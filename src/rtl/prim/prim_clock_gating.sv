// Copyright lowRISC contributors.
// SPDX-FileCopyrightText: 2024-2026 RVLab Contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by RVLab Contributors.
//
// Common Library: Clock Gating cell

module prim_clock_gating (
  input  logic clk_i,
  input  logic en_i,
  input  logic test_en_i,
  output logic clk_o
);

  logic enable_clock;
  assign enable_clock = en_i | test_en_i;
    
  BUFGCE clkbuf_i (
    .O (clk_o),
    .CE(enable_clock),  // according to doc, this seems to be a glitch-free (latch based) clock gate
    .I (clk_i)
  );

endmodule
