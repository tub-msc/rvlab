// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

module rvlab_ddr_blkmgr #(
  parameter  int REQBUF_SIZE = 16, // >= 2
  localparam int REQBUF_AW = $clog2(REQBUF_SIZE),
  localparam int AUX_BITS = REQBUF_AW + rvlab_ddr_pkg::DDR_ANCW
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  rvlab_ddr_pkg::ddr3_h2d_t req_i,
  output rvlab_ddr_pkg::ddr3_d2h_t rsp_o,

  output logic                wb_stb_o,
  output logic                wb_we_o,
  output logic [        24:0] wb_blk_addr_o,
  output logic [       127:0] wb_wdata_o,
  output logic [        15:0] wb_wmask_o,
  output logic [AUX_BITS-1:0] wb_aux_o,
  input  logic                wb_stall_i,
  input  logic                wb_ack_i,
  input  logic [       127:0] wb_rdata_i,
  input  logic [AUX_BITS-1:0] wb_aux_i
);

  import rvlab_ddr_pkg::*;
  import tlul_pkg::*;

  /*
   * DDR3 Block Access Manager (Outdated description)
   *
   * Provides access to the DDR3 Wishbone interface in 128-bit blocks.
   * Implemented as FSM with states for reading/writing blocks.
   * Highly combinational, i.e. can answer same-cycle requests.
   * The FSM comprises several states:
   * - 'Primed': Several things may happen, depending on req.a_opcode:
   *     1. Width of Tx = 64b (write with only one write mask bit set):
   *        Transaction is immediately placed on WB bus, and response
   *        is immediately directed back to rsp_o.
   *     2. 128b-wide read:
   *        Lower 64 bits are read into a holding register, state
   *        changes to 'ReadHigh', Tx is accepted but not ACK'd yet.
   *     3. 128b-wide write:
   *        Lower 64 bits are written to RAM, state changes to
   *        'WriteHigh', Tx is accepted but not ACK'd yet.
   * - 'ReadHigh': Upper 64 bits of buffered block (address) are read,
   *        concatenated with the holding register, returned to Master.
   *        If master declines request, Value is registered and subse-
   *        quently returned. No new requests are accepted in this
   *        time.
   * - 'WriteHigh': Upper 64 bits of input block (buffered) are written
   *        to the upper 64 bits of addressed block (in buffer). ACK
   *        occurs at the earliest in the cycle of the DDR3's ACK.
   * - 'AckWrite': Present AccessAck beat until req.d_ready goes high.
   *        Don't accept any new requests in this time.
   * - 'AckRead': Present AccessAckData beat with data from blkdata_q
   *        until req.d_ready goes high. Don't accept any new requests
   *        in this time.
   *
   *
   * Block Manager uses a request buffer to keep track of outstanding
   * requests. When it is full, no new requests are accepted.
  */

  /*
   * Flow for Block Read
   *
   * 1. Block request a_valid goes high
   *    (wait for request buffer to not be full)
   * 2. wb_stb is asserted for lower half
   * 3. when wb_stall is low, a_ready is asserted, state switch to ReadHigh
   * 4. ReadHigh: wb_stb is asserted for higher half of block
   * 5. when wb_stall is low, switch back into primed mode
   * 6. Update next entry in request buffer to pending mode
  */

  typedef enum logic [1:0] {
    Invalid,
    PendingLow,
    PendingHigh,
    Valid
  } ddr3_req_state_e;

  typedef enum logic {
    Read,
    Write
  } ddr3_req_type_e;

  // Request Buffer state + data are implemented separately
  // To allow global state reset (invalidation) and
  // Data storage via LUTRAM (256 data bits per entry)

  ddr3_req_state_e   reqbuf_state_mem [REQBUF_SIZE-1:0];
  ddr3_req_type_e    reqbuf_type_mem  [REQBUF_SIZE-1:0];
  reg [       255:0] reqbuf_data_mem  [REQBUF_SIZE-1:0];
  reg [DDR_ANCW-1:0] reqbuf_anc_mem   [REQBUF_SIZE-1:0];

  reg [REQBUF_AW-1:0] reqbuf_wptr, reqbuf_wptr_q;
  reg [REQBUF_AW-1:0] reqbuf_rptr;

  reg [DDR_ANCW-1:0] ancillary_data_q;

  wire   reqbuf_full;
  assign reqbuf_full = reqbuf_state_mem[reqbuf_wptr] != Invalid;

  typedef enum logic [1:0] {
    Primed,
    ReadHigh,
    WriteHigh
  } ddr3_blkmgr_state_e;

  reg [DDR_AW-1:0] blkaddr_q;
  reg [     255:0] blkdata_q; // buffer for a full block's data
  reg [      31:0] wmask_q;

  ddr3_blkmgr_state_e state_d, state_q;

  always_comb begin
    rsp_o = '{d_opcode: AccessAck, default: '0};
    state_d = state_q;
    
    wb_stb_o = '0;
    wb_we_o = '0;
    wb_wmask_o = '0;
    wb_blk_addr_o = {req_i.a_address, 1'b0};
    wb_wdata_o = '0;
    wb_aux_o = {reqbuf_wptr, req_i.a_anc};

    case (state_q)
      Primed: begin
        if (req_i.a_valid && !reqbuf_full) begin
          case (req_i.a_opcode)
            PutPartialData: begin
              /* Fastest case: 64-bit write */
              wb_stb_o = '1;
              wb_we_o = '1;
              if (req_i.a_mask[16]) begin
                // High dword write
                wb_wmask_o = req_i.a_mask[31:16];
                wb_wdata_o = req_i.a_data[255:128];
                wb_blk_addr_o[0] = '1;
              end else begin
                // Low dword write
                wb_wmask_o = req_i.a_mask[15:0];
                wb_wdata_o = req_i.a_data[127:0];
              end
              if (!wb_stall_i) begin
                rsp_o.a_ready = '1;
              end
            end
            PutFullData: begin
              /* 128-bit write */
              wb_stb_o = '1;
              wb_we_o = '1;
              wb_wmask_o = req_i.a_mask[15:0];
              wb_wdata_o = req_i.a_data[127:0];
              if (!wb_stall_i) begin
                state_d = WriteHigh;
                rsp_o.a_ready = '1;
              end
            end
            Get: begin
              /* 128-bit read */
              wb_stb_o = '1;
              if (!wb_stall_i) begin
                state_d = ReadHigh;
                rsp_o.a_ready = '1;
              end
            end
            default: ;
          endcase
        end
      end
      WriteHigh: begin
        wb_stb_o = '1;
        wb_we_o = '1;
        wb_wmask_o = wmask_q[31:16];
        wb_wdata_o = blkdata_q[255:128];
        wb_blk_addr_o = {blkaddr_q, 1'b1};
        wb_aux_o = {reqbuf_wptr_q, ancillary_data_q};
        if (!wb_stall_i) state_d = Primed;
      end
      ReadHigh: begin
        wb_stb_o = '1;
        wb_blk_addr_o = {blkaddr_q, 1'b1};
        wb_aux_o = {reqbuf_wptr_q, ancillary_data_q};
        if (!wb_stall_i) state_d = Primed;
      end
      default: ;
    endcase

    if (reqbuf_state_mem[reqbuf_rptr] == Valid) begin
      if (reqbuf_type_mem[reqbuf_rptr] == Read) begin
        rsp_o.d_opcode = AccessAckData;
      end else begin
        rsp_o.d_opcode = AccessAck;
      end
      rsp_o.d_valid = '1;
      rsp_o.d_anc = reqbuf_anc_mem[reqbuf_rptr];
      rsp_o.d_data = reqbuf_data_mem[reqbuf_rptr];
    end
  end

  wire [REQBUF_AW-1:0] ack_reqbuf_adr;
  assign ack_reqbuf_adr = wb_aux_i[AUX_BITS-1-:REQBUF_AW];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      state_q <= Primed;
      blkdata_q <= '0;
      blkaddr_q <= '0;
      wmask_q <= '0;
      for (int i = 0; i < REQBUF_SIZE; i++) begin
        reqbuf_state_mem[i] <= Invalid;
      end
      reqbuf_wptr <= '0;
      reqbuf_wptr_q <= '0;
      reqbuf_rptr <= '0;
      ancillary_data_q <= '0;
    end else begin
      state_q <= state_d;

      if (req_i.a_valid && rsp_o.a_ready) begin
        blkdata_q        <= req_i.a_data;
        blkaddr_q        <= req_i.a_address;
        wmask_q          <= req_i.a_mask;
        ancillary_data_q <= req_i.a_anc;

        reqbuf_wptr   <= reqbuf_wptr + 1;
        reqbuf_wptr_q <= reqbuf_wptr;

        reqbuf_anc_mem[reqbuf_wptr] <= req_i.a_anc;

        if (req_i.a_opcode == PutPartialData) begin
          // Iff opcode is PutPartialData, only one
          // response must arrive for validation
          reqbuf_state_mem[reqbuf_wptr] <= PendingHigh;
        end else begin
          reqbuf_state_mem[reqbuf_wptr] <= PendingLow;
        end

        if (req_i.a_opcode == Get) begin
          reqbuf_type_mem[reqbuf_wptr] <= Read;
        end else begin
          reqbuf_type_mem[reqbuf_wptr] <= Write;
        end
      end

      if (wb_ack_i) begin
        case (reqbuf_state_mem[ack_reqbuf_adr]) 
          Invalid     : /* ERROR */;
          PendingLow  : reqbuf_state_mem[ack_reqbuf_adr] <= PendingHigh;
          PendingHigh : reqbuf_state_mem[ack_reqbuf_adr] <= Valid;
          Valid       : /* ERROR */;
          default     : /* ERROR */;
        endcase
      end

      if (rsp_o.d_valid && req_i.d_ready) begin
        reqbuf_state_mem[reqbuf_rptr] <= Invalid;
        reqbuf_rptr <= reqbuf_rptr + 1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (wb_ack_i) begin
      case (reqbuf_state_mem[ack_reqbuf_adr])
        Invalid     : /* ERROR */;
        PendingLow  : reqbuf_data_mem[ack_reqbuf_adr][127:0] <= wb_rdata_i;
        PendingHigh : reqbuf_data_mem[ack_reqbuf_adr][255:128] <= wb_rdata_i;
        Valid       : /* ERROR */;
        default     : /* ERROR */;
      endcase
    end
  end

endmodule
