// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

module rvlab_ddr3_tb;

  import tlul_pkg::*;
  import rvlab_ddr_pkg::*;

  ////////////
  // Clocks //
  ////////////

  // sysclk = 50mhz
  logic sysclk, clk100, clk200, clk400, clk400_90;
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

  /* 200MHz (DDR3 Reference) Clock */
  always begin
    clk200 = '1;
    #2500;
    clk200 = '0;
    #2500;
  end

  /* 400MHz (Main DDR3) Clock */
  always begin
    clk400 = '1;
    #1250;
    clk400 = '0;
    #1250;
  end

  /* 400MHz 90° Clock */
  always begin
    #625;
    clk400_90 = '1;
    #1250;
    clk400_90 = '0;
    #625;
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
  wire [ 0:0] ddr3_cs_n;
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

  logic         ddr3if_stb;
  logic         ddr3if_we;
  logic [ 24:0] ddr3if_blk_addr;
  logic [127:0] ddr3if_wdata;
  logic         ddr3if_stall;
  logic         ddr3if_ack;
  logic [127:0] ddr3if_rdata;
  logic [ 14:0] ddr3if_req_aux;
  logic [ 14:0] ddr3if_rsp_aux;

  ///////////////////
  //               //
  // INSTANTIATION //
  //               //
  ///////////////////

  ddr3_h2d_t blockmgr_req;
  ddr3_d2h_t blockmgr_rsp;

  /* Block Manager */

  rvlab_ddr_blkmgr #(
    .REQBUF_SIZE(16)
  ) blkmgr_i (
    .clk_i        (clk100),
    .rst_ni       (rstn),

    .req_i        (blockmgr_req),
    .rsp_o        (blockmgr_rsp),

    .wb_stb_o     (ddr3if_stb),
    .wb_we_o      (ddr3if_we),
    .wb_blk_addr_o(ddr3if_blk_addr),
    .wb_wdata_o   (ddr3if_wdata),
    .wb_aux_o     (ddr3if_req_aux),
    .wb_stall_i   (ddr3if_stall),
    .wb_ack_i     (ddr3if_ack),
    .wb_rdata_i   (ddr3if_rdata),
    .wb_aux_i     (ddr3if_rsp_aux)
  );

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
    .AUX_WIDTH(15), //width of aux line (must be >= 4)
    .MICRON_SIM(1), //enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
    .ODELAY_SUPPORTED(0), //set to 1 if ODELAYE2 is supported
    .SECOND_WISHBONE(0), //set to 1 if 2nd wishbone for debugging is needed 
    .ECC_ENABLE(0), // set to 1 or 2 to add ECC (1 = Side-band ECC per burst, 2 = Side-band ECC per 8 bursts , 3 = Inline ECC ) 
    .WB_ERROR(0) // set to 1 to support Wishbone error (asserts at ECC double bit error)
  ) ddr_i (
  //clock and reset
    .i_controller_clk(clk100),
    .i_ddr3_clk(clk400), //i_controller_clk has period of CONTROLLER_CLK_PERIOD, i_ddr3_clk has period of DDR3_CLK_PERIOD 
    .i_ref_clk(clk200), // usually set to 200 MHz 
    .i_ddr3_clk_90(clk400_90), //90 degree phase shifted version i_ddr3_clk (required only when ODELAY_SUPPORTED is zero)
    .i_rst_n(rstn),
    //
    // Wishbone inputs
    .i_wb_cyc('1), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    .i_wb_stb(ddr3if_stb), //request a transfer
    .i_wb_we(ddr3if_we), //write-enable (1 = write, 0 = read)
    .i_wb_addr(ddr3if_blk_addr), //burst-addressable {row,bank,col} 
    .i_wb_data(ddr3if_wdata), //write data, for a 4:1 controller data width is 8 times the number of pins on the device
    .i_wb_sel(16'hffff), //byte strobe for write (1 = write the byte)
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
    .o_ddr3_cs_n(ddr3_cs_n), // width = number of DDR3 ranks
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
    // Debug outputs
    .o_debug1()
  );

  /*rvlab_tlul_ddr DUT (
    .clk_i                (sysclk),
    .rst_ni               (rstn),
    .clk_100mhz_buffered_i(clk100),
    .clk_200mhz_i         (clk200),
    .clk_400mhz_i         (clk400),

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
  );*/

  ddr3 ddr3_model_i (
      .rst_n  (ddr3_reset_n),
      .ck     (ddr3_ck_p),
      .ck_n   (ddr3_ck_n),
      .cke    (ddr3_cke),
      .cs_n   (ddr3_cs_n),
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

  /*tlul_test_host bus (
    .clk_i (sysclk),
    .rst_no(rstn),
    .tl_i  (tl_host_d2h),
    .tl_o  (tl_host_h2d)
  );*/

  task reset();
    rstn <= '0;
    blockmgr_req <= '{
      a_opcode: Get,
      default: '0
    };
    @(posedge clk100);
    @(posedge clk100);
    rstn <= '1;
    @(posedge clk100);
    @(posedge clk100);
  endtask

  task wait_cycles(input integer n_cycles);
    integer i;
    for (i = 0; i < n_cycles; i++) @(posedge clk100);
  endtask

  task do_transaction();
    integer i;
    // Send request on A channel:
    blockmgr_req.a_valid <= '1;
    @(posedge clk100);
    i = '0;
    while (!blockmgr_rsp.a_ready) begin
      if (i++ == 10) begin
        $display("Warning: device takes > 10 cycles to respond.");
      end
      @(posedge clk100);
    end
    blockmgr_req.a_valid <= '0;
    blockmgr_req.d_ready <= '1;
    //@(posedge clk100);
    //blockmgr_req <= TlIdle;  // a_valid <= '0;
    while (!blockmgr_rsp.d_valid) begin
      @(posedge clk100);
    end
  endtask

  task put_full(input logic [DDR_AW-1:0] addr, input logic [255:0] wdata);
    blockmgr_req.a_address <= addr;
    blockmgr_req.a_opcode  <= tlul_pkg::PutFullData;
    blockmgr_req.a_data    <= wdata;
    blockmgr_req.a_mask    <= 2'b11;
    do_transaction();
    if (blockmgr_rsp.d_opcode != tlul_pkg::AccessAck) begin
      $display("Warning: put response d_opcode was %p.", blockmgr_rsp.d_opcode);
    end
    @(posedge clk100);
  endtask

  task get_full(input logic [DDR_AW-1:0] addr, output logic [255:0] rdata);
    blockmgr_req.a_address <= addr;
    blockmgr_req.a_opcode  <= tlul_pkg::Get;
    blockmgr_req.a_mask    <= 2'b11;
    do_transaction();
    rdata <= blockmgr_rsp.d_data;
    if (blockmgr_rsp.d_opcode != tlul_pkg::AccessAckData) begin
      $display("Warning: put response d_opcode was %p.", blockmgr_rsp.d_opcode);
    end
    @(posedge clk100);
  endtask

  logic [255:0] rdata;

  initial begin
    reset();

    put_full(25'h1CDCDCD, 256'hFFEEDDCCBBAA0099887766554433221111223344556677889900AABBCCDDEEFF);
    get_full(25'h1CDCDCD, rdata);

    wait_cycles(10000);

    $finish;
  end

endmodule
