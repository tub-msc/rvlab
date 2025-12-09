// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module student_tlul_mux #(
    parameter int NUM = 2
) (
    input logic clk_i,
    input logic rst_ni,

    output tlul_pkg::tl_d2h_t tl_host_o,
    input  tlul_pkg::tl_h2d_t tl_host_i,

    input  tlul_pkg::tl_d2h_t  tl_device_o [NUM-1:0],
    output tlul_pkg::tl_h2d_t  tl_device_i [NUM-1:0]
);

  // Implement TL-UL multiplexer here.

endmodule
