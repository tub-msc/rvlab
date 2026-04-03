// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

// TL-UL Short Circuit Utility.

module tlul_short_circuit (
	input  tlul_pkg::tl_h2d_t tl_i,
	output tlul_pkg::tl_d2h_t tl_o
);

	import tlul_pkg::*;

	assign tl_o = '{
		d_valid : tl_i.a_valid,
		d_opcode: tl_i.a_opcode == Get ? AccessAckData : AccessAck,
		d_size  : tl_i.a_size,
		d_source: tl_i.a_source,
		d_data  : 32'h00000000,
		a_ready : tl_i.d_ready,
		default : '0
	};

endmodule
