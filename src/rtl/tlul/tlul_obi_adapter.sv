// Copyright David Schröder 2025.
//
// OBI <-> TL-UL Adapter where OBI is the master interface and TL-UL is the slave interface.
// Implements TL-UL Response Reordering using an ROB-like structure.

module tlul_obi_adapter #(
	parameter int ROB_DEPTH = 2 /* must be a power of 2 and at least 2 */
) (
	input  logic        clk_i,
	input  logic        rst_ni,

	input  logic        obi_req_i,
	output logic        obi_gnt_o,
	output logic        obi_rvalid_o,
	input  logic        obi_we_i,
	input  logic  [3:0] obi_be_i,
	input  logic [31:0] obi_addr_i,
	input  logic [31:0] obi_wdata_i,
	output logic [31:0] obi_rdata_o,
	
	output tlul_pkg::tl_h2d_t tl_o,
	input  tlul_pkg::tl_d2h_t tl_i
);

	import tlul_pkg::*;
	import top_pkg::*;

	tl_h2d_t host_h2d;
	tl_d2h_t host_d2h;

	tlul_rob #(
		.DEPTH(ROB_DEPTH)
	) ROB_inst (
		.clk_i,
		.rst_ni,

		.host_i(host_h2d),
		.host_o(host_d2h),
		.device_i(tl_i),
		.device_o(tl_o)
	);

	//assign tl_o = host_h2d;
	//assign host_d2h = tl_i;

	assign host_h2d = '{
		a_valid: obi_req_i,
		a_opcode: obi_we_i ? (obi_be_i == 4'hF ? tlul_pkg::PutFullData : tlul_pkg::PutPartialData): tlul_pkg::Get,
		a_param: 3'h0,
		a_size: 2'h2, // 32 Bits
		a_mask: obi_be_i,
		a_source: 0,
		a_address: {obi_addr_i[31:2], 2'h0}, // Set bottom two bits to zero for aligned access when accessing bytes/halfwords
		a_data: obi_wdata_i,
		a_user: '{default: '0},
		
		d_ready: 1'b1
	};

	assign obi_gnt_o = host_d2h.a_ready;
	assign obi_rvalid_o = host_d2h.d_valid;
	assign obi_rdata_o = host_d2h.d_data;
	
endmodule
