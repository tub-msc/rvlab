// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2025-2026 RVLab Contributors

module cv32e40p_clock_gate (
    input  logic clk_i,
    input  logic en_i,
    input  logic scan_cg_en_i,
    output logic clk_o
);

  	prim_clock_gating cg_i (
  		.clk_i,
  		.en_i,
  		.test_en_i(scan_cg_en_i),
  		.clk_o
  	);

endmodule  // cv32e40p_clock_gate
