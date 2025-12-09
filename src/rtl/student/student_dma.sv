// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module student_dma (
  input logic clk_i,
  input logic rst_ni,

  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,

  input  tlul_pkg::tl_d2h_t tl_host_i,
  output tlul_pkg::tl_h2d_t tl_host_o
);
  import student_dma_reg_pkg::*;

  // Signals & types
  // ---------------
  
  typedef enum logic [1:0] {
    STATUS_IDLE         = 2'd0,
    STATUS_READING_DESC = 2'd1,
    STATUS_MEMSET_BUSY  = 2'd2,
    STATUS_MEMCPY_BUSY  = 2'd3
  } dma_status_t;

  typedef enum logic [0:0] {
    DESC_OP_MEMSET = 1'b0,
    DESC_OP_MEMCPY = 1'b1
  } dma_desc_op_t;

  student_dma_reg2hw_t reg2hw;
  student_dma_hw2reg_t hw2reg;

  dma_status_t         status;
  logic         [31:0] src_adr;
  logic         [31:0] dst_adr;
  logic         [31:0] length;
  logic         [31:0] length_recv;
  logic         [31:0] offset;
  logic                still_sending;
  logic                desc_addr_write;
  logic                desc_read_finished;
  dma_desc_op_t        operation;
  logic                desc_response_received;
  logic                write_done;
  logic                cmd_stop_strobe;
  logic       [31:0] now_dadr;
  
  // Register interface
  // ------------------

  student_dma_reg_top reg_top_i (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .reg2hw,
    .hw2reg,
    .devmode_i('1)
  );

  assign hw2reg.status.d  = status;
  assign hw2reg.length.d  = length;
  assign hw2reg.src_adr.d = src_adr;
  assign hw2reg.dst_adr.d = dst_adr;

  assign desc_addr_write  = reg2hw.now_dadr.qe;
  assign cmd_stop_strobe  = reg2hw.cmd.qe && reg2hw.cmd.q;

  // DMA Finite State Machine
  // ------------------------

  typedef enum logic [6:0] {
    IDLE,
    READ_DESC_SEND,
    READ_DESC_RECV,
    MEMSET_WRITING,   // ready to try to write next thing
    MEMSET_WAIT_RESP  // still trying to send next thing
  } state_dma_t;

  state_dma_t        current_state;
  state_dma_t        next_state;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // Next state:

  always_comb begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        if (desc_addr_write) begin
          next_state = READ_DESC_SEND;
        end
      end
      READ_DESC_SEND: begin
        if (tl_host_i.a_ready) begin
          next_state = READ_DESC_RECV;
        end
      end
      READ_DESC_RECV: begin
        if (desc_response_received) next_state = READ_DESC_SEND;
        if (desc_read_finished && (operation == DESC_OP_MEMSET)) next_state = MEMSET_WRITING;
        if (desc_read_finished && (operation == DESC_OP_MEMCPY))
          next_state = IDLE;  // <-- memcpy not implemented yet.
      end
      MEMSET_WRITING: begin
        if (length == 0 && tl_host_i.a_ready && tl_host_o.a_valid) next_state = MEMSET_WAIT_RESP;
      end
      MEMSET_WAIT_RESP: begin
        if (length_recv == 0) next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase

    if (cmd_stop_strobe) next_state = IDLE;
  end

  // Registered outputs:

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      tl_host_o <= '{
          a_opcode: tlul_pkg::PutFullData,
          a_mask: '1,
          a_source: '0,
          a_valid: '0,
          default: '0
      };
      desc_read_finished <= '0;
      still_sending <= 0;
      offset <= '0;
      operation <= DESC_OP_MEMSET;
      desc_response_received <= '0;
      write_done <= '0;
      status <= STATUS_IDLE;
      src_adr <= '0;
      dst_adr <= '0;
      length <= '0;
      length_recv <= '0;
      now_dadr <= '0;
    end else begin
      tl_host_o <= '{
          a_opcode: tlul_pkg::PutFullData,
          a_mask: '1,
          a_source: '0,
          a_valid: '0,
          a_size: 2,  // requested size is 2^a_size, thus 2 = 32 bit
          d_ready: '1,  // always ready
          default: '0
      };
      status <= STATUS_IDLE;

      desc_read_finished <= '0;
      desc_response_received <= '0;
      write_done <= '0;

      case (next_state)
        IDLE: begin
          offset <= '0;
        end
        READ_DESC_SEND: begin
          status <= STATUS_READING_DESC;
          if (desc_addr_write) begin
            now_dadr            <= reg2hw.now_dadr.q;
            tl_host_o.a_address <= reg2hw.now_dadr.q;
          end else begin
            tl_host_o.a_address <= now_dadr + offset;
          end

          tl_host_o.a_opcode <= tlul_pkg::Get;
          tl_host_o.a_valid  <= '1;
          tl_host_o.a_data   <= src_adr;
        end
        READ_DESC_RECV: begin
          status <= STATUS_READING_DESC;
          if (tl_host_i.d_valid) begin
            desc_response_received <= '1;
            if (offset == 0) begin
              operation <= dma_desc_op_t'(tl_host_i.d_data);
            end else if (offset == 4) begin
              length      <= tl_host_i.d_data - 4;
              length_recv <= tl_host_i.d_data;
            end else if (offset == 8) begin
              src_adr <= tl_host_i.d_data;
            end else if (offset == 12) begin
              dst_adr            <= tl_host_i.d_data;
              desc_read_finished <= '1;
              offset             <= '0;
            end
            offset <= offset + 4;
          end
        end
        MEMSET_WRITING: begin
          status <= STATUS_MEMSET_BUSY;
          tl_host_o.a_opcode <= tlul_pkg::PutFullData;
          tl_host_o.a_valid <= '1;
          tl_host_o.a_data <= src_adr;

          if (tl_host_i.a_ready && tl_host_o.a_valid) begin
            dst_adr <= dst_adr + 4;
            length  <= length - 4;
            tl_host_o.a_address <= dst_adr + 4;
          end
          else begin
            tl_host_o.a_address <= dst_adr;
          end

          if (tl_host_i.d_valid) begin
            length_recv <= length_recv - 4;
          end
        end
        MEMSET_WAIT_RESP: begin
          status <= STATUS_MEMSET_BUSY;
          if (tl_host_i.d_valid) begin
            length_recv <= length_recv - 4;
          end
        end
        default: begin

        end
      endcase
    end
  end

endmodule
