// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module rvlab_core (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic rst_dbg_ni,
  output logic ndmreset_o,

  input  logic jtag_tck_i,
  input  logic jtag_tdi_i,
  output logic jtag_tdo_o,
  input  logic jtag_tms_i,
  input  logic jtag_trst_ni,

  input  top_pkg::userio_board2fpga_t userio_i,
  output top_pkg::userio_fpga2board_t userio_o,

  output tlul_pkg::tl_h2d_t tl_ddr_o,
  input  tlul_pkg::tl_d2h_t tl_ddr_i,
  output tlul_pkg::tl_h2d_t tl_ddr_ctrl_o,
  input  tlul_pkg::tl_d2h_t tl_ddr_ctrl_i

);

  import tlul_pkg::*;

  logic irq_external;
  logic irq_timer;

  // xbar_main hosts:
  tl_h2d_t tl_cpui_h2d, tl_cpud_h2d, tl_dbgsba_h2d, tl_student_host_h2d;
  tl_d2h_t tl_cpui_d2h, tl_cpud_d2h, tl_dbgsba_d2h, tl_student_host_d2h;

  // xbar_main devices:
  tl_h2d_t tl_bram_main_h2d, tl_peri_h2d, tl_student_device_fast_h2d;
  tl_d2h_t tl_bram_main_d2h, tl_peri_d2h, tl_student_device_fast_d2h;

  // xbar_peri devices:
  tl_h2d_t tl_dbgmem_h2d, tl_timer_h2d, tl_regdemo_h2d, tl_student_device_peri_h2d;
  tl_d2h_t tl_dbgmem_d2h, tl_timer_d2h, tl_regdemo_d2h, tl_student_device_peri_d2h;

  // TL-UL interconnect
  // ------------------

  xbar_main xbar_main_i (
    .clk_main_i (clk_i),
    .rst_main_ni(rst_ni),
    .scanmode_i ('0),

    .tl_corei_i       (tl_cpui_h2d),
    .tl_corei_o       (tl_cpui_d2h),
    .tl_cored_i       (tl_cpud_h2d),
    .tl_cored_o       (tl_cpud_d2h),
    .tl_dbgsba_i      (tl_dbgsba_h2d),
    .tl_dbgsba_o      (tl_dbgsba_d2h),
    .tl_student_host_i(tl_student_host_h2d),
    .tl_student_host_o(tl_student_host_d2h),

    .tl_bram_main_o          (tl_bram_main_h2d),
    .tl_bram_main_i          (tl_bram_main_d2h),
    .tl_peri_o               (tl_peri_h2d),
    .tl_peri_i               (tl_peri_d2h),
    .tl_ddr_o,
    .tl_ddr_i,
    .tl_student_device_fast_o(tl_student_device_fast_h2d),
    .tl_student_device_fast_i(tl_student_device_fast_d2h)
  );

  xbar_peri xbar_peri_i (
    .clk_main_i (clk_i),
    .rst_main_ni(rst_ni),
    .scanmode_i ('0),

    .tl_main_i(tl_peri_h2d),
    .tl_main_o(tl_peri_d2h),

    .tl_dbgmem_o             (tl_dbgmem_h2d),
    .tl_dbgmem_i             (tl_dbgmem_d2h),
    .tl_timer_o              (tl_timer_h2d),
    .tl_timer_i              (tl_timer_d2h),
    .tl_ddr_ctrl_o,
    .tl_ddr_ctrl_i,
    .tl_regdemo_o            (tl_regdemo_h2d),
    .tl_regdemo_i            (tl_regdemo_d2h),
    .tl_student_device_peri_o(tl_student_device_peri_h2d),
    .tl_student_device_peri_i(tl_student_device_peri_d2h)
  );

  // Processor core
  // --------------

  logic debug_req;

  rvlab_cpu #(
    .PIPELINE_I_O('1),
    .PIPELINE_I_I('0),
    .PIPELINE_D_O('0),
    .PIPELINE_D_I('0),

    .RANDOMIZE_I ('0),
    .RANDOMIZE_D ('0)
  ) cpu_i (
    .clk_i,
    .rst_ni,
    .irq_external_i(irq_external),
    .irq_timer_i   (irq_timer),
    .tl_i_i        (tl_cpui_d2h),
    .tl_i_o        (tl_cpui_h2d),
    .tl_d_i        (tl_cpud_d2h),
    .tl_d_o        (tl_cpud_h2d),

    .debug_req_i(debug_req)
  );

  // Main block RAM
  // --------------

  rvlab_bram_main mem_i (
    .clk_i,
    .rst_ni,

    .tl_i(tl_bram_main_h2d),
    .tl_o(tl_bram_main_d2h)
  );

  // RISC-V debug
  // ------------

  rvlab_debug debug_i (
    .clk_i,
    .rst_ni         (rst_dbg_ni),
    .ndmreset_o,
    .jtag_tck_i,
    .jtag_tdi_i,
    .jtag_tdo_o,
    .jtag_tms_i,
    .jtag_trst_ni,
    .tl_dbgmem_d2h_o(tl_dbgmem_d2h),
    .tl_dbgmem_h2d_i(tl_dbgmem_h2d),
    .tl_dbgsba_d2h_i(tl_dbgsba_d2h),
    .tl_dbgsba_h2d_o(tl_dbgsba_h2d),
    .debug_req_o    (debug_req)
  );

  // Timer module
  // ------------

  rv_timer timer_i (
    .clk_i,
    .rst_ni,
    .tl_i                    (tl_timer_h2d),
    .tl_o                    (tl_timer_d2h),
    .intr_timer_expired_0_0_o(irq_timer)
  );


  // Register demo module
  // --------------------

  rvlab_regdemo regdemo_i (
    .clk_i,
    .rst_ni,
    .tl_i(tl_regdemo_h2d),
    .tl_o(tl_regdemo_d2h)
  );

  // Student module
  // --------------

  student student_i (
    .clk_i,
    .rst_ni,
    .userio_i,
    .userio_o,
    .irq_o           (irq_external),
    .tl_device_peri_i(tl_student_device_peri_h2d),
    .tl_device_peri_o(tl_student_device_peri_d2h),
    .tl_device_fast_i(tl_student_device_fast_h2d),
    .tl_device_fast_o(tl_student_device_fast_d2h),
    .tl_host_i       (tl_student_host_d2h),
    .tl_host_o       (tl_student_host_h2d)
  );

endmodule
