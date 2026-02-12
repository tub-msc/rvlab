// SPDX-FileCopyrightText: 2026 RVLab Contributors
// SPDX-License-Identifier: SHL-2.1

package rvlab_ddr_pkg;

  /* Custom bus protocol structs */
  /*  Loosely based on TileLink  */

  /*
   * Main changes from TileLink:
   * - Guaranteed in-order responses, so no X_source fields
   * - Removed X_size fields and use fixed address + data widths
   * - Convention: PutFullData for 256-bit writes,
   *               PutPartialData for smaller writes
   * - Beats should be presented until accepted (not modified
   *   before a_ready is asserted)
   * - Added ancillary data fields a_anc and d_anc:
   *   d_anc must contain the same value passed to a_anc in the request.
   *   This mirrors the behavior of the X_source fields, yet bears a
   *   different semantic meaning.
   *   The width of the ancillary fields suffices for:
   *   - 3 bit word selection (1/8 32-bit words is selected)
   *   - Full TL-UL source field width, for TL-UL adapters
  */

  localparam int DDR_AW = 24; // 29 bit = byte-addressable 512MiB, block = 2^5 bytes
  localparam int DDR_ANCW = 3 + top_pkg::TL_AIW; // Width of ancillary data (bits)

  typedef struct packed {
    logic                a_valid;
    tlul_pkg::tl_a_op_e  a_opcode;
    logic [  DDR_AW-1:0] a_address; // block address
    logic [        31:0] a_mask;    // 1 bit per byte
    logic [       255:0] a_data;
    logic [DDR_ANCW-1:0] a_anc;     // Ancillary Data

    logic               d_ready;
  } ddr3_h2d_t;

  typedef struct packed {
    logic                d_valid;
    tlul_pkg::tl_d_op_e  d_opcode;
    logic [       255:0] d_data;
    logic [DDR_ANCW-1:0] d_anc; // Ancillary Data

    logic                a_ready;
  } ddr3_d2h_t;

endpackage
