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


  /* Memory */

  localparam int SETS = 2**IDX_BITS;

  (* ram_style = "block" *)       reg [       255:0]  data_mem [SETS-1:0];
                                  reg [TAG_BITS-1:0]   tag_mem [SETS-1:0];
  (* ram_style = "distributed" *) logic              dirty_mem [SETS-1:0];

  /* Address decomposition */

  logic [  DDR_AW-1:0] access_addr;
  logic [IDX_BITS-1:0] access_idx, access_idx_q, access_idx_q_q;
  logic [TAG_BITS-1:0] access_tag, access_tag_q;
  assign access_addr = fe_req_i.a_address;
  assign access_idx  = fe_req_i.a_address[IDX_BITS-1:0];
  assign access_tag  = fe_req_i.a_address[IDX_BITS+:TAG_BITS];

  reg [DDR_ANCW-1:0] ancillary_q;

  tl_a_op_e     access_type_q;
  logic [ 31:0] access_mask_q;
  logic [255:0] access_data_q;

  logic stall, stall_d;
  reg   stall_q;

  logic  access, access_q;
  assign access = fe_req_i.a_valid;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      access_q <= '0;
      access_idx_q <= '0;
      access_idx_q_q <= '0;
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

      access_idx_q_q <= access_idx_q;
      stall_q <= stall_d;
    end
  end

  wire   hit, miss;

  // Begin stalling once we miss
  // End stalling once we receive the new (fetched) block's data
  assign stall = stall_q || miss;
  assign stall_d = stall && !(be_rsp_i.d_valid && be_req_o.d_ready && be_rsp_i.d_opcode == AccessAckData);

  /* Memory access / inference templates */

  logic [       255:0] data_rdata_raw; // Output of Data memory
  logic [       255:0]     data_rdata; // data_rdata_raw but updated if read address was written to (write-first)
  logic [TAG_BITS-1:0]      tag_rdata;
  logic                   dirty_rdata;

  assign hit  = tag_rdata == access_tag_q && access_q && ~stall;
  assign miss = tag_rdata != access_tag_q && access_q;

  /* Data memory */

  wire use_be_port; // write from backend port (Get response)
  assign use_be_port = be_rsp_i.d_valid && be_req_o.d_ready; // TileLink beat exchange

  logic data_wen, data_wen_q;
  assign data_wen = use_be_port || (hit && access_type_q inside {PutFullData, PutPartialData});

  logic [31:0] data_wmask, data_wmask_q;
  assign data_wmask = use_be_port ? '1 : access_mask_q;

  logic [255:0] data_wdata, data_wdata_q;
  assign data_wdata = use_be_port ? be_rsp_i.d_data : access_data_q;

  always_ff @(posedge clk_i) begin
    for (int i = 0; i < 32; i++) begin
      if (data_wmask[i] & data_wen) begin
        data_mem[access_idx_q][8*i+:8] <= data_wdata[8*i+:8];
      end
    end
    // We want to read from the currently addressed index in most cases,
    // so that we can issue a response in the next cycle.
    // If there is an inbound response from the backend (use_be_port = 1),
    // then we potentially want to resume normal operation after this
    // cycle, i.e. complete the request that caused the miss. This however
    // requires reading from the stored index (request that caused the stall)
    // instead of the one from the current address.
    data_rdata_raw <= data_mem[use_be_port ? access_idx_q : access_idx];
  end

  always_ff @(posedge clk_i) begin
    data_wmask_q <= data_wmask;
    data_wdata_q <= data_wdata;
    data_wen_q   <= data_wen;
  end

  // Adjust data_rdata to reflect writes that happened last cycle.
  // (There is no write-first byte-wide write-enable RAM inference template
  // as of writing)
  generate
    for (genvar i = 0; i < 32; i++) begin : gen_bwwe
      // the access_idx checking is to ensure the address we wrote to is the address we're trying
      // to read from
      assign data_rdata[8*i+:8] = data_wen_q && data_wmask_q[i] && access_idx_q == access_idx_q_q
                                ? data_wdata_q[8*i+:8]
                                : data_rdata_raw[8*i+:8];
    end : gen_bwwe
  endgenerate

  // Tag memory
  always_ff @(posedge clk_i) begin
    if (be_req_o.a_valid && be_rsp_i.a_ready && be_req_o.a_opcode == Get) begin
      tag_mem[access_idx_q] <= access_tag_q;
      tag_rdata <= access_tag_q;
    end else begin
      tag_rdata <= tag_mem[stall ? access_idx_q : access_idx];
    end
  end

  // Flag memory
  wire fe_modify_req;
  assign fe_modify_req = hit && access_type_q inside {PutFullData, PutPartialData};

  wire modify_clear; // clear M flag when a cache line is evicted
  assign modify_clear = miss && dirty_rdata && be_req_o.a_valid && be_rsp_i.a_ready;

  always_ff @(posedge clk_i) begin
    if (fe_modify_req || modify_clear) begin
      dirty_mem[access_idx_q] <= ~modify_clear;
      dirty_rdata <= ~modify_clear;
    end else dirty_rdata <= dirty_mem[access_idx];
  end

  // Populate cache initially
  initial begin
    for (int i = 0; i < SETS; i++) begin
      tag_mem[i] = '0;
      dirty_mem[i] = '0;
      data_mem[i] = '0;
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

    be_req_o = '{
      d_ready: '1,
      a_valid: miss,
      a_opcode: dirty_rdata ? PutFullData : Get,
      a_mask: 32'hFFFFFFFF,
      a_address: {dirty_rdata ? tag_rdata : access_tag_q, access_idx_q},
      a_data: data_rdata_raw,
      a_anc: ancillary_q
    };
  end

endmodule
