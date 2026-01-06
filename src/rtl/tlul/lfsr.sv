// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2025 RVLab Contributors

/* 16-bit Linear Feedback Shift Register */

module lfsr #(
	SEED = 16'hCAFE
) (
	input logic clk_i,
	input logic rst_ni,

	input logic lfsr_en_i,

	output logic [15:0] lfsr_o
);

	logic [15:0] lfsr_d;
	logic [15:0] lfsr_q;

	always_comb begin
		lfsr_d[14:0] = lfsr_q[15:1];
		lfsr_d[15] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[3] ^ lfsr_q[12];
	end

	always_ff @(posedge clk_i or negedge rst_ni) begin
		if(~rst_ni) begin
			lfsr_q <= SEED;
		end else begin
			if (lfsr_en_i == 1'b1) begin
				lfsr_q <= lfsr_d;
			end
		end
	end

	assign lfsr_o = lfsr_q;

endmodule
