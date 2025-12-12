// Copyright David Schröder 2025.
//
// TL-UL <-> TL-UL Randomizer.
// Reorders TL-UL responses (brings them out of order) to test conformance with TL-UL standards.

module tlul_order_randomizer #(
	parameter int WAIT_CYCLES = 0, /* Number of cycles to wait for outgoing requests after first response. Must be <2^16. */
	parameter int MAX_SIZE = 4, /* Maximum number of stored entries. Must be a power of 2, >= 2 and <= 2^16. */
	parameter int LFSR_SEED = 16'hCAFE /* LFSR starting seed. May not be zero. */
) (
	input logic clk_i,
	input logic rst_ni,

	input tlul_pkg::tl_h2d_t host_i,
	output tlul_pkg::tl_d2h_t host_o,
	output tlul_pkg::tl_h2d_t device_o,
	input tlul_pkg::tl_d2h_t device_i
);

	import tlul_pkg::*;
	import top_pkg::*;

/*
	How it works

	The TL-UL order randomizer works on a queue (rspq) of TL-UL response objects.
	
	When the first request is made on the host bus, the randomizer starts counting the number
	of outgoing requests, starting at 1. It automatically invalidates the request channel once
	the number of outgoing requests + the number of current queue items matches MAX_SIZE.
	Once the first response arrives, the randomizer continues to count outgoing requests for
	WAIT_CYCLES cycles, then waits until all requests have been met with a response. Until then,
	no more requests are accepted.

	Once there are no more outstanding responses, the reordering process begins.
	The reordering of response objects is based on an LRU selector combined with a 16-bit LFSR.
	Every cycle that the randomizer is in the reordering state, the response pointed to by the
	LRU's selected output is dispatched back to the host, updating the LRU when the response is
	ACK'd by the host. The LRU's selected output is however generated slightly abnormally, as
	it should only select queue entries which actually have data. For this to occur, the LRU
	(which is based on a promotion queue) is combined with a priority encoder, selecting the
	least recent promotion queue item whose data is valid.

	When the randomizer is not in the dispatching state, the LRU is continuously updated by
	the LFSR. Every cycle, the bottom log2(MAX_SIZE) bits of the LFSR are used as an index
	into the LRU to "use" the corresponding entry. The LFSR is updated every cycle, even
	during dispatch. Its starting seed can be specified by varying LFSR_SEED.

	Overall, this results in the following states:
	- COLLECT state, where outgoing requests are counted until the first response arrives
	- RECEIVE state, where all outstanding responses are awaited
	- WAIT state, waiting for WAIT_CYCLES cycles
	- DISPATCH state, where the responses are reordered and dispatched
*/

	localparam int queue_addr_len = $clog2(MAX_SIZE);

	typedef enum logic [1:0] {
		Collect = 2'h0,
		Wait = 2'h1,
		Receive = 2'h2,
		Dispatch = 2'h3
	} rnd_state_e;


	//////////
	// LFSR //
	//////////

	logic [15:0] lfsr_o;

	lfsr #(
		.SEED(LFSR_SEED)
	) rnd_lfsr (
		.clk_i,
		.rst_ni,
		.lfsr_en_i('1),
		.lfsr_o
	);

	/////////
	// LRU //
	/////////

	logic [queue_addr_len-1:0] lru_use_sel;
	logic lru_use_valid;

	// Promotion to beginning of storage
	// LRU item at end
	// Each item holds an index from 0 to MAX_SIZE (exclusive)
	logic [queue_addr_len-1:0] lru_storage [MAX_SIZE];
	logic [MAX_SIZE-1:0] lru_cam_match;

	// CAM
	always_comb begin
		for (int i = 0; i < MAX_SIZE; i++) begin
			lru_cam_match[i] = lru_storage[i] == lru_use_sel;
		end
	end

	// Update storage
	genvar i;
	generate
		for (i = 1; i < MAX_SIZE; i++) begin
			always_ff @(posedge clk_i or negedge rst_ni) begin
				if(~rst_ni) begin
					lru_storage[i] <= MAX_SIZE-i-1;
				end else begin
					if (lru_use_valid) begin
						if (|(lru_cam_match[MAX_SIZE-1:i]) == '1) begin
							lru_storage[i] <= lru_storage[i-1];
						end
					end // lru_use_valid
				end // if ~rst_ni
			end // always_ff
		end // generate for
	endgenerate

	// Promotion queue head (promoted item)
	always_ff @(posedge clk_i or negedge rst_ni) begin
		if (~rst_ni) begin
			lru_storage[0] <= MAX_SIZE-1;
		end else begin
			if (lru_use_valid) begin
				lru_storage[0] <= lru_use_sel;
			end
		end
	end

	// Connect LRU with LFSR
	always_comb begin
		lru_use_sel <= lfsr_o[queue_addr_len-1:0];
	end

	///////////
	// QUEUE //
	///////////

	tlul_pkg::tl_d2h_t rsp_queue [MAX_SIZE];
	logic [MAX_SIZE-1:0] 	   rspq_valid;
	// #used/#outstanding reqs can be equal to max_size -> need extra bit
	logic [queue_addr_len:0]   rspq_used; // Doubles as write pointer
	logic [queue_addr_len:0]   rspq_outstanding;
	logic 					   req_valid;
	logic					   rsp_valid;
	logic [15:0]			   wait_cycles_remaining;

	rnd_state_e 			   state_d, state_q;

	/* Select next output for dispatch with prio encoder */
	logic [MAX_SIZE-1:0]	   rspq_valid_lru_ordering; // rspq_valid_lru_ordering[i] = 1 -> rspq[lru[i]] is valid
	logic [MAX_SIZE-1:0]	   rspq_selected; // rspq_selected[i] = 1 -> lru[i] is the index of the next dispatchable rspq entry

	always_comb begin
		for (int i = 0; i < MAX_SIZE; i++) begin
			rspq_valid_lru_ordering[i] = rspq_valid[lru_storage[i]];
		end
	end

	priority_encoder #(
		.NUM_BITS(MAX_SIZE)
	) dispatch_selector_inst (
		.clk_i,
		.rst_ni,

		.srcvec_i(rspq_valid_lru_ordering),
		.outvec_o(rspq_selected)
	);

	always_comb begin
		device_o = host_i;
		device_o.a_valid = (rspq_used + rspq_outstanding < MAX_SIZE) && host_i.a_valid && (state_q == Collect || state_q == Wait);
		device_o.d_ready = state_q == Dispatch ? '0: '1;

		req_valid = (rspq_used + rspq_outstanding < MAX_SIZE) && host_i.a_valid && device_i.a_ready && (state_q == Collect || state_q == Wait);
		rsp_valid = device_i.d_valid && device_o.d_ready;

		host_o = '{d_opcode: tlul_pkg::AccessAck, default: '0};
		for (int i = 0; i < MAX_SIZE; i++) begin
			if (rspq_selected[i] && state_q == Dispatch) begin
				host_o = rsp_queue[lru_storage[i]];
				host_o.d_valid = '1;
			end
		end
		host_o.a_ready = (rspq_used + rspq_outstanding < MAX_SIZE) && device_i.a_ready && (state_q == Collect || state_q == Wait);

		lru_use_valid = '1;

		state_d = state_q;

		case (state_q)
			Collect: begin
				if (rsp_valid) begin
					if (WAIT_CYCLES == 0) state_d = Receive;
					else state_d = Wait;
				end
			end
			Wait: begin
				if (wait_cycles_remaining == 16'h0) state_d = Receive;
			end
			Receive: begin
				if (rspq_outstanding == 32'h1 && rsp_valid || rspq_outstanding == 32'h0) state_d = Dispatch;
			end
			Dispatch: begin
				if (rspq_used == 32'h1 && host_o.d_valid && host_i.d_ready || rspq_used == 32'h0) state_d = Collect;
			end
			default: state_d = Collect;
		endcase

		if (state_q == Dispatch) begin
			lru_use_valid = '0;
		end
	end

	always_ff @(posedge clk_i or negedge rst_ni) begin
		if(~rst_ni) begin
			rspq_valid <= '0;
			rspq_used <= 0;
			rspq_outstanding <= 0;
			state_q <= Collect;
			wait_cycles_remaining <= WAIT_CYCLES;
			for (int i = 0; i < MAX_SIZE; i++) begin
				rsp_queue[i] <= '{d_opcode: tlul_pkg::AccessAck, default: '0};
			end
		end else begin
			case (state_q)
				Collect: begin
					if (req_valid) begin
						// if req_valid && rsp_valid, outstanding requests stay the same
						if (!rsp_valid) rspq_outstanding <= rspq_outstanding + 1;
					end else if (rsp_valid) begin
						rspq_outstanding <= rspq_outstanding - 1;
					end
					if (rsp_valid) begin
						rspq_used <= rspq_used + 1;
						rsp_queue[rspq_used] <= device_i;
						rspq_valid[rspq_used] <= '1;
					end
				end
				Wait: begin
					if (wait_cycles_remaining == 0) wait_cycles_remaining <= WAIT_CYCLES;
					else wait_cycles_remaining <= wait_cycles_remaining - 1;
					if (req_valid) begin
						if (!rsp_valid) rspq_outstanding <= rspq_outstanding + 1;
					end else if (rsp_valid) begin
						rspq_outstanding <= rspq_outstanding - 1;
					end
					if (rsp_valid) begin
						rspq_used <= rspq_used + 1;
						rsp_queue[rspq_used] <= device_i;
						rspq_valid[rspq_used] <= '1;
					end
				end
				Receive: begin
					if (rsp_valid) begin
						rspq_used <= rspq_used + 1;
						rspq_outstanding <= rspq_outstanding - 1;
						rsp_queue[rspq_used] <= device_i;
						rspq_valid[rspq_used] <= '1;
					end
				end
				Dispatch: begin
					if (host_o.d_valid && host_i.d_ready) begin
						for (int i = 0; i < MAX_SIZE; i++) begin
							if (rspq_selected[i]) begin
								rspq_valid[lru_storage[i]] <= '0;
							end
						end
						rspq_used <= rspq_used - 1;
					end
				end
				default:;
			endcase
			state_q <= state_d;
		end
	end

endmodule
