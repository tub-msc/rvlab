// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

/*
	LUTRAM-Based Register File for the RISC-V Lab CV32E40P.
	Does not support FPU or ZFINX.
*/

module cv32e40p_register_file #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32,
    parameter FPU        = 0,
    parameter ZFINX      = 0
) (
	// Clock and Reset
    input logic clk,
    input logic rst_n,

    input logic scan_cg_en_i,

    //Read port R1
    input  logic [ADDR_WIDTH-1:0] raddr_a_i,
    output logic [DATA_WIDTH-1:0] rdata_a_o,

    //Read port R2
    input  logic [ADDR_WIDTH-1:0] raddr_b_i,
    output logic [DATA_WIDTH-1:0] rdata_b_o,

    //Read port R3
    input  logic [ADDR_WIDTH-1:0] raddr_c_i,
    output logic [DATA_WIDTH-1:0] rdata_c_o,

    // Write port W1
    input logic [ADDR_WIDTH-1:0] waddr_a_i,
    input logic [DATA_WIDTH-1:0] wdata_a_i,
    input logic                  we_a_i,

    // Write port W2
    input logic [ADDR_WIDTH-1:0] waddr_b_i,
    input logic [DATA_WIDTH-1:0] wdata_b_i,
    input logic                  we_b_i
);

	/*
		Consists of two banks of LUTRAM registers (one for each write port).
		Selects most recent register value using an LVT (live value table) approach.

		The register at address zero explicitly reads 0.

		Write port W2 has priority over W1.

		Reset is unconnected; crt0 should initialize register values.
	*/

	localparam int NUM_REGS = 2**5;

	(* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] bank_a [NUM_REGS-1:0];
	(* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] bank_b [NUM_REGS-1:0];

	reg lvt_mem [NUM_REGS-1:0]; // Bit set = bank b, else bank a is more live

	// Read ports
	wire [DATA_WIDTH-1:0] read_a1, read_a2, read_a3; // a = bank, 1/2/3 = read port# respectively
	assign read_a1 = bank_a[raddr_a_i];
	assign read_a2 = bank_a[raddr_b_i];
	assign read_a3 = bank_a[raddr_c_i];

	wire [DATA_WIDTH-1:0] read_b1, read_b2, read_b3;
	assign read_b1 = bank_b[raddr_a_i];
	assign read_b2 = bank_b[raddr_b_i];
	assign read_b3 = bank_b[raddr_c_i];

	wire lvt_r1, lvt_r2, lvt_r3;
	assign lvt_r1 = lvt_mem[raddr_a_i];
	assign lvt_r2 = lvt_mem[raddr_b_i];
	assign lvt_r3 = lvt_mem[raddr_c_i];

	assign rdata_a_o = lvt_r1 ? read_b1 : read_a1;
	assign rdata_b_o = lvt_r2 ? read_b2 : read_a2;
	assign rdata_c_o = lvt_r3 ? read_b3 : read_a3;

	// Write ports
	always_ff @(posedge clk) begin
		if (we_a_i && waddr_a_i != '0) begin
			bank_a[waddr_a_i] <= wdata_a_i;
		end
	end

	always_ff @(posedge clk) begin
		if (we_b_i && waddr_b_i != '0) begin
			bank_b[waddr_b_i] <= wdata_b_i;
		end
	end

	// LVT updating
	generate
		for (genvar i = 1; i < NUM_REGS; i++) begin
			always_ff @(posedge clk or negedge rst_n) begin
				if(~rst_n) begin
					lvt_mem[i] <= '0;
				end else begin
					if (we_b_i && waddr_b_i == i) lvt_mem[i] <= '1;
					else if (we_a_i && waddr_a_i == i) lvt_mem[i] <= '0;
				end
			end
		end
		assign lvt_mem[0] = '0;
	endgenerate

	initial begin
		for (int i = 0; i < NUM_REGS; i++) begin
			bank_a[i] <= '0;
			bank_b[i] <= '0;
		end
	end

endmodule
