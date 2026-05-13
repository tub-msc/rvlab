// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors
//
// prim_rstsyn: 2-FF reset synchronizer with asynchronous reset assertion and
// synchronous reset deassertion.

module prim_rstsyn(
    input logic clk_i,
    input logic rst_ni,
    output logic rst_no
);

    logic [1:0] rst_n_q;
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            rst_n_q <= 2'b00;
        end
        else begin
            rst_n_q <= {rst_n_q[0], 1'b1};
        end
    end

    assign rst_no = rst_n_q[1];
endmodule
