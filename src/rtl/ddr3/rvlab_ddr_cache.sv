// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

/* Wrapper around rvlab_ddr_block_cache, adding 32-bit wide TL-UL access. */

module rvlab_ddr_cache #(
  parameter int IDX_BITS = 9
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,

  output rvlab_ddr_pkg::ddr3_h2d_t block_req_o,
  input  rvlab_ddr_pkg::ddr3_d2h_t block_rsp_i
);

  import rvlab_ddr_pkg::*;

  ddr3_h2d_t blk_cache_req;
  ddr3_d2h_t blk_cache_rsp;

  wire [4:2] blk_wordsel;
  assign blk_wordsel = tl_i.a_address[4:2];

  always_comb begin
    blk_cache_req = '{
      a_valid  : tl_i.a_valid,
      a_opcode : tl_i.a_opcode,
      a_address: tl_i.a_address[5+:DDR_AW],
      a_anc    : {tl_i.a_source, blk_wordsel},
      d_ready  : tl_i.d_ready,
      default  : '0
    };
    for (int i = 0; i < 8; i++) begin
      // Runs once per word in the block size
      if (blk_wordsel == i) begin
        blk_cache_req.a_mask[4*i+:4] = tl_i.a_mask;
        blk_cache_req.a_data[32*i+:32] = tl_i.a_data;
      end
    end
  end

  always_comb begin
    tl_o = '{
      d_valid : blk_cache_rsp.d_valid,
      d_opcode: blk_cache_rsp.d_opcode,
      d_size  : 8'h2,
      d_source: blk_cache_rsp.d_anc[3+:top_pkg::TL_AIW],
      a_ready : blk_cache_rsp.a_ready,
      default : '0
    };

    unique case (blk_cache_rsp.d_anc[2:0])
      3'b000: tl_o.d_data = blk_cache_rsp.d_data[  0+:32];
      3'b001: tl_o.d_data = blk_cache_rsp.d_data[ 32+:32];
      3'b010: tl_o.d_data = blk_cache_rsp.d_data[ 64+:32];
      3'b011: tl_o.d_data = blk_cache_rsp.d_data[ 96+:32];
      3'b100: tl_o.d_data = blk_cache_rsp.d_data[128+:32];
      3'b101: tl_o.d_data = blk_cache_rsp.d_data[160+:32];
      3'b110: tl_o.d_data = blk_cache_rsp.d_data[192+:32];
      3'b111: tl_o.d_data = blk_cache_rsp.d_data[224+:32];
    endcase
  end

  rvlab_ddr_block_cache #(
    .IDX_BITS(IDX_BITS)
  ) cache_i (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .fe_req_i(blk_cache_req),
    .fe_rsp_o(blk_cache_rsp),
    .be_req_o(block_req_o),
    .be_rsp_i(block_rsp_i)
  );

endmodule
