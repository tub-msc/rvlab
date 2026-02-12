// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

/* Last-Level Cache for RVLab DDR3 memory. */
/*
 * Features:
 * - Direct-Mapped
 * - 256-bit wide access
 * - Mapped to Block RAM resources
 * - Minimum 16KiB size (configurable)
 *
 * Notes:
 * - Assumed to be used as an LLC (Last-Level Cache).
 *   As such, it does not contain a RAM for data
 *   validation. Data persists across device resets (rst_ni);
 *   this cache should thus not be used in security-sensitive
 *   environments. This is unproblematic for the RISC-V Lab.
*/

module rvlab_ddr_block_cache #(
  parameter int IDX_BITS = 9,
  parameter int TAG_BITS = rvlab_ddr_pkg::DDR_AW - IDX_BITS
) (
  input  logic clk_i,
  input  logic rst_ni,

  /* Front-End */
  input  rvlab_ddr_pkg::ddr3_h2d_t fe_req_i,
  output rvlab_ddr_pkg::ddr3_d2h_t fe_rsp_o,

  /* Back-End */
  output rvlab_ddr_pkg::ddr3_h2d_t be_req_o,
  input  rvlab_ddr_pkg::ddr3_d2h_t be_rsp_i
);

  import rvlab_ddr_pkg::*;
  import tlul_pkg::*;

  localparam int SETS = 2**IDX_BITS;

  reg [       255:0] data_mem [SETS-1:0];
  reg [TAG_BITS-1:0]  tag_mem [SETS-1:0];
  logic         modified_mem [SETS-1:0];

  logic [  DDR_AW-1:0] access_addr;
  logic [IDX_BITS-1:0] access_idx, access_idx_q;
  logic [TAG_BITS-1:0] access_tag, access_tag_q;
  assign access_addr = fe_req_i.a_address;
  assign access_idx  = fe_req_i.a_address[IDX_BITS-1:0];
  assign access_tag  = fe_req_i.a_address[IDX_BITS+:TAG_BITS];

  reg [DDR_ANCW-1:0] ancillary_q;

  tl_a_op_e     access_type_q;
  logic [ 31:0] access_mask_q;
  logic [255:0] access_data_q;

  reg [       255:0] data_rdata;
  reg [TAG_BITS-1:0]  tag_rdata;
  logic              modified_rdata;

  logic stall, stall_d;
  reg   stall_q;

  logic  access, access_q;
  assign access = fe_req_i.a_valid;

  wire   hit, miss;
  assign hit  = tag_rdata == access_tag_q && access_q && ~stall;
  assign miss = tag_rdata != access_tag_q && access_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      access_q <= '0;
      access_idx_q <= '0;
      access_tag_q <= '0;
      access_type_q <= Get;
      access_mask_q <= '0;
      access_data_q <= '0;
      ancillary_q <= '0;
      stall_q <= '0;
    end else begin
      if (~stall) begin
        access_q      <= access;
        access_idx_q  <= access_idx;
        access_tag_q  <= access_tag;
        access_type_q <= fe_req_i.a_opcode;
        access_mask_q <= fe_req_i.a_mask;
        access_data_q <= fe_req_i.a_data;
        ancillary_q   <= fe_req_i.a_anc;
      end

      stall_q <= stall_d;
    end
  end

  always_comb begin
    stall   = stall_q || miss;
    stall_d = stall;

    // Don't accept responses from the backend unless they contain data
    // (don't resume normal activity while evicting)
    if (be_rsp_i.d_valid && be_req_o.d_ready && be_rsp_i.d_opcode == AccessAckData) stall_d = '0;
  end

  /* Memory inference templates */

  /* Data memory */

  wire use_be_port;
  assign use_be_port = be_rsp_i.d_valid && be_req_o.d_ready;

  wire data_wen;
  reg  data_wen_q;
  assign data_wen = use_be_port || (hit && access_type_q inside {PutFullData, PutPartialData});

  wire [31:0] data_wmask;
  reg  [31:0] data_wmask_q;
  assign data_wmask = use_be_port ? '1 : access_mask_q;

  wire [255:0] data_wdata;
  reg  [255:0] data_wdata_q;
  assign data_wdata = use_be_port ? be_rsp_i.d_data : access_data_q;

  reg [255:0] data_rdata_raw;

  always_ff @(posedge clk_i) begin
    if (data_wen) begin
      for (int i = 0; i < 32; i++) begin
        if (data_wmask[i]) begin
          data_mem[access_idx_q][8*i+:8] <= data_wdata[8*i+:8];
        end
      end
    end
    data_rdata_raw <= data_mem[use_be_port ? access_idx_q : access_idx];
  end

  always_ff @(posedge clk_i) begin
    data_wmask_q <= data_wmask;
    data_wdata_q <= data_wdata;
    data_wen_q   <= data_wen;
  end

  generate
    for (genvar i = 0; i < 32; i++) begin
      assign data_rdata[8*i+:8] = data_wen_q && data_wmask_q[i]
                                ? data_wdata_q[8*i+:8]
                                : data_rdata_raw[8*i+:8];
    end
  endgenerate

  // Tag memory
  always_ff @(posedge clk_i) begin
    if (be_req_o.a_valid && be_rsp_i.a_ready && be_req_o.a_opcode == Get) begin
      tag_mem[access_idx_q] <= access_tag_q;
      tag_rdata <= access_tag_q;
    end else begin
      tag_rdata <= tag_mem[access_idx];
    end
  end

  // Flag memory
  wire fe_modify_req;
  assign fe_modify_req = hit && access_type_q inside {PutFullData, PutPartialData};

  wire modify_clear; // clear M flag when a cache line is evicted
  assign modify_clear = miss && modified_rdata && be_req_o.a_valid && be_rsp_i.a_ready;

  always_ff @(posedge clk_i) begin
    if (fe_modify_req || modify_clear) begin
      modified_mem[access_idx] <= ~modify_clear;
      modified_rdata <= ~modify_clear;
    end
    modified_rdata <= modified_mem[access_idx];
  end

  // Populate cache initially
  initial begin
    for (int i = 0; i < SETS; i++) begin
      tag_mem[i] <= '0;
      modified_mem[i] <= '0;
    end
  end

  always_comb begin
    fe_rsp_o = '{
      a_ready: ~stall,
      d_valid: hit,
      d_data: data_rdata,
      d_opcode: access_type_q == Get ? AccessAckData : AccessAck,
      d_anc: ancillary_q
    };

    // TODO: fix subsequent write -> read to same addr

    be_req_o = '{
      d_ready: '1,
      a_valid: miss,
      a_opcode: modified_rdata ? PutFullData : Get,
      a_mask: 32'hFFFFFFFF,
      a_address: {modified_rdata ? tag_rdata : access_tag_q, access_idx_q},
      a_data: data_rdata,
      a_anc: ancillary_q
    };
  end

endmodule
