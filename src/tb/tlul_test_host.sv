// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

module tlul_test_host (
    input  logic              clk_i,
    output logic              rst_no,
    input  tlul_pkg::tl_d2h_t tl_i,
    output tlul_pkg::tl_h2d_t tl_o
);

  localparam tlul_pkg::tl_h2d_t TlIdle = '{a_opcode: tlul_pkg::PutFullData, default: '0};

  initial begin
    tl_o   <= TlIdle;
    rst_no <= '0;
  end

  task reset();
    rst_no <= '0;
    @(posedge clk_i);
    @(posedge clk_i);
    rst_no <= '1;
    @(posedge clk_i);
    @(posedge clk_i);
  endtask

  task wait_cycles(input integer n_cycles);
    integer i;
    for (i = 0; i < n_cycles; i++) @(posedge clk_i);
  endtask

  task do_transaction();
    integer i;
    // Send request on A channel:
    @(negedge clk_i);
    tl_o.a_valid = 1'b1;
    tl_o.d_ready = 1'b1;
    i = '0;
    while (1) begin
      @(posedge clk_i);
      if (tl_i.a_ready) begin
        break;
      end
      if (i++ == 10) begin
        $display("Warning: device takes > 10 cycles to respond.");
      end
    end
    @(negedge clk_i);
    tl_o.a_valid = 1'b0;
    //tl_o <= TlIdle;  // a_valid <= '0;
    while (!tl_i.d_valid) begin
      @(posedge clk_i);
      $display("Waiting for response to be d_valid = 1");
    end
    if (tl_i.d_error) begin
      $display("Warning: response d_error was %p.", tl_i.d_error);
    end
    if (tl_i.d_size != tl_o.a_size) begin
      $display("Warning: response d_size was %p, expected %p.", tl_i.d_size, tl_o.a_size);
    end
    if (tl_i.d_sink != tl_o.a_source) begin
      $display("Warning: response d_sink was %p, expected %p.", tl_i.d_sink, tl_o.a_source);
    end
  endtask

  task put_word(input logic [31:0] addr, input logic [31:0] wdata);
    tl_o.a_address = addr;
    tl_o.a_opcode  = tlul_pkg::PutFullData;
    tl_o.a_size    = 2;  // 2^2 = 4 byte access
    tl_o.a_data    = wdata;
    tl_o.a_mask    = 4'b1111;
    do_transaction();
    if (tl_i.d_opcode != tlul_pkg::AccessAck) begin
      $display("Warning: put response d_opcode was %p.", tl_i.d_opcode);
    end
    @(posedge clk_i);
    $display("Debug: put word addr=0x%08x, wdata=0x%08x", addr, wdata);
  endtask

  task get_word(input logic [31:0] addr, output logic [31:0] rdata);
    tl_o.a_address = addr;
    tl_o.a_opcode  = tlul_pkg::Get;
    tl_o.a_size    = 2;  // 2^2 = 4 byte access
    tl_o.a_mask    = 4'b1111;
    do_transaction();
    rdata = tl_i.d_data;
    if (tl_i.d_opcode != tlul_pkg::AccessAckData) begin
      $display("Warning: get response d_opcode was %p.", tl_i.d_opcode);
    end
    @(posedge clk_i);
    $display("Debug: get word addr=0x%08x, rdata=0x%08x", addr, rdata);
  endtask

endmodule
