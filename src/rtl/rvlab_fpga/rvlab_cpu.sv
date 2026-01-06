// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2025 RVLab Contributors

module rvlab_cpu #(
  parameter logic PIPELINE_I_O = '1,
  parameter logic PIPELINE_I_I = '0,
  parameter logic PIPELINE_D_O = '0,
  parameter logic PIPELINE_D_I = '0,

  parameter logic RANDOMIZE_I = '0,
  parameter logic RANDOMIZE_D = '0
) (
  // Clock and Reset
  input logic clk_i,
  input logic rst_ni,

  input logic irq_external_i,
  input logic irq_timer_i,

  // Instruction memory interface
  output tlul_pkg::tl_h2d_t tl_i_o,
  input  tlul_pkg::tl_d2h_t tl_i_i,

  // Data memory interface
  output tlul_pkg::tl_h2d_t tl_d_o,
  input  tlul_pkg::tl_d2h_t tl_d_i,

  // Debug Interface
  input  logic       debug_req_i
);


  import tlul_pkg::*;
  import top_pkg::*;

  localparam int WordSize = $clog2(TL_DW / 8);
  
  // Instruction interface (internal)
  logic           instr_req;
  logic           instr_gnt;
  logic           instr_rvalid;
  logic    [31:0] instr_addr;
  logic    [31:0] instr_rdata;
  logic           instr_err;

  // Data interface (internal)
  logic           data_req;
  logic           data_gnt;
  logic           data_rvalid;
  logic           data_we;
  logic    [ 3:0] data_be;
  logic    [31:0] data_addr;
  logic    [31:0] data_wdata;
  logic    [31:0] data_rdata;
  logic           data_err;
  
  ////////////////////////////
  // CV32E40P Instantiation //
  ////////////////////////////
  
  logic [31:0] irq_bus;
  always_comb begin
  	irq_bus = '0;
  	irq_bus[7] = irq_timer_i;
  	irq_bus[11] = irq_external_i;
  end

  /* CORE */
	cv32e40p_top #(
  	.NUM_MHPMCOUNTERS(10)
	) u_core_default (
		.clk_i,
		.rst_ni,
		
		.pulp_clock_en_i('0),
		.scan_cg_en_i('0),
		
		.boot_addr_i        (32'h00000080),
		.mtvec_addr_i       (32'h00000000),
		.dm_halt_addr_i     (32'h1E000800),
		.dm_exception_addr_i(32'h1E000808),
		.hart_id_i          ('0),
		
		.instr_req_o   (instr_req),
		.instr_gnt_i   (instr_gnt),
		.instr_rvalid_i(instr_rvalid),
		.instr_addr_o  (instr_addr),
		.instr_rdata_i (instr_rdata),

		.data_req_o    (data_req),
		.data_gnt_i    (data_gnt),
		.data_rvalid_i (data_rvalid),
		.data_we_o     (data_we),
		.data_be_o     (data_be),
		.data_addr_o   (data_addr),
		.data_wdata_o  (data_wdata),
		.data_rdata_i  (data_rdata),

		.irq_i    (irq_bus),
		.irq_ack_o(),
		.irq_id_o (),

		.debug_req_i,
		.debug_havereset_o(),
		.debug_running_o  (),
		.debug_halted_o   (),

		.fetch_enable_i('1),
		.core_sleep_o  ()
	);

  //////////////////
  // BUS TOPOLOGY //
  //////////////////

  /* Instruction Port */
  tl_h2d_t i_adapter_to_fifo;
  tl_d2h_t i_fifo_to_adapter;

  // FIFO outputs to randomizer
  tl_h2d_t i_fifo_h2d;
  tl_d2h_t i_fifo_d2h;


  /* Data port */
  tl_h2d_t d_adapter_to_fifo;
  tl_d2h_t d_fifo_to_adapter;

  // FIFO outputs to randomizer
  tl_h2d_t d_fifo_h2d;
  tl_d2h_t d_fifo_d2h;


  /* I-Port component instantiation */
  tlul_obi_adapter #(
  	.ROB_DEPTH(4)
  ) instr_adapter (
  	.clk_i,
  	.rst_ni,
  	
  	.obi_req_i   (instr_req),
  	.obi_gnt_o   (instr_gnt),
  	.obi_rvalid_o(instr_rvalid),
  	.obi_we_i    ('0),
  	.obi_be_i    ('0),
  	.obi_addr_i  (instr_addr),
  	.obi_wdata_i ('0),
  	.obi_rdata_o (instr_rdata),
  	
  	.tl_i        (i_fifo_to_adapter),
  	.tl_o        (i_adapter_to_fifo)
  );

  tlul_fifo_sync #(
		.ReqPass (~PIPELINE_I_O),
		.RspPass (~PIPELINE_I_I),
		.ReqDepth(2),
		.RspDepth(2)
  ) fifo_i (
		.clk_i,
		.rst_ni,
		.tl_h_i     (i_adapter_to_fifo),
		.tl_h_o     (i_fifo_to_adapter),
		.tl_d_o     (i_fifo_h2d),
		.tl_d_i     (i_fifo_d2h),
		.spare_req_i(1'b0),
		.spare_req_o(),
		.spare_rsp_i(1'b0),
		.spare_rsp_o()
  );
  
  generate
    if (RANDOMIZE_I) begin
      tlul_order_randomizer #(
        .LFSR_SEED  (16'h67CD),
        .WAIT_CYCLES(4)
      ) insn_randomizer (
        .clk_i,
        .rst_ni,

        .host_i  (i_fifo_h2d),
        .host_o  (i_fifo_d2h),
        .device_i(tl_i_i),
        .device_o(tl_i_o)
      );
    end else begin
      assign tl_i_o = i_fifo_h2d;
      assign i_fifo_d2h = tl_i_i;
    end
  endgenerate



  /* D-Port component instantiation */
  tlul_obi_adapter #(
  	.ROB_DEPTH(4)
  ) data_adapter (
  	.clk_i,
  	.rst_ni,
  	
  	.obi_req_i   (data_req),
  	.obi_gnt_o   (data_gnt),
  	.obi_rvalid_o(data_rvalid),
  	.obi_we_i    (data_we),
  	.obi_be_i    (data_be),
  	.obi_addr_i  (data_addr),
  	.obi_wdata_i (data_wdata),
  	.obi_rdata_o (data_rdata),
  	
  	.tl_i        (d_fifo_to_adapter),
  	.tl_o        (d_adapter_to_fifo)
  );

  tlul_fifo_sync #(
    .ReqPass (~PIPELINE_D_O),
    .RspPass (~PIPELINE_D_I),
    .ReqDepth(2),
    .RspDepth(2)
  ) fifo_d (
    .clk_i,
    .rst_ni,
    .tl_h_i     (d_adapter_to_fifo),
    .tl_h_o     (d_fifo_to_adapter),
    .tl_d_o     (d_fifo_h2d),
    .tl_d_i     (d_fifo_d2h),
    .spare_req_i(1'b0),
    .spare_req_o(),
    .spare_rsp_i(1'b0),
    .spare_rsp_o()
  );

  generate
    if (RANDOMIZE_D) begin
      tlul_order_randomizer #(
        .LFSR_SEED  (16'h4545),
        .WAIT_CYCLES(4)
      ) insn_randomizer (
        .clk_i,
        .rst_ni,

        .host_i  (d_fifo_h2d),
        .host_o  (d_fifo_d2h),
        .device_i(tl_d_i),
        .device_o(tl_d_o)
      );
    end else begin
      assign tl_d_o = d_fifo_h2d;
      assign d_fifo_d2h = tl_d_i;
    end
  endgenerate
  
endmodule
