// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

module rvlab_ddr3_tlul_tb;

  import tlul_pkg::*;
  import rvlab_ddr_pkg::*;

  ////////////
  // Clocks //
  ////////////

  // sysclk = 50mhz
  logic sysclk, clk100;
  logic rstn;

  /* System Clock */
  always begin
    sysclk = '1;
    #10000;
    sysclk = '0;
    #10000;
  end

  /* 100MHz (DDR3 Controller) Clock */
  always begin
    clk100 = '1;
    #5000;
    clk100 = '0;
    #5000;
  end

  ///////////////////////
  // DDR instantiation //
  ///////////////////////

  tl_h2d_t tl_host_h2d, tl_ctrl_h2d;
  tl_d2h_t tl_host_d2h, tl_ctrl_d2h;

  wire [15:0] ddr3_dq;
  wire [ 1:0] ddr3_dqs_n;
  wire [ 1:0] ddr3_dqs_p;
  wire [14:0] ddr3_addr;
  wire [ 2:0] ddr3_ba;
  wire        ddr3_ras_n;
  wire        ddr3_cas_n;
  wire        ddr3_we_n;
  wire        ddr3_reset_n;
  wire [ 0:0] ddr3_ck_p;
  wire [ 0:0] ddr3_ck_n;
  wire [ 0:0] ddr3_cke;
  wire [ 1:0] ddr3_dm;
  wire [ 0:0] ddr3_odt;

  import rvlab_ddr_pkg::*;

  ///////////////////
  //               //
  // INSTANTIATION //
  //               //
  ///////////////////

  rvlab_tlul_ddr DUT (
    .clk_i       (sysclk),
    .rst_ni      (rstn),
    .clk_100mhz_i(clk100),

    .tl_i     (tl_host_h2d),
    .tl_o     (tl_host_d2h),
    .tl_ctrl_i(tl_ctrl_h2d),
    .tl_ctrl_o(tl_ctrl_d2h),

    .ddr3_dq     (ddr3_dq),
    .ddr3_dqs_n  (ddr3_dqs_n),
    .ddr3_dqs_p  (ddr3_dqs_p),
    .ddr3_addr   (ddr3_addr),
    .ddr3_ba     (ddr3_ba),
    .ddr3_ras_n  (ddr3_ras_n),
    .ddr3_cas_n  (ddr3_cas_n),
    .ddr3_we_n   (ddr3_we_n),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ck_p   (ddr3_ck_p),
    .ddr3_ck_n   (ddr3_ck_n),
    .ddr3_cke    (ddr3_cke),
    .ddr3_dm     (ddr3_dm),
    .ddr3_odt    (ddr3_odt)
  );

  ddr3 ddr3_model_i (
      .rst_n  (ddr3_reset_n),
      .ck     (ddr3_ck_p),
      .ck_n   (ddr3_ck_n),
      .cke    (ddr3_cke),
      .cs_n   ('0),
      .ras_n  (ddr3_ras_n),
      .cas_n  (ddr3_cas_n),
      .we_n   (ddr3_we_n),
      .dm_tdqs(ddr3_dm),
      .ba     (ddr3_ba),
      .addr   (ddr3_addr),
      .dq     (ddr3_dq),
      .dqs    (ddr3_dqs_p),
      .dqs_n  (ddr3_dqs_n),
      .tdqs_n (),
      .odt    (ddr3_odt)
  );

  /////////////
  // Testing //
  /////////////

  tlul_test_host bus (
    .clk_i (sysclk),
    .rst_no(),
    .tl_i  (tl_host_d2h),
    .tl_o  (tl_host_h2d)
  );

  tlul_test_host bus_ctrl (
    .clk_i (sysclk),
    .rst_no(rstn),
    .tl_i  (tl_ctrl_d2h),
    .tl_o  (tl_ctrl_h2d)
  );

  logic [31:0] rdata;
  logic        calib_complete;
  assign calib_complete = rdata[1];

  initial begin
    bus_ctrl.reset();

    bus_ctrl.put_word(32'h1f001004, 32'h1); // deassert reset

    rdata <= '0;
    #1;
    while (!calib_complete) begin
      bus_ctrl.get_word(32'h1f001000, rdata);
    end

    $display("DDR3 calibration complete!");

    bus.put_word(32'h10000000, 32'hbeefcafe);

    bus.contiguous_write(32'h00000000, 16448);
    bus.contiguous_read(32'h00000000, 16448);

    bus.get_word(32'h10000000, rdata);
    bus.get_word(32'h00000000, rdata);

    bus.wait_cycles(100);

    $finish;
  end

endmodule
