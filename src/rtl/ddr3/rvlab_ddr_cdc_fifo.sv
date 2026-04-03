// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors


module rvlab_ddr_cdc_fifo #(
  parameter int unsigned ReqDepth = 3, // minimum 3
  parameter int unsigned RspDepth = 3  // minimum 3
) (
  input logic clk_h_i,
  input logic rst_h_ni,
  input logic clk_d_i,
  input logic rst_d_ni,

  input  rvlab_ddr_pkg::ddr3_h2d_t wtl_h_i,
  output rvlab_ddr_pkg::ddr3_d2h_t wtl_h_o,
  output rvlab_ddr_pkg::ddr3_h2d_t wtl_d_o,
  input  rvlab_ddr_pkg::ddr3_d2h_t wtl_d_i
);

  prim_fifo_async #(
    .Width($bits(rvlab_ddr_pkg::ddr3_h2d_t)-2),
    .Depth(ReqDepth)
  ) reqfifo_i (
    .clk_wr_i      (clk_h_i),
    .rst_wr_ni     (rst_h_ni),
    .clk_rd_i      (clk_d_i),
    .rst_rd_ni     (rst_d_ni),
    .wvalid        (wtl_h_i.a_valid),
    .wready        (wtl_h_o.a_ready),
    .wdata         ({wtl_h_i.a_opcode,
                     wtl_h_i.a_address,
                     wtl_h_i.a_mask,
                     wtl_h_i.a_data,
                     wtl_h_i.a_anc}),
    .rvalid        (wtl_d_o.a_valid),
    .rready        (wtl_d_i.a_ready),
    .rdata         ({wtl_d_o.a_opcode,
                     wtl_d_o.a_address,
                     wtl_d_o.a_mask,
                     wtl_d_o.a_data,
                     wtl_d_o.a_anc}),
    .wdepth        (),
    .rdepth        ()
  );

  prim_fifo_async #(
    .Width($bits(rvlab_ddr_pkg::ddr3_d2h_t)-2),
    .Depth(RspDepth)
  ) rspfifo_i (
    .clk_wr_i      (clk_d_i),
    .rst_wr_ni     (rst_d_ni),
    .clk_rd_i      (clk_h_i),
    .rst_rd_ni     (rst_h_ni),
    .wvalid        (wtl_d_i.d_valid),
    .wready        (wtl_d_o.d_ready),
    .wdata         ({wtl_d_i.d_opcode, wtl_d_i.d_data, wtl_d_i.d_anc}),
    .rvalid        (wtl_h_o.d_valid),
    .rready        (wtl_h_i.d_ready),
    .rdata         ({wtl_h_o.d_opcode, wtl_h_o.d_data, wtl_h_o.d_anc}),
    .wdepth        (),
    .rdepth        ()
  );

endmodule
