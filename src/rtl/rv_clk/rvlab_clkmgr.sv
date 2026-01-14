// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2025 RVLab Contributors

// Clock manager for RISC-V Lab.
// Supports dynamic clock divider adjusting, enabling clock speed changes
// without having to regenerate a new bitstream.

/* Variable clocking Configuration: */
/*
                      clk_100mhz
                          │
┌─────rvlab_clkmgr.sv─────────┐ <------ this module
│                         │   │
│   ┌──────────────────┐  │   │
│   │       MMCM       ├──┤   │
│   │       drp        │  │   │
│   └────────┬─────────┘  │   │
│   ┌────────┴─────────┐  │   │
│   │  TL-UL <-> DRP   ├──┤   │
│   └───┬──────────┬───┘  │   │
│       │  TL-UL   │      │   │
│   ┌───┴──────────┴───┐  │   │
│   │   CLK Reconfig   ├──┘   │
│   │ ┌──────────────┐ │      │
│   │ │  ADDR REMAP  │ │      │
│   │ └──────────────┘ │      │
│   │ ┌──────────────┐ │      │
│   │ │  SAFETY NET  │ │      │
│   │ └──────────────┘ ├──┐   │
│   └───┬──────────┬───┘  │   │
│       │  TL-UL   │      │   │
└─────────────────────────────┘
    ┌───┴──────────┴───┐  │
    │       SOC        ├──┤
    │                  │  │
                          │
                       sys_clk (technically an MMCM output)
*/

module rvlab_clkmgr #(
  parameter int SYS_CLK_DIV_DEFAULT = 18,
  parameter int USE_SAFETY_NET = 1
) (
  input  logic clk_100mhz_i,
  input  logic jtag_srst_ni,

  output logic sys_clk_o,
  output logic clk_100mhz_buffered_o,
  output logic clk_200mhz_o,
  output logic locked_o,
  output logic sys_rst_no,

  input  tlul_pkg::tl_h2d_t tl_reconfig_i,
  output tlul_pkg::tl_d2h_t tl_reconfig_o,

  output logic [1:0] reconfig_status_o
);

  logic clk_200mhz;
  logic clk_100mhz_buffered;
  logic clk_fb;
  logic ddrclk_fb;
  logic clkout0;

  logic syslocked;
  logic ddrlocked;
  assign locked_o = syslocked & ddrlocked;

  BUFG clk_100mhz_bufg_i (
    .I(clk_100mhz_i),
    .O(clk_100mhz_buffered)
  );

  assign clk_100mhz_buffered_o = clk_100mhz_buffered;

  /* Dynamic Reconfiguration Signals */
  // Inputs
  logic        drp_en, drp_we;
  logic [ 6:0] drp_adr;
  logic [15:0] drp_di;
  // Outputs
  logic        drp_rdy;
  logic [15:0] drp_do;

  logic mmcm_reset;

  MMCME2_ADV #(
     .BANDWIDTH("OPTIMIZED"),        // Jitter programming (OPTIMIZED, HIGH, LOW)
     .CLKFBOUT_MULT_F(12.0),         // fVCO = 12 * 100 MHz = 1200 MHz
     .CLKFBOUT_PHASE(0.0),           // Phase offset in degrees of CLKFB (-360.000-360.000).
     // CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
     .CLKIN1_PERIOD(10.0),           // 10ns = 100MHz
     .CLKIN2_PERIOD(0.0),
     // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
     .CLKOUT0_DIVIDE_F(SYS_CLK_DIV_DEFAULT), // freq(CLKOUT0) = fVCO / 18 [Dynamically adjustable]
     .CLKOUT1_DIVIDE(20),            // not used
     .CLKOUT2_DIVIDE(20),            // not used
     .CLKOUT3_DIVIDE(20),            // not used
     .CLKOUT4_DIVIDE(20),            // not used
     .CLKOUT5_DIVIDE(20),            // not used
     .CLKOUT6_DIVIDE(20),            // not used
     // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
     .CLKOUT0_DUTY_CYCLE(0.5),
     .CLKOUT1_DUTY_CYCLE(0.5),
     .CLKOUT2_DUTY_CYCLE(0.5),
     .CLKOUT3_DUTY_CYCLE(0.5),
     .CLKOUT4_DUTY_CYCLE(0.5),
     .CLKOUT5_DUTY_CYCLE(0.5),
     .CLKOUT6_DUTY_CYCLE(0.5),
     // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
     .CLKOUT0_PHASE(0.0),
     .CLKOUT1_PHASE(90.0),
     .CLKOUT2_PHASE(0.0),
     .CLKOUT3_PHASE(0.0),
     .CLKOUT4_PHASE(0.0),
     .CLKOUT5_PHASE(0.0),
     .CLKOUT6_PHASE(0.0),
     .CLKOUT4_CASCADE("FALSE"),      // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
     .COMPENSATION("ZHOLD"),         // ZHOLD, BUF_IN, EXTERNAL, INTERNAL
     .DIVCLK_DIVIDE(1),              // Master division value (1-106)
     // REF_JITTER: Reference input jitter in UI (0.000-0.999).
     .REF_JITTER1(0.0),
     .REF_JITTER2(0.0),
     .STARTUP_WAIT("FALSE"),         // Delays DONE until MMCM is locked (FALSE, TRUE)
     // Spread Spectrum: Spread Spectrum Attributes
     .SS_EN("FALSE"),                // Enables spread spectrum (FALSE, TRUE)
     .SS_MODE("CENTER_HIGH"),        // CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
     .SS_MOD_PERIOD(10000),          // Spread spectrum modulation period (ns) (VALUES)
     // USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
     .CLKFBOUT_USE_FINE_PS("FALSE"),
     .CLKOUT0_USE_FINE_PS("FALSE"),
     .CLKOUT1_USE_FINE_PS("FALSE"),
     .CLKOUT2_USE_FINE_PS("FALSE"),
     .CLKOUT3_USE_FINE_PS("FALSE"),
     .CLKOUT4_USE_FINE_PS("FALSE"),
     .CLKOUT5_USE_FINE_PS("FALSE"),
     .CLKOUT6_USE_FINE_PS("FALSE")
  ) sys_mmcm_i (
     // Clock Outputs: 1-bit (each) output: User configurable clock outputs
     .CLKOUT0 (clkout0),          // 1-bit output: CLKOUT0
     .CLKOUT0B(),                 // 1-bit output: Inverted CLKOUT0
     .CLKOUT1 (),                 // 1-bit output: CLKOUT1
     .CLKOUT1B(),                 // 1-bit output: Inverted CLKOUT1
     .CLKOUT2 (),                 // 1-bit output: CLKOUT2
     .CLKOUT2B(),                 // 1-bit output: Inverted CLKOUT2
     .CLKOUT3 (),                 // 1-bit output: CLKOUT3
     .CLKOUT3B(),                 // 1-bit output: Inverted CLKOUT3
     .CLKOUT4 (),                 // 1-bit output: CLKOUT4
     .CLKOUT5 (),                 // 1-bit output: CLKOUT5
     .CLKOUT6 (),                 // 1-bit output: CLKOUT6
     // DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
     .DO  (drp_do),               // 16-bit output: DRP data
     .DRDY(drp_rdy),              // 1-bit output: DRP ready
     // Dynamic Phase Shift Ports: 1-bit (each) output: Ports used for dynamic phase shifting of the outputs
     .PSDONE(),                   // 1-bit output: Phase shift done
     // Feedback Clocks: 1-bit (each) output: Clock feedback ports
     .CLKFBOUT (clk_fb),          // 1-bit output: Feedback clock
     .CLKFBOUTB(),                // 1-bit output: Inverted CLKFBOUT
     // Status Ports: 1-bit (each) output: MMCM status ports
     .CLKFBSTOPPED(),             // 1-bit output: Feedback clock stopped
     .CLKINSTOPPED(),             // 1-bit output: Input clock stopped
     .LOCKED(syslocked),           // 1-bit output: LOCK
     // Clock Inputs: 1-bit (each) input: Clock inputs
     .CLKIN1(clk_100mhz_buffered),// 1-bit input: Primary clock
     .CLKIN2(),                   // 1-bit input: Secondary clock
     // Control Ports: 1-bit (each) input: MMCM control ports
     .CLKINSEL('1),               // 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
     .PWRDWN('0),                 // 1-bit input: Power-down
     .RST(mmcm_reset),            // 1-bit input: Reset
     // DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
     .DADDR(drp_adr),             // 7-bit input: DRP address
     .DCLK (clk_100mhz_buffered), // 1-bit input: DRP clock
     .DEN  (drp_en),              // 1-bit input: DRP enable
     .DI   (drp_di),              // 16-bit input: DRP data
     .DWE  (drp_we),              // 1-bit input: DRP write enable
     // Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
     .PSCLK(clk_100mhz_buffered), // 1-bit input: Phase shift clock
     .PSEN('0),                   // 1-bit input: Phase shift enable
     .PSINCDEC('0),               // 1-bit input: Phase shift increment/decrement
     // Feedback Clocks: 1-bit (each) input: Clock feedback ports
     .CLKFBIN(clk_fb)             // 1-bit input: Feedback clock
  );

  MMCME2_BASE #(
   .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
   .CLKFBOUT_MULT_F(6.0),     // fVCO = 6 * 100 MHz = 600 MHz
   .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
   .CLKIN1_PERIOD(10.0),      // 10ns = 100MHz
   // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
   .CLKOUT0_DIVIDE_F(3.0),    // DDRCLK = 200MHz
   // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
   .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
   .DIVCLK_DIVIDE(1),         // Master division value (1-106)
   .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
   .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
) ddr_mmcm_i (
   // Clock Outputs: 1-bit (each) output: User configurable clock outputs
   .CLKOUT0(clk_200mhz),  // 1-bit output: CLKOUT0
   .CLKOUT0B(),           // 1-bit output: Inverted CLKOUT0
   .CLKOUT1(),            // 1-bit output: CLKOUT1
   .CLKOUT1B(),           // 1-bit output: Inverted CLKOUT1
   .CLKOUT2(),            // 1-bit output: CLKOUT2
   .CLKOUT2B(),           // 1-bit output: Inverted CLKOUT2
   .CLKOUT3(),            // 1-bit output: CLKOUT3
   .CLKOUT3B(),           // 1-bit output: Inverted CLKOUT3
   .CLKOUT4(),            // 1-bit output: CLKOUT4
   .CLKOUT5(),            // 1-bit output: CLKOUT5
   .CLKOUT6(),            // 1-bit output: CLKOUT6
   // Feedback Clocks: 1-bit (each) output: Clock feedback ports
   .CLKFBOUT(ddrclk_fb),  // 1-bit output: Feedback clock
   .CLKFBOUTB(),          // 1-bit output: Inverted CLKFBOUT
   // Status Ports: 1-bit (each) output: MMCM status ports
   .LOCKED(ddrlocked),    // 1-bit output: LOCK
   // Clock Inputs: 1-bit (each) input: Clock input
   .CLKIN1(clk_100mhz_buffered),       // 1-bit input: Clock
   // Control Ports: 1-bit (each) input: MMCM control ports
   .PWRDWN('0),           // 1-bit input: Power-down
   .RST('0),              // 1-bit input: Reset
   // Feedback Clocks: 1-bit (each) input: Clock feedback ports
   .CLKFBIN(ddrclk_fb)    // 1-bit input: Feedback clock
);

  tlul_pkg::tl_d2h_t tl_adapter_d2h;
  tlul_pkg::tl_h2d_t tl_adapter_h2d;

  rvlab_tl_clkdrp_adapter clk_drp_adapter_i (
    .clk_i        (clk_100mhz_buffered),
    .rst_ni       (jtag_srst_ni),
    .tl_reconfig_i(tl_adapter_h2d),
    .tl_reconfig_o(tl_adapter_d2h),
    .drp_rdy_i    (drp_rdy),
    .drp_do_i     (drp_do),
    .drp_en_o     (drp_en),
    .drp_we_o     (drp_we),
    .drp_adr_o    (drp_adr),
    .drp_di_o     (drp_di),
    .rst_mmcm_o   (mmcm_reset)
  );

  rvlab_clk_reconfig #(
    .FALLBACK_CLKDIV(SYS_CLK_DIV_DEFAULT),
    .USE_SAFETY_NET(USE_SAFETY_NET)
  ) clk_reconfig_i (
    .board_clk_i  (clk_100mhz_buffered),
    .board_rst_ni (jtag_srst_ni),
    .sys_clk_i    (sys_clk_o),
    .sys_rst_ni   (jtag_srst_ni), // for resetting cdc fifo
    .tl_host_i    (tl_reconfig_i),
    .tl_host_o    (tl_reconfig_o),
    .tl_device_i  (tl_adapter_d2h),
    .tl_device_o  (tl_adapter_h2d),
    .mmcm_locked_i(locked_o),
    .sys_rst_no,
    .status_o     (reconfig_status_o)
  );

  BUFGCE clkbuf_i (
    .O (sys_clk_o), // 1-bit output: Clock output
    .CE(locked_o),  // according to doc, this seems to be a glitch-free (latch based) clock gate
    .I (clkout0)    // 1-bit input: Primary clock
  );

  BUFG clkbuf_200mhz_i (
    .O (clk_200mhz_o), // 1-bit output: Clock output
    .I (clk_200mhz)    // 1-bit input: Primary clock
  );


endmodule
