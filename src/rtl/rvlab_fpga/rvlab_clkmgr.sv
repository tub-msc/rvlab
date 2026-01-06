// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024-2026 RVLab Contributors

module rvlab_clkmgr (
  input  logic clk_100mhz_i,
  output logic sys_clk_o,
  output logic clk_200mhz_o,
  output logic locked_o,
  output logic clk_100mhz_buffered_o
);

  logic clk_200mhz;
  logic clk_100mhz_buffered;
  logic clk_fb;
  logic clkout0;

  BUFG clk_100mhz_bufg_i (
    .I(clk_100mhz_i),
    .O(clk_100mhz_buffered)
  );

  assign clk_100mhz_buffered_o = clk_100mhz_buffered;

  MMCME2_BASE #(
    .BANDWIDTH         ("OPTIMIZED"),  // Jitter programming (OPTIMIZED, HIGH, LOW)
    .CLKFBOUT_MULT_F   (12.0),         // fVCO = 12 * 100 MHz = 1200 MHz 
    .CLKFBOUT_PHASE    (0.0),          // Phase offset in degrees of CLKFB (-360.000-360.000).
    .CLKIN1_PERIOD     (10.0),         // 100 MHz input clock = 10 ns clock period
    .CLKOUT0_DIVIDE_F  (24.0),         // freq(CLKOUT0) = fVCO / 24 = 50 MHz
    .CLKOUT1_DIVIDE    (6),            // freq(clk_200mhz_o) = fVCO / 6 / 200 MHz
    .CLKOUT2_DIVIDE    (20),           // not used
    .CLKOUT3_DIVIDE    (20),           // not used
    .CLKOUT4_DIVIDE    (20),           // not used
    .CLKOUT5_DIVIDE    (20),           // not used
    .CLKOUT6_DIVIDE    (20),           // not used
    // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT6_DUTY_CYCLE(0.5),
    // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
    .CLKOUT0_PHASE     (0.0),
    .CLKOUT1_PHASE     (90.0),
    .CLKOUT2_PHASE     (0.0),
    .CLKOUT3_PHASE     (0.0),
    .CLKOUT4_PHASE     (0.0),
    .CLKOUT5_PHASE     (0.0),
    .CLKOUT6_PHASE     (0.0),
    .CLKOUT4_CASCADE   ("FALSE"),      // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
    .DIVCLK_DIVIDE     (1),            // Master division value (1-106)
    .REF_JITTER1       (0.0),          // Reference input jitter in UI (0.000-0.999).
    .STARTUP_WAIT      ("FALSE")       // Delays DONE until MMCM is locked (FALSE, TRUE)
  ) mmcm_i (
    // Clock Outputs: 1-bit (each) output: User configurable clock outputs
    .CLKOUT0  (clkout0),              // 1-bit output: CLKOUT0
    .CLKOUT0B (),                     // 1-bit output: Inverted CLKOUT0
    .CLKOUT1  (clk_200mhz),         // 1-bit output: CLKOUT1
    .CLKOUT1B (),                     // 1-bit output: Inverted CLKOUT1
    .CLKOUT2  (),                     // 1-bit output: CLKOUT2
    .CLKOUT2B (),                     // 1-bit output: Inverted CLKOUT2
    .CLKOUT3  (),                     // 1-bit output: CLKOUT3
    .CLKOUT3B (),                     // 1-bit output: Inverted CLKOUT3
    .CLKOUT4  (),                     // 1-bit output: CLKOUT4
    .CLKOUT5  (),                     // 1-bit output: CLKOUT5
    .CLKOUT6  (),                     // 1-bit output: CLKOUT6
    // Feedback Clocks: 1-bit (each) output: Clock feedback ports
    .CLKFBOUT (clk_fb),               // 1-bit output: Feedback clock
    .CLKFBOUTB(),                     // 1-bit output: Inverted CLKFBOUT
    // Status Ports: 1-bit (each) output: MMCM status ports
    .LOCKED   (locked_o),             // 1-bit output: LOCK
    // Clock Inputs: 1-bit (each) input: Clock input
    .CLKIN1   (clk_100mhz_buffered),  // 1-bit input: Clock
    // Control Ports: 1-bit (each) input: MMCM control ports
    .PWRDWN   ('0),                   // 1-bit input: Power-down
    .RST      ('0),                   // 1-bit input: Reset
    // Feedback Clocks: 1-bit (each) input: Clock feedback ports
    .CLKFBIN  (clk_fb)                // 1-bit input: Feedback clock
  );

  prim_clock_gating sys_clk_cg_i (
    .clk_i    (clkout0),
    .en_i     (locked_o),
    .test_en_i('0),
    .clk_o    (sys_clk_o)
  );

  BUFG clkbuf_200mhz_i (
    .O (clk_200mhz_o),     // 1-bit output: Clock output
    .I (clk_200mhz)    // 1-bit input: Primary clock
  );


endmodule
