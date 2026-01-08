// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module student_rlight_tb;
  logic clk;
  logic rst_n;
  logic [7:0] led;
  tlul_pkg::tl_d2h_t tl_d2h;
  tlul_pkg::tl_h2d_t tl_h2d;

  // 50 MHz
  always begin
    clk = '1;
    #10000;
    clk = '0;
    #10000;
  end

  student_rlight DUT (
    .clk_i (clk),
    .rst_ni(rst_n),
    .tl_i  (tl_h2d),
    .tl_o  (tl_d2h),
    .led_o (led)
  );

  tlul_test_host bus(
    .clk_i(clk),
    .rst_no(rst_n),
    .tl_i(tl_d2h),
    .tl_o(tl_h2d)
  );
    
  initial begin
    logic [31:0] rdata;
`ifdef VERILATOR
    $dumpfile("trace.vcd");
    $dumpvars(0, student_rlight_tb);
`endif
    bus.reset();

    // write and read pattern register 2x:

    bus.get_word(32'h00000000, rdata);
    $display("read RegA: 0x%08x", rdata);

    bus.put_word(32'h00000000, 32'h12345678);
    bus.get_word(32'h00000000, rdata);
    $display("read RegA: 0x%08x", rdata);
    
    bus.wait_cycles(2);

    bus.put_word(32'h00000004, 32'hFFFFFF01);
    bus.get_word(32'h00000004, rdata);
    $display("read RegB: 0x%08x", rdata);
    
    bus.wait_cycles(10);
    
    // ...

    $finish;
  end


endmodule
