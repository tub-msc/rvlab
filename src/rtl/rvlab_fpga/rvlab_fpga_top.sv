// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module rvlab_fpga_top (
  input logic clk_100mhz_i,

  input  logic jtag_tck_i,
  input  logic jtag_tdi_i,
  output logic jtag_tdo_o,
  input  logic jtag_tms_i,
  input  logic jtag_trst_ni,
  input  logic jtag_srst_ni,

  inout  wire [15:0] ddr3_dq,
  inout  wire [ 1:0] ddr3_dqs_n,
  inout  wire [ 1:0] ddr3_dqs_p,
  output wire [14:0] ddr3_addr,
  output wire [ 2:0] ddr3_ba,
  output wire        ddr3_ras_n,
  output wire        ddr3_cas_n,
  output wire        ddr3_we_n,
  output wire        ddr3_reset_n,
  output wire [ 0:0] ddr3_ck_p,
  output wire [ 0:0] ddr3_ck_n,
  output wire [ 0:0] ddr3_cke,
  output wire [ 1:0] ddr3_dm,
  output wire [ 0:0] ddr3_odt,

  output wire [7:0] led_o,
  input  wire [7:0] switch_i,
  output wire       uart_rx_out,
  input  wire       uart_tx_in,
  inout  wire       ps2_clk,
  inout  wire       ps2_data,
  inout  wire       scl,
  inout  wire       sda,

  output wire oled_sdin,
  output wire oled_sclk,
  output wire oled_dc,
  output wire oled_res,
  output wire oled_vbat,
  output wire oled_vdd,

  input wire ac_adc_sdata,
  output wire ac_bclk,
  output wire ac_lrclk,
  output wire ac_mclk,
  output  wire ac_dac_sdata,

  output wire sd_sck,
  output wire sd_mosi,
  output wire sd_cs,
  output wire sd_reset,
  input  wire sd_cd,
  input  wire sd_miso,

  input  wire       hdmi_rx_clk_n,
  input  wire       hdmi_rx_clk_p,
  input  wire [2:0] hdmi_rx_n,
  input  wire [2:0] hdmi_rx_p,
  inout  wire       hdmi_rx_cec,
  inout  wire       hdmi_rx_scl,
  inout  wire       hdmi_rx_sda,
  output wire       hdmi_rx_hpa,
  output wire       hdmi_rx_txen,
  output wire       hdmi_tx_clk_n,
  output wire       hdmi_tx_clk_p,
  output wire [2:0] hdmi_tx_n,
  output wire [2:0] hdmi_tx_p,
  inout  wire       hdmi_tx_cec,
  inout  wire       hdmi_tx_rscl,
  inout  wire       hdmi_tx_rsda,
  input  wire       hdmi_tx_hpd,

  input  wire [3:0] eth_rxd,
  input  wire       eth_rxctl,
  input  wire       eth_rxck,
  output wire [3:0] eth_txd,
  output wire       eth_txctl,
  output wire       eth_txck,
  inout  wire       eth_mdio,
  output wire       eth_mdc,
  input  wire       eth_int_b,
  input  wire       eth_pme_b,
  output wire       eth_rst_b,

  inout wire [7:0] pmod_a,
  inout wire [7:0] pmod_b,
  inout wire [7:0] pmod_c
);

  import tlul_pkg::*;
  import top_pkg::*;

  // Reset and clock generation
  // --------------------------

  logic sys_clk;
  logic clk_200mhz;
  logic clk_100mhz_buffered;
  logic locked;
  logic ndmreset;
  logic recovery_reset; // fallback when system clock prescaler
                        // is set too low
  logic locked_q = '0;  // fpga bitstream init val = reset active
  logic dbg_rst_n = '0;  // fpga bitstream init val = reset active
  logic sys_rst_n = '0;  // fpga bitstream init val = reset active

  tl_h2d_t tl_clk_reconf_h2d;
  tl_d2h_t tl_clk_reconf_d2h;

  rvlab_clkmgr clkmgr_i (
    .clk_100mhz_i         (clk_100mhz_i),
    .clk_100mhz_buffered_o(clk_100mhz_buffered),
    .sys_clk_o            (sys_clk),
    .clk_200mhz_o         (clk_200mhz),
    .locked_o             (locked),
    
    .sys_rst_no           (recovery_reset),
    .jtag_srst_ni,

    .tl_reconfig_i        (tl_clk_reconf_h2d),
    .tl_reconfig_o        (tl_clk_reconf_d2h),
    .reconfig_status_o    ()
  );


  always_ff @(posedge sys_clk) begin
    // dbg_rst_n is only asserted through locked right after bitstream loading.
    // The external system reset button is disconnected for mechanical reasons
    // and simplicity.
    locked_q  <= locked && jtag_srst_ni && recovery_reset;
    dbg_rst_n <= locked_q;
    // Attention: ndmreset and dbg_rst_n are both synchronous, but not
    // glitch-free, so we need another FF.
    sys_rst_n <= (dbg_rst_n & ~ndmreset);
    // sys_rst_n can be asserted at runtime via the RISC-V JTAG debug (ndmreset).
  end

  // TDO negative edge FF
  // --------------------

  logic tdo_posedge;

  (* IOB = "TRUE" *)
  // This places the FF in the IOB (improving timing)
  FDRE #(
    .INIT('0)
  ) tdo_flop_i (
    .Q (jtag_tdo_o),
    .C (~jtag_tck_i),
    .CE('1),
    .R ('0),
    .D (tdo_posedge)
  );

  // TL-UL DDR3 external memory controller
  // -------------------------------------

  tlul_pkg::tl_h2d_t tl_ddr_h2d, tl_ddr_ctrl_h2d;
  tlul_pkg::tl_d2h_t tl_ddr_d2h, tl_ddr_ctrl_d2h;

  rvlab_tlul_ddr tlul_ddr_i (
    .clk_i                (sys_clk),
    .clk_100mhz_buffered_i(clk_100mhz_buffered),
    .clk_200mhz_i         (clk_200mhz),
    .rst_ni               (sys_rst_n),
    .tl_i                 (tl_ddr_h2d),
    .tl_o                 (tl_ddr_d2h),
    .tl_ctrl_i            (tl_ddr_ctrl_h2d),
    .tl_ctrl_o            (tl_ddr_ctrl_d2h),

    .ddr3_dq,
    .ddr3_dqs_n,
    .ddr3_dqs_p,
    .ddr3_addr,
    .ddr3_ba,
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_reset_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_dm,
    .ddr3_odt
  );


  // User I/O pin connections
  // ------------------------

  userio_board2fpga_t userio_b2f;
  userio_fpga2board_t userio_f2b;

  assign led_o                 = userio_f2b.led;
  assign userio_b2f.switch     = switch_i;

  assign userio_b2f.uart_tx_in = uart_tx_in;
  assign uart_rx_out           = userio_f2b.uart_rx_out;

  // PS/2 keyboard / mouse:
  iocell_opendrain io_ps2_clk (
    .pad(ps2_clk),
    .oe (userio_f2b.ps2_clk_oe),
    .in (userio_b2f.ps2_clk)
  );
  iocell_opendrain io_ps2_data (
    .pad(ps2_data),
    .oe (userio_f2b.ps2_data_oe),
    .in (userio_b2f.ps2_data)
  );

  // I2C for Audio codec and Ethernet-associated EEPROM:
  iocell_opendrain io_scl (
    .pad(scl),
    .oe (userio_f2b.scl_oe),
    .in (userio_b2f.scl)
  );
  iocell_opendrain io_sda (
    .pad(sda),
    .oe (userio_f2b.sda_oe),
    .in (userio_b2f.sda)
  );

  // Mini OLED display
  // -----------------

  assign oled_sdin               = userio_f2b.oled_sdin;
  assign oled_sclk               = userio_f2b.oled_sclk;
  assign oled_dc                 = userio_f2b.oled_dc;
  assign oled_res                = userio_f2b.oled_res;
  assign oled_vbat               = userio_f2b.oled_vbat;
  assign oled_vdd                = userio_f2b.oled_vdd;

  // Audio codec
  // -----------

  assign ac_dac_sdata            = userio_f2b.ac_dac_sdata;
  assign ac_bclk                 = userio_f2b.ac_bclk;
  assign ac_lrclk                = userio_f2b.ac_lrclk;
  assign ac_mclk                 = userio_f2b.ac_mclk;
  assign userio_b2f.ac_adc_sdata = ac_adc_sdata;

  // SD card
  // -------

  assign sd_sck                  = userio_f2b.sd_sck;
  assign sd_mosi                 = userio_f2b.sd_mosi;
  assign sd_cs                   = userio_f2b.sd_cs;
  assign sd_reset                = userio_f2b.sd_reset;
  assign userio_b2f.sd_cd        = sd_cd;
  assign userio_b2f.sd_miso      = sd_miso;

  // hdmi_rx: HDMI sink / input
  // --------------------------

  assign hdmi_rx_hpa             = userio_f2b.hdmi_rx_hpa;
  assign hdmi_rx_txen            = userio_f2b.hdmi_rx_txen;

  IBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_rx_clk (
    .O (userio_b2f.hdmi_rx_clk),
    .I (hdmi_rx_clk_p),
    .IB(hdmi_rx_clk_n)
  );
  IBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_rx0 (
    .O (userio_b2f.hdmi_rx[0]),
    .I (hdmi_rx_p[0]),
    .IB(hdmi_rx_n[0])
  );
  IBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_rx1 (
    .O (userio_b2f.hdmi_rx[1]),
    .I (hdmi_rx_p[1]),
    .IB(hdmi_rx_n[1])
  );
  IBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_rx2 (
    .O (userio_b2f.hdmi_rx[2]),
    .I (hdmi_rx_p[2]),
    .IB(hdmi_rx_n[2])
  );

  iocell_opendrain io_hdmi_rx_cec (
    .pad(hdmi_rx_cec),
    .oe (userio_f2b.hdmi_rx_cec_oe),
    .in (userio_b2f.hdmi_rx_cec)
  );
  iocell_opendrain io_hdmi_rx_scl (
    .pad(hdmi_rx_scl),
    .oe (userio_f2b.hdmi_rx_scl_oe),
    .in (userio_b2f.hdmi_rx_scl)
  );
  iocell_opendrain io_hdmi_rx_sda (
    .pad(hdmi_rx_sda),
    .oe (userio_f2b.hdmi_rx_sda_oe),
    .in (userio_b2f.hdmi_rx_sda)
  );

  // hdmi_tx: HDMI source / output
  // -----------------------------

  assign userio_b2f.hdmi_tx_hpd = hdmi_tx_hpd;

  OBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_tx_clk (
    .I (userio_f2b.hdmi_tx_clk),
    .O (hdmi_tx_clk_p),
    .OB(hdmi_tx_clk_n)
  );
  OBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_tx0 (
    .I (userio_f2b.hdmi_tx[0]),
    .O (hdmi_tx_p[0]),
    .OB(hdmi_tx_n[0])
  );
  OBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_tx1 (
    .I (userio_f2b.hdmi_tx[1]),
    .O (hdmi_tx_p[1]),
    .OB(hdmi_tx_n[1])
  );
  OBUFDS #(
    .IOSTANDARD("TMDS_33")
  ) io_hdmi_tx2 (
    .I (userio_f2b.hdmi_tx[2]),
    .O (hdmi_tx_p[2]),
    .OB(hdmi_tx_n[2])
  );

  iocell_opendrain io_hdmi_tx_cec (
    .pad(hdmi_tx_cec),
    .oe (userio_f2b.hdmi_tx_cec_oe),
    .in (userio_b2f.hdmi_tx_cec)
  );
  iocell_opendrain io_hdmi_tx_rscl (
    .pad(hdmi_tx_rscl),
    .oe (userio_f2b.hdmi_tx_rscl_oe),
    .in (userio_b2f.hdmi_tx_rscl)
  );
  iocell_opendrain io_hdmi_tx_rsda (
    .pad(hdmi_tx_rsda),
    .oe (userio_f2b.hdmi_tx_rsda_oe),
    .in (userio_b2f.hdmi_tx_rsda)
  );

  // Ethernet (RGMII)
  // ----------------

  iocell_bidir io_eth_mdio (
    .pad(eth_mdio),
    .oe (userio_f2b.eth_mdio_oe),
    .out(userio_f2b.eth_mdio_out),
    .in (userio_b2f.eth_mdio)
  );

  assign userio_b2f.eth_rxd   = eth_rxd;
  assign userio_b2f.eth_rxctl = eth_rxctl;
  assign userio_b2f.eth_rxck  = eth_rxck;
  assign userio_b2f.eth_int_b = eth_int_b;
  assign userio_b2f.eth_pme_b = eth_pme_b;
  assign eth_txd              = userio_f2b.eth_txd;
  assign eth_txctl            = userio_f2b.eth_txctl;
  assign eth_txck             = userio_f2b.eth_txck;
  assign eth_mdc              = userio_f2b.eth_mdc;
  assign eth_rst_b            = userio_f2b.eth_rst_b;

  // Pmod ports A, B, C
  // ------------------

  iocell_bidir #(
    .Width(8)
  ) io_pmod_a (
    .pad(pmod_a),
    .oe (userio_f2b.pmod_a_oe),
    .out(userio_f2b.pmod_a_out),
    .in (userio_b2f.pmod_a)
  );

  iocell_bidir #(
    .Width(8)
  ) io_pmod_b (
    .pad(pmod_b),
    .oe (userio_f2b.pmod_b_oe),
    .out(userio_f2b.pmod_b_out),
    .in (userio_b2f.pmod_b)
  );

  iocell_bidir #(
    .Width(8)
  ) io_pmod_c (
    .pad(pmod_c),
    .oe (userio_f2b.pmod_c_oe),
    .out(userio_f2b.pmod_c_out),
    .in (userio_b2f.pmod_c)
  );


  // Core
  // ----

  rvlab_core core_i (
    .clk_i(sys_clk),

    .rst_ni    (sys_rst_n),
    .rst_dbg_ni(dbg_rst_n),
    .ndmreset_o(ndmreset),

    .jtag_tck_i,
    .jtag_tdi_i,
    .jtag_tdo_o(tdo_posedge),
    .jtag_tms_i,
    .jtag_trst_ni,

    .tl_ddr_o     (tl_ddr_h2d),
    .tl_ddr_i     (tl_ddr_d2h),
    .tl_ddr_ctrl_o(tl_ddr_ctrl_h2d),
    .tl_ddr_ctrl_i(tl_ddr_ctrl_d2h),

    .tl_clk_reconf_o(tl_clk_reconf_h2d),
    .tl_clk_reconf_i(tl_clk_reconf_d2h),

    .userio_i(userio_b2f),
    .userio_o(userio_f2b)
  );


endmodule
