// Copyright David Schröder 2025.
//
// TL-UL <-> TL-UL Re-Order buffer.
// Guarantees that the host output response order matches the host request order.

/*
	How it works
	
	At the heart of this adapter is a Re-Order Buffer (ROB), which is a table
	(a ring buffer) containing source, data, and state fields.
	When a new request arrives (via host_i.a_valid = 1), a new source value for the
	TL-UL request is generated based on pointers to the ROB (tail and head).
	The source value is written to a free ROB entry, pointed to by the head
	pointer, and the state of the entry is set to pending.
	
	Since TL-UL can accept requests in any arbitrary order, the conversion
	from the input bus to the output in the host-to-device direction
	can bypass the ROB almost entirely and update it silently. The only
	exception to this rule is when the ROB is full, in which case the request
	will not be granted until the device bus responds to the oldest outstanding
	request and at least one entry in the ROB can be cleared.
	
	When any response arrives, the entries of the ROB are checked in parallel
	for a match of the source fields. If the source field matches that of the
	ROB entry pointed to by the tail pointer, i.e. the response is to the
	oldest outstanding request, the response can bypass being stored in the
	ROB and immediately combinationally drive the host D channel.
	The oldest ROB entry is immediately invalidated and the tail pointer is
	incremented.
	If the source field matches an entry that isn't the oldest outstanding
	request, the entry is validated and the data field is updated to the
	read data of the device D channel.
	
	So long as the entry pointed to by the tail pointer is in a valid state,
	the tail entry's data is immediately provided to the host_o.d_data output,
	driving host_o.d_valid to signal a valid response. This means that responses
	can be flushed from the ROB at a maximum rate of one entry per clock.
	
	An optimization can be made regarding the source field of the ROB entries:
	since there can be exactly one outstanding request for each ROB entry,
	the index of each entry can be used as the source field. This significantly
	reduces the complexity of the lookup logic for responses, and reduces the
	size of the table.
	
	Note that the ROB is full iff the tail and head pointers overlap and the
	state of the entry pointed to by them is valid. This is because the head
	pointer always points to the next entry to be populated, and the tail
	pointer always points to the next entry to be read.
*/

module tlul_rob #(
	parameter int DEPTH = 2
) (
	input  logic        clk_i,
	input  logic        rst_ni,

	input tlul_pkg::tl_h2d_t host_i,
	output tlul_pkg::tl_d2h_t host_o,
	input tlul_pkg::tl_d2h_t device_i,
	output tlul_pkg::tl_h2d_t device_o
);

	import tlul_pkg::*;
	import top_pkg::*;

	typedef enum logic [1:0] {
		Invalid = 2'h0,
		Pending = 2'h1,
		Valid = 2'h2
	} rob_state_e;
	
	typedef struct packed {
		logic       [31:0] 	data;
		logic       [31:0] 	address;
		tl_d_op_e	device_op;
		logic		[TL_AIW-1:0] host_src;
		logic 		[TL_SZW-1:0] device_size;
		logic		device_err;
		rob_state_e	state;
	} rob_entry_t;
	
	rob_entry_t entries [DEPTH];
	
	localparam int ROB_ADR_W = $clog2(DEPTH) - 1;

	logic [ROB_ADR_W:0] rob_head;
	logic [ROB_ADR_W:0] rob_tail;
	
	logic rob_full;
	assign rob_full = rob_head == rob_tail && entries[rob_head].state != Invalid;
	
	/* Update ROB */
	always_ff @(posedge clk_i, negedge rst_ni) begin
		if (~rst_ni) begin
			int i;
			for (i = 0; i < DEPTH; i = i + 1) begin
			  	entries[i] <= '{
			  		data: '0,
			  		address: '0,
			  		host_src: '0,
			  		device_size: '0,
			  		device_op: AccessAck,
			  		device_err: '0,
			  		state: Invalid
			  	};
			end
			rob_head <= '0;
			rob_tail <= '0;
		end else begin
			// check for successful beat exchange
			if (host_i.a_valid && device_i.a_ready) begin
				if (~rob_full) begin
					// populate next entry in ROB (Update to pending)
					entries[rob_head].state 	<= Pending;
					entries[rob_head].address 	<= host_i.a_address;
					entries[rob_head].host_src 	<= host_i.a_source;
					// shift head pointer
					rob_head <= rob_head + 1;
				end
			end

			// check for response
			if (device_i.d_valid) begin
				// device_i.d_source is an index to the correct entry
				if (device_i.d_source == rob_tail) begin
					// Data bypasses ROB straight to TL-UL -> invalidate entry
					entries[rob_tail].state <= Invalid;
					rob_tail <= rob_tail + 1;
				end else begin
					// Otherwise write data to ROB and validate
					// (This is the part that enables out-of-order delivery :P)
					entries[device_i.d_source].state 	  <= Valid;
					entries[device_i.d_source].device_op   <= device_i.d_opcode;
					entries[device_i.d_source].data 		  <= device_i.d_data;
					entries[device_i.d_source].device_err  <= device_i.d_error;
					entries[device_i.d_source].device_size <= device_i.d_size;
				end
			end
			
			// update tail
			if (entries[rob_tail].state == Valid) begin
				entries[rob_tail].state <= Invalid;
				rob_tail <= rob_tail + 1;
			end
		end
	end

	/* Generate TL-UL output */
	assign device_o = '{
		a_valid: host_i.a_valid,
		a_opcode: host_i.a_opcode,
		a_param: host_i.a_param,
		a_size: host_i.a_size,
		a_source: rob_head,
		a_address: host_i.a_address,
		a_data: host_i.a_data,
		a_mask: host_i.a_mask,
		a_user: '{default: '0},

		d_ready: host_i.d_ready
	};

	logic bypass_rsp; // Whether to bypass the device D channel straight to the host
	assign bypass_rsp = device_i.d_valid && device_i.d_source == rob_tail; // bypass when responses come in-order

	assign host_o = '{
		// Immediately set valid to 1 when device response is oldest entry
		d_valid: 	bypass_rsp ? '1 : entries[rob_tail].state == Valid,
		d_opcode: 	bypass_rsp ? device_i.d_opcode : entries[rob_tail].device_op,
		// bypass device data when dev resp is oldest entry
		d_data: 	bypass_rsp ? device_i.d_data : entries[rob_tail].data,
		d_source: 	entries[rob_tail].host_src,
		d_size: 	bypass_rsp ? device_i.d_size : entries[rob_tail].device_size,
		d_error: 	bypass_rsp ? device_i.d_error : entries[rob_tail].device_err,

		a_ready: 	~rob_full && device_i.a_ready, // Grant any request when the ROB still has space and when TL-UL accepts it
		default: '0
	};

endmodule
