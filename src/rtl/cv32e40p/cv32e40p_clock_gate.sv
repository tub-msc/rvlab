// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2025 RVLab Contributors

module cv32e40p_clock_gate (
    input  logic clk_i,
    input  logic en_i,
    input  logic scan_cg_en_i,
    output logic clk_o
);

  	logic enable_clock;
  	assign enable_clock = en_i | scan_cg_en_i;
  	
  	BUFGCE clkbuf_i (
		.O (clk_o),
		.CE(enable_clock),  // according to doc, this seems to be a glitch-free (latch based) clock gate
		.I (clk_i)
	);

endmodule  // cv32e40p_clock_gate
