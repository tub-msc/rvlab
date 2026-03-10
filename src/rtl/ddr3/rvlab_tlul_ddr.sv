// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

module rvlab_tlul_ddr (
  input logic clk_i,  // sys_clk
  input logic rst_ni,

  input logic clk_100mhz_i,

  // TL-UL slave interface
  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_ctrl_i,
  output tlul_pkg::tl_d2h_t tl_ctrl_o,

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
  output wire [ 0:0] ddr3_odt
);

  import rvlab_ddr_pkg::*;
  import ddr_ctrl_reg_pkg::*;

  /*
    Control Interface Registers:
      - DDR Status:
        - Present
        - Calibration complete
        - Calibration status
      - Control:
        - Self refresh
        - Reset
      - Tags / cache interface?
        -> Tag/Modified mem support
           additional read ports
  */

  //////////////////////////////
  //                          //
  // CONTROL+STATUS REGISTERS //
  //                          //
  //////////////////////////////

  logic       ctrl_ddr_present;
  logic       ctrl_calib_complete;
  logic [4:0] ctrl_calib_status;
  logic       ctrl_ddr_self_refresh;
  logic       ctrl_ddr_rst_n;

  ddr_ctrl_reg2hw_t reg2hw;
  ddr_ctrl_hw2reg_t hw2reg;

  ddr_ctrl_reg_top reg_top_i (
    .clk_i,
    .rst_ni,
    .tl_i     (tl_ctrl_i),
    .tl_o     (tl_ctrl_o),
    .reg2hw,
    .hw2reg,
    .devmode_i('0)
  );

  assign hw2reg.status.present.d = ctrl_ddr_present;
  assign hw2reg.status.calib_complete.d = ctrl_calib_complete;
  assign hw2reg.status.calib_status.d = ctrl_calib_status;

  assign ctrl_ddr_self_refresh = reg2hw.ctrl.self_refresh.q;
  assign ctrl_ddr_rst_n = reg2hw.ctrl.rst_n.q;

`ifdef WITH_EXT_DRAM

  localparam int BLKMGR_REQBUF_SIZE = 16;
  localparam int BLKMGR_REQBUF_IDXW = $clog2(BLKMGR_REQBUF_SIZE);
  localparam int AUXW = BLKMGR_REQBUF_IDXW + DDR_ANCW;

  logic            ddr3if_stb;
  logic            ddr3if_we;
  logic [    24:0] ddr3if_blk_addr;
  logic [   127:0] ddr3if_wdata;
  logic [    15:0] ddr3if_wmask;
  logic [AUXW-1:0] ddr3if_req_aux;
  logic            ddr3if_stall;
  logic            ddr3if_ack;
  logic [   127:0] ddr3if_rdata;
  logic [AUXW-1:0] ddr3if_rsp_aux;

  ///////////////////
  //               //
  // INSTANTIATION //
  //               //
  ///////////////////

  /* Clock */

  logic clk_ctrl;
  logic clk_ref;
  logic clk_fast;
  logic clk_fast90;

  logic ddr_rstn, ddr_locked;

  rvlab_ddr_clkmgr clkmgr_i (
    .clk_100mhz_i,
    .clk_ctrl_o  (clk_ctrl),
    .clk_ref_o   (clk_ref),
    .clk_fast_o  (clk_fast),
    .clk_fast90_o(clk_fast90),
    .locked_o    (ddr_locked)
  );

  /* LLC */

  ddr3_h2d_t blockmgr_req, llc_req;
  ddr3_d2h_t blockmgr_rsp, llc_rsp;

  rvlab_ddr_cache #(
    .IDX_BITS(9)
  ) ddr_llc_i (
    .clk_i,
    .rst_ni,

    .tl_i,
    .tl_o,

    .block_req_o(llc_req),
    .block_rsp_i(llc_rsp)
  );

  /* CDC FIFO */

  rvlab_ddr_cdc_fifo cdc_fifo_i (
    .clk_h_i (clk_i),
    .rst_h_ni(rst_ni),
    .clk_d_i (clk_ctrl),
    .rst_d_ni(ddr_rstn),

    .wtl_h_i (llc_req),
    .wtl_h_o (llc_rsp),
    .wtl_d_o (blockmgr_req),
    .wtl_d_i (blockmgr_rsp)
  );

  /* Block Manager */

  rvlab_ddr_blkmgr #(
    .REQBUF_SIZE(BLKMGR_REQBUF_SIZE)
  ) blkmgr_i (
    .clk_i        (clk_ctrl),
    .rst_ni       (ddr_rstn),

    .req_i        (blockmgr_req),
    .rsp_o        (blockmgr_rsp),

    .wb_stb_o     (ddr3if_stb),
    .wb_we_o      (ddr3if_we),
    .wb_blk_addr_o(ddr3if_blk_addr),
    .wb_wdata_o   (ddr3if_wdata),
    .wb_wmask_o   (ddr3if_wmask),
    .wb_aux_o     (ddr3if_req_aux),
    .wb_stall_i   (ddr3if_stall),
    .wb_ack_i     (ddr3if_ack),
    .wb_rdata_i   (ddr3if_rdata),
    .wb_aux_i     (ddr3if_rsp_aux)
  );

  logic ddr3_self_refresh;
  logic ddr3_calib_complete;

  logic [31:0] ddr3_debug_out;
  logic [ 4:0] ddr3_calib_status;
  assign ddr3_calib_status = ddr3_debug_out[4:0];

  /* DDR3 Controller */
  /*
   * Note on parameter settings: The DDR3 used is assumed to be part MT41K256M16HA-187E. The Nexys Video manual
   *     explicitly states that compatibility with this part can be assumed for our board:
   *     https://digilent.com/reference/programmable-logic/nexys-video/reference-manual (20 Jan 2026)
   *     Configuration options have been extracted from:
   *     https://www.datasheets360.com/pdf/7219336740294538527 (20 Jan 2026)
  */
  ddr3_top #(
    .CONTROLLER_CLK_PERIOD(10_000), //ps, clock period of the controller interface
    .DDR3_CLK_PERIOD(2_500), //ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD) 
    .ROW_BITS(15), //width of row address
    .COL_BITS(10), //width of column address
    .BA_BITS(3), //width of bank address
    .BYTE_LANES(2), //number of byte lanes of DDR3 RAM
    .AUX_WIDTH(AUXW), //width of aux line (must be >= 4)
  `ifndef SYNTHESIS
    .MICRON_SIM(1), //enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
  `endif
    .ODELAY_SUPPORTED(0), //set to 1 if ODELAYE2 is supported
    .SECOND_WISHBONE(0), //set to 1 if 2nd wishbone for debugging is needed 
    .ECC_ENABLE(0), // set to 1 or 2 to add ECC (1 = Side-band ECC per burst, 2 = Side-band ECC per 8 bursts , 3 = Inline ECC ) 
    .WB_ERROR(0) // set to 1 to support Wishbone error (asserts at ECC double bit error)
  ) ddr_i (
    //clock and reset
    .i_controller_clk(clk_ctrl),
    .i_ddr3_clk(clk_fast), //i_controller_clk has period of CONTROLLER_CLK_PERIOD, i_ddr3_clk has period of DDR3_CLK_PERIOD
    .i_ref_clk(clk_ref), // usually set to 200 MHz
    .i_ddr3_clk_90(clk_fast90), //90 degree phase shifted version i_ddr3_clk (required only when ODELAY_SUPPORTED is zero)
    .i_rst_n(ddr_rstn),
    //
    // Wishbone inputs
    .i_wb_cyc(1), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    .i_wb_stb(ddr3if_stb), //request a transfer
    .i_wb_we(ddr3if_we), //write-enable (1 = write, 0 = read)
    .i_wb_addr(ddr3if_blk_addr), //burst-addressable {row,bank,col} 
    .i_wb_data(ddr3if_wdata), //write data, for a 4:1 controller data width is 8 times the number of pins on the device
    .i_wb_sel(ddr3if_wmask), //byte strobe for write (1 = write the byte)
    .i_aux(ddr3if_req_aux), //for AXI-interface compatibility (given upon strobe)
    // Wishbone outputs
    .o_wb_stall(ddr3if_stall), //1 = busy, cannot accept requests
    .o_wb_ack(ddr3if_ack), //1 = read/write request has completed
    .o_wb_err(), //1 = Error due to ECC double bit error (fixed to 0 if WB_ERROR = 0)
    .o_wb_data(ddr3if_rdata), //read data, for a 4:1 controller data width is 8 times the number of pins on the device
    .o_aux(ddr3if_rsp_aux),
    //
    // Wishbone 2 (PHY) inputs
    .i_wb2_cyc(0), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    .i_wb2_stb(0), //request a transfer
    .i_wb2_we(0), //write-enable (1 = write, 0 = read)
    .i_wb2_addr(0), //burst-addressable {row,bank,col} 
    .i_wb2_data(0), //write data, for a 4:1 controller data width is 8 times the number of pins on the device
    .i_wb2_sel(0), //byte strobe for write (1 = write the byte)
    // Wishbone 2 (Controller) outputs
    .o_wb2_stall(), //1 = busy, cannot accept requests
    .o_wb2_ack(), //1 = read/write request has completed
    .o_wb2_data(), //read data, for a 4:1 controller data width is 8 times the number of pins on the device
    //
    // DDR3 I/O Interface
    .o_ddr3_clk_p(ddr3_ck_p), 
    .o_ddr3_clk_n(ddr3_ck_n),
    .o_ddr3_reset_n(ddr3_reset_n),
    .o_ddr3_cke(ddr3_cke), 
    .o_ddr3_cs_n(), // width = number of DDR3 ranks
    .o_ddr3_ras_n(ddr3_ras_n), 
    .o_ddr3_cas_n(ddr3_cas_n), 
    .o_ddr3_we_n(ddr3_we_n), 
    .o_ddr3_addr(ddr3_addr), // width = ROW_BITS
    .o_ddr3_ba_addr(ddr3_ba), // width = BA_BITS
    .io_ddr3_dq(ddr3_dq), // width = BYTE_LANES*8
    .io_ddr3_dqs(ddr3_dqs_p), // width = BYTE_LANES
    .io_ddr3_dqs_n(ddr3_dqs_n), // width = BYTE_LANES
    .o_ddr3_dm(ddr3_dm), // width = BYTE_LANES
    .o_ddr3_odt(ddr3_odt),
    // CSR interface
    .o_debug1(ddr3_debug_out),
    .o_calib_complete(ddr3_calib_complete),
    .i_user_self_refresh(ddr3_self_refresh),
    // UART
    .uart_tx()
  );

  assign ctrl_ddr_present = '1;

  //////////////
  // CTRL CDC //
  //////////////

  /* CTRL clock -> SYS clock domain */

  prim_flop_2sync #(
    .Width(1)
  ) sync_calib_complete_i (
    .clk_i,
    .rst_ni,
    .d     (ddr3_calib_complete),
    .q     (ctrl_calib_complete)
  );

  prim_flop_2sync #(
    .Width(5)
  ) sync_calib_status_i (
    .clk_i,
    .rst_ni,
    .d     (ddr3_calib_status),
    .q     (ctrl_calib_status)
  );

  /* SYS clock -> CTRL clock domain */

  prim_flop_2sync #(
    .Width(1)
  ) sync_self_refresh_i (
    .clk_i (clk_ctrl),
    .rst_ni(ddr_rstn),
    .d     (ctrl_ddr_self_refresh),
    .q     (ddr3_self_refresh)
  );

  prim_flop_2sync #(
    .Width(1)
  ) sync_ddr_reset_i (
    .clk_i (clk_ctrl),
    .rst_ni(ddr_locked),
    .d     (ctrl_ddr_rst_n),
    .q     (ddr_rstn)
  );


`else

  // Make sure all output signals are somehow valid, in case someone tries to
  // build a bitstream of the design without DDR.

  assign ddr3_addr    = '0;
  assign ddr3_ba      = '0;
  assign ddr3_ras_n   = '1;
  assign ddr3_cas_n   = '1;
  assign ddr3_we_n    = '1;
  assign ddr3_reset_n = '0;

  assign ddr3_ck_p    = '1;
  assign ddr3_ck_n    = '0;
  assign ddr3_cke     = '0;

  assign ddr3_dm      = '0;

  assign ctrl_ddr_present = '0;
  assign ctrl_calib_complete = '0;
  assign ctrl_calib_status = '0;

  tlul_short_circuit ddr_short_i (
    .tl_i,
    .tl_o
  );

`endif

endmodule
