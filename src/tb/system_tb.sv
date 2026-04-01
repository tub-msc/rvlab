// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module system_tb;

  // Signal definitions
  // ------------------

  logic       clk;

  logic       srst_n;
  logic [7:0] led;
  logic [7:0] switch;

  wire        uart_rx_out;
  wire        uart_tx_in;
  wire        ps2_clk;
  wire        ps2_data;
  wire        scl;
  wire        sda;

  wire        oled_sdin;
  wire        oled_sclk;
  wire        oled_dc;
  wire        oled_res;
  wire        oled_vbat;
  wire        oled_vdd;

  wire        ac_adc_sdata;
  wire        ac_bclk;
  wire        ac_lrclk;
  wire        ac_mclk;
  wire        ac_dac_sdata;

  wire        sd_sck;
  wire        sd_mosi;
  wire        sd_cs;
  wire        sd_reset;
  wire        sd_cd;
  wire        sd_miso;

  wire        hdmi_rx_clk_n;
  wire        hdmi_rx_clk_p;
  wire  [2:0] hdmi_rx_n;
  wire  [2:0] hdmi_rx_p;
  wire        hdmi_rx_cec;
  wire        hdmi_rx_scl;
  wire        hdmi_rx_sda;
  wire        hdmi_rx_hpa;
  wire        hdmi_rx_txen;
  wire        hdmi_tx_clk_n;
  wire        hdmi_tx_clk_p;
  wire  [2:0] hdmi_tx_n;
  wire  [2:0] hdmi_tx_p;
  wire        hdmi_tx_cec;
  wire        hdmi_tx_rscl;
  wire        hdmi_tx_rsda;
  wire        hdmi_tx_hpd;

  wire  [3:0] eth_rxd;
  wire        eth_rxctl;
  wire        eth_rxck;
  wire  [3:0] eth_txd;
  wire        eth_txctl;
  wire        eth_txck;
  wire        eth_mdio;
  wire        eth_mdc;
  wire        eth_int_b;
  wire        eth_pme_b;
  wire        eth_rst_b;

  wire  [7:0] pmod_a;
  wire  [7:0] pmod_b;
  wire  [7:0] pmod_c;

  // JTAG
  // ----

  jtag_master jtag ();

  // Set board inputs to valid default values
  // ----------------------------------------

  assign                switch        = '0;
  assign                srst_n        = '1;  // System reset is done via MMCM lock

  assign                uart_tx_in    = '0;

  assign (weak1, weak0) ps2_clk       = '1;
  assign (weak1, weak0) ps2_data      = '1;

  assign (weak1, weak0) scl           = '1;
  assign (weak1, weak0) sda           = '1;

  assign                ac_dac_sdata  = '0;

  assign                sd_cd         = '0;
  assign                sd_miso       = '0;

  assign                hdmi_rx_clk_n = '0;
  assign                hdmi_rx_clk_p = '0;
  assign                hdmi_rx_n     = '0;
  assign                hdmi_rx_p     = '0;

  assign (weak1, weak0) hdmi_rx_cec   = '1;
  assign (weak1, weak0) hdmi_rx_scl   = '1;
  assign (weak1, weak0) hdmi_rx_sda   = '1;

  assign (weak1, weak0) hdmi_tx_cec   = '1;
  assign (weak1, weak0) hdmi_tx_rscl  = '1;
  assign (weak1, weak0) hdmi_tx_rsda  = '1;

  assign                hdmi_tx_hpd   = '0;

  assign                eth_rxd       = '0;
  assign                eth_rxctl     = '0;
  assign                eth_rxck      = '0;
  assign (weak1, weak0) eth_mdio      = '0;
  assign                eth_int_b     = '1;
  assign                eth_pme_b     = '1;

  assign (weak1, weak0) pmod_a        = '0;
  assign (weak1, weak0) pmod_b        = '0;
  assign (weak1, weak0) pmod_c        = '0;

  // Clock source
  // ------------

  always begin
    clk = '1;
    #5000;
    clk = '0;
    #5000;
  end

  // Nexys Video board (including FPGA)
  // ----------------------------------

  rvlab_board board (
    .clk_100mhz_i(clk),
    .jtag_tck_i  (jtag.tck),
    .jtag_tdi_i  (jtag.tdi),
    .jtag_tdo_o  (jtag.tdo),
    .jtag_tms_i  (jtag.tms),
    .jtag_trst_ni(jtag.trst_n),
    .jtag_srst_ni(srst_n),

    .led_o   (led),
    .switch_i(switch),
    .uart_rx_out,
    .uart_tx_in,
    .ps2_clk,
    .ps2_data,
    .scl,
    .sda,

    .oled_sdin,
    .oled_sclk,
    .oled_dc,
    .oled_res,
    .oled_vbat,
    .oled_vdd,

    .ac_adc_sdata,
    .ac_bclk,
    .ac_lrclk,
    .ac_mclk,
    .ac_dac_sdata,

    .sd_sck,
    .sd_mosi,
    .sd_cs,
    .sd_reset,
    .sd_cd,
    .sd_miso,

    .hdmi_rx_clk_n,
    .hdmi_rx_clk_p,
    .hdmi_rx_n,
    .hdmi_rx_p,
    .hdmi_rx_cec,
    .hdmi_rx_scl,
    .hdmi_rx_sda,
    .hdmi_rx_hpa,
    .hdmi_rx_txen,
    .hdmi_tx_clk_n,
    .hdmi_tx_clk_p,
    .hdmi_tx_n,
    .hdmi_tx_p,
    .hdmi_tx_cec,
    .hdmi_tx_rscl,
    .hdmi_tx_rsda,
    .hdmi_tx_hpd,

    .eth_rxd,
    .eth_rxctl,
    .eth_rxck,
    .eth_txd,
    .eth_txctl,
    .eth_txck,
    .eth_mdio,
    .eth_mdc,
    .eth_int_b,
    .eth_pme_b,
    .eth_rst_b,

    .pmod_a,
    .pmod_b,
    .pmod_c
  );

  // Testbench main routine
  // ----------------------

  rvlab_tests tests (
    .jtag (jtag),
    .clk_i(clk)
  );

  initial begin
    string sw_mem_filename;

    tests.test_idcode();
    tests.test_dtmcs();

    if ($value$plusargs("jtag_prog_mem=%s", sw_mem_filename)) begin
      $display("rvlab_tests: Running software %s.", sw_mem_filename);
      tests.test_sw(sw_mem_filename);
    end else begin
      $error("rvlab_tests: No software provided via plusarg jtag_prog_mem.");
    end

    $finish;
  end

endmodule
