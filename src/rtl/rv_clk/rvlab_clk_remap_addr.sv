// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2025 RVLab Contributors

/* Combinational address remapper for dynamic clocking */
/* Maps virtual address space of RVLab dynamic clocking module to */
/* MMCM DRP module address space */

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
│   │  TL-UL <-> DRP   ├──┤   │
│   └───┬──────────┬───┘  │   │
│       │  TL-UL   │      │   │
│   ┌───┴──────────┴───┐  │   │
│   │   CLK Reconfig   ├──┘   │
│   │ ┌──────────────┐ │      │
│   │ │  ADDR REMAP  │ <------ this module
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

module rvlab_clk_remap_addr (
  /* Combinational, so no clock / resets */
  input  logic [31:0] vaddr_i,
  input  logic        clkreg_mux_i,
  output logic [31:0] drp_addr_o
);

  always_comb begin
    /* Address mappings according to XAPP888: */
    /* https://docs.amd.com/v/u/en-US/xapp888_7Series_DynamicRecon */
    unique0 case (vaddr_i[11:0])
      // CLK0 / SYSCLK
      12'h100 : drp_addr_o = clkreg_mux_i ? 32'h00000009 : 32'h00000008;
      // CLK1
      12'h110 : drp_addr_o = clkreg_mux_i ? 32'h0000000B : 32'h0000000A;
      // CLK2
      12'h120 : drp_addr_o = clkreg_mux_i ? 32'h0000000D : 32'h0000000C;
      // CLK3
      12'h130 : drp_addr_o = clkreg_mux_i ? 32'h0000000F : 32'h0000000E;
      // CLK4
      12'h140 : drp_addr_o = clkreg_mux_i ? 32'h00000011 : 32'h00000010;
      // CLK5
      12'h150 : drp_addr_o = clkreg_mux_i ? 32'h00000007 : 32'h00000006;
      // CLK6
      12'h160 : drp_addr_o = clkreg_mux_i ? 32'h00000013 : 32'h00000012;
      default : drp_addr_o = '0;
    endcase
  end

endmodule
