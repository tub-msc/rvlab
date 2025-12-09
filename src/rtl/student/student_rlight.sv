// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module student_rlight (
  input logic clk_i,
  input logic rst_ni,

  output tlul_pkg::tl_d2h_t tl_o,  //slave output (this module's response)
  input  tlul_pkg::tl_h2d_t tl_i,  //master input (incoming request)

  output logic [7:0] led_o
);


  logic [3:0] addr;
  logic we;
  logic re;
  logic [31:0] wdata;
  logic [31:0] rdata;

  tlul_adapter_reg #(
    .RegAw(4),
    .RegDw(32)
  ) adapter_reg_i (
    .clk_i,
    .rst_ni,

    .tl_i,
    .tl_o,

    .we_o   (we),
    .re_o   (re),
    .addr_o (addr),
    .wdata_o(wdata),
    .be_o   (),
    .rdata_i(rdata),
    .error_i('0)
  );

  localparam logic [3:0] ADDR_REGA = 4'h0;
  localparam logic [3:0] ADDR_REGB = 4'h4;

  logic [31:0] regA;
  logic [ 7:0] regB;

  // Bus reads
  // ---------

  always_comb begin
    rdata = '0;  // !!!
    if (re) begin
      case (addr)
        ADDR_REGA:  rdata[31:0] = regA;
        ADDR_REGB:  rdata[ 7:0] = regB;
        default:    rdata       = '0;
      endcase
    end
  end


  // Bus writes
  // ----------

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      regA   <= 32'h0000AFFE; // reset value
      regB   <= '0;           // reset value
    end else begin
      if (we) begin
        case (addr)
          ADDR_REGA: regA <= wdata[31:0];
          ADDR_REGB: regB <= wdata[ 7:0];
          default: ;
        endcase
      end // if(we)
    end // if (~rst_ni) else
  end 


  // Demo FSM. Replace with your rlight
  // ----------------------------------
  enum logic[1:0] {idle, swap, count} state;
  logic [7:0] led;
  logic [1:0] cnt;
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      state   <= idle;
      led     <= 8'b10101010;
      cnt     <= '0;
    end else begin
        case (state)
          idle: begin
            if (regB[0] == 1'b1) begin
              led   <= regA[15:8];
              state <= swap;
            end
          end
          swap: begin
            led[7:4] <= led[3:0];
            led[3:0] <= led[7:4];
            cnt      <= 2'd2;
            state    <= count;
          end
          count: begin
            if (cnt != 0) begin
              cnt <= cnt - 1;
            end
            else begin 
              state <= idle;
            end
          end
          default: begin
            state <= idle;
          end
        endcase;
    end // if (~rst_ni) else
  end 
 
  assign led_o = led; // output assignment

endmodule
