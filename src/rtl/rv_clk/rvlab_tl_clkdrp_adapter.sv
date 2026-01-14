/* Copyright David Schröder 2025. */
/* TL-UL <-> MMCM Dynamic Reconfiguration Port (DRP) adapter */
/* Processes one request at a time */


/* Variable clocking Configuration: */
/*
                      clk_100mhz
                          │
┌─────rvlab_clkmgr.sv─────────┐
│                         │   │
│   ┌──────────────────┐  │   │
│   │       MMCM       ├──┤   │
│   │       drp        │  │   │
│   └────────┬─────────┘  │   │
│   ┌────────┴─────────┐  │   │
│   │  TL-UL <-> DRP   ├──┤ <------ this module
│   └───┬──────────┬───┘  │   │
│       │  TL-UL   │      │   │
│   ┌───┴──────────┴───┐  │   │
│   │   CLK Reconfig   ├──┘   │
│   │ ┌──────────────┐ │      │
│   │ │  ADDR REMAP  │ │      │
│   │ └──────────────┘ │      │
│   │ ┌──────────────┐ │      │
│   │ │  SAFETY NET  │ │      │
│   │ └──────────────┘ ├──┐   │
│   └───┬──────────┬───┘  │   │
│       │  TL-UL   │      │   │
└─────────────────────────────┘
    ┌───┴──────────┴───┐  │
    │       SOC        ├──┤
    │                  │  │
                          │
                       sys_clk (technically an MMCM output)
*/

module rvlab_tl_clkdrp_adapter (
	input logic clk_i,
	input logic rst_ni, // Should come from jtag_srst or some reset that isn't triggered by MMCM Unlock

	input  tlul_pkg::tl_h2d_t tl_reconfig_i,
	output tlul_pkg::tl_d2h_t tl_reconfig_o,

	input  logic        drp_rdy_i,
	input  logic [15:0] drp_do_i,
	output logic        drp_en_o,
	output logic        drp_we_o,
	output logic [ 6:0] drp_adr_o,
	output logic [15:0] drp_di_o,

	output logic rst_mmcm_o
);
	import tlul_pkg::*;

	typedef enum logic [1:0] {
		Collect = 2'h0,
		DRPWait = 2'h1,
		Acknowledge = 2'h2
	} tl_drp_state_e;

	tl_drp_state_e state_q;
	tl_drp_state_e state_d;

	logic        xfer_we;   // is current request a write request
	logic [15:0] xfer_data; // transaction data: either read or write data
	                        // which one can be derived from xfer_we

	always_comb begin
		/* TL-UL output */
		tl_reconfig_o = '{d_opcode: AccessAck, d_size: 2'h2, default: '0};
		case (state_q)
			Collect: begin
				tl_reconfig_o.a_ready = '1;
			end
			Acknowledge: begin
				tl_reconfig_o.d_opcode = xfer_we ? AccessAck : AccessAckData;
				tl_reconfig_o.d_valid = '1;
				tl_reconfig_o.d_data = xfer_we ? '0 : xfer_data;
			end
			default : /* default */;
		endcase
	end

	always_comb begin
		/* State */
		state_d = state_q;
		case (state_q)
			Collect: begin
				if (tl_reconfig_i.a_valid) state_d = DRPWait;
			end
			DRPWait: begin
				if (drp_rdy_i) state_d = Acknowledge;
			end
			Acknowledge: begin
				if (tl_reconfig_o.d_valid && tl_reconfig_i.d_ready) state_d = Collect;
			end
		endcase
	end

	always_ff @(posedge clk_i or negedge rst_ni) begin
		if(~rst_ni) begin
			state_q    <= Collect;
			drp_en_o   <= '0;
			drp_we_o   <= '0;
			drp_adr_o  <= '0;
			drp_di_o   <= '0;
			xfer_we    <= '0;
			xfer_data  <= '0;
			rst_mmcm_o <= '0;
		end else begin
			state_q  <= state_d;
			drp_en_o <= '0;
			drp_we_o <= '0;
			case (state_q)
				Collect: begin
					if (tl_reconfig_i.a_valid) begin

						xfer_we <= '0;
						drp_we_o <= '0;
						if (tl_reconfig_i.a_opcode != Get) begin
							xfer_we <= '1;
							drp_we_o <= '1;
							rst_mmcm_o <= '1;
						end

						drp_en_o <= '1;
						drp_adr_o <= tl_reconfig_i.a_address;
						drp_di_o <= tl_reconfig_i.a_data;
					end
				end
				DRPWait: begin
					if (drp_rdy_i) begin
						if (!xfer_we) xfer_data <= drp_do_i;
						rst_mmcm_o <= '0;
					end
				end
				default : /* default */;
			endcase
		end
	end

endmodule
