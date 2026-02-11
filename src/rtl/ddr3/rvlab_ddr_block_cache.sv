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

  typedef struct packed {
    logic modified;
  } set_flag_t;

  reg [       255:0] data_mem [SETS-1:0];
  reg [TAG_BITS-1:0]  tag_mem [SETS-1:0];
  set_flag_t         flag_mem [SETS-1:0];

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
  set_flag_t         flag_rdata;

  logic stall, stall_d;
  reg   stall_q;

  reg pending_be_req_q, pending_fetch_after_evict;

  logic  access, access_q;
  assign access = fe_req_i.a_valid && ~stall;

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
      pending_be_req_q <= '0;
      pending_fetch_after_evict <= '0;
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
      
      if (be_req_o.a_valid && be_rsp_i.a_ready) begin
        pending_be_req_q <= '1;
        if (be_req_o.a_opcode == PutFullData) begin
          pending_fetch_after_evict <= '1;
        end
      end
      if (be_rsp_i.d_valid && be_req_o.d_ready) begin
        pending_be_req_q <= '0;
        if (be_rsp_i.d_opcode == AccessAckData) begin
          pending_fetch_after_evict <= '0;
        end
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

  reg [255:0] data_rdata_raw;

  // Data memory (Port 2, Pseudo-Write-First)
  reg [255:0] rsp_data_q;
  reg         be_d_xchg_q; // Backend D-channel exchange buffered
  assign data_rdata = be_d_xchg_q ? rsp_data_q : data_rdata_raw;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      rsp_data_q <= '0;
      be_d_xchg_q <= '0;
    end else begin
      rsp_data_q <= be_rsp_i.d_data;
      be_d_xchg_q <= be_rsp_i.d_valid && be_req_o.d_ready;
    end
  end

  logic [IDX_BITS-1:0] data_be_port_adr;
  assign data_be_port_adr = (be_rsp_i.d_valid && be_req_o.d_ready) ? access_idx_q : access_idx;

  always_ff @(posedge clk_i) begin
    if (be_rsp_i.d_valid && be_req_o.d_ready) begin
      data_mem[data_be_port_adr] <= be_rsp_i.d_data;
    end
    data_rdata_raw <= data_mem[data_be_port_adr];
  end

  // Data memory (Port 1)
  always_ff @(posedge clk_i) begin
    if (hit && access_type_q inside {PutFullData, PutPartialData}) begin
      for (int i = 0; i < 32; i++) begin
        if (access_mask_q[i]) data_mem[access_idx][8*i+:8] <= access_data_q[8*i+:8];
      end
    end
  end

  // Tag memory
  always_ff @(posedge clk_i) begin
    if (be_req_o.a_valid && be_rsp_i.a_ready) begin
      tag_mem[access_idx_q] <= access_tag_q;
    end

    tag_rdata <= tag_mem[access_idx];
  end

  // Flag memory
  wire fe_modify_req;
  assign fe_modify_req = hit && access_type_q inside {PutFullData, PutPartialData};

  wire modify_clear; // clear M flag when a cache line is evicted
  assign modify_clear = miss && flag_rdata.modified && be_req_o.a_valid && be_rsp_i.a_ready;

  always_ff @(posedge clk_i) begin
    if (fe_modify_req || modify_clear) begin
      flag_mem[access_idx].modified <= modify_clear ? '0 : '1;
    end

    flag_rdata <= flag_mem[access_idx];
  end

  // Populate cache initially
  initial begin
    for (int i = 0; i < SETS; i++) begin
      tag_mem[i] <= '0;
      flag_mem[i].modified <= '0;
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

    // TODO: pipeline eviction and data fetch request
    // TODO: fix subsequent write -> read to same addr

    be_req_o = '{
      d_ready: '1,
      a_valid: (miss || pending_fetch_after_evict) && ~pending_be_req_q,
      a_opcode: flag_rdata.modified ? PutFullData : Get,
      a_mask: 32'hFFFFFFFF,
      a_address: {flag_rdata.modified ? tag_rdata : access_tag_q, access_idx_q},
      a_data: data_rdata,
      a_anc: ancillary_q
    };
  end

endmodule
