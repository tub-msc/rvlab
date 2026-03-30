// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

module rvlab_ddr_prefetch #(
    parameter int SIZE = 4 // >= 2
) (
    input  logic clk_i,
    input  logic rst_ni,

    /* Front-End */
    input  rvlab_ddr_pkg::ddr3_h2d_t fe_req_i,
    output rvlab_ddr_pkg::ddr3_d2h_t fe_rsp_o,

    /* Back-End */
    output rvlab_ddr_pkg::ddr3_h2d_t be_req_o,
    input  rvlab_ddr_pkg::ddr3_d2h_t be_rsp_i
);

    import rvlab_ddr_pkg::*;
    import tlul_pkg::*;

    /*
     * How it works - RVLab DDR3 Block Prefetch Unit
     *
     * The block prefetch unit operates on a table of entries corresponding to DDR requests.
     * Each entry has a status, an address, and several data fields.
     *     When a new GET request arrives from the front-end side, the address is compared to
     * the addresses of the existing (non-invalid) entries of the table. If there is a match,
     * the prefetch unit waits until that entry's status is Valid, then responds instantly with
     * the data. Otherwise, the prefetch unit is cleared (all entries are invalidated) and
     * a new entry is allocated with the outstanding address. The unit acknowledges the in-
     * coming request once the result is registered and valid in the table. All entries with
     * addresses less or equal to the just acknowledged one are invalidated.
     *     When a new PUT request arrives from the front-end side, a similar address comparison
     * is carried out. If there is a match, the corresponding entry's data is invalidated. The PUT
     * is always acknowledged instantly (contingent upon the acknowledgement from the backend,
     * to whom a request is issued in the same CC); the prefetcher assumes that all such requests
     * are Valid and thus discards incoming AccessAck messages from the backend.
     *
     * All requests are acknowledged in the same cycle as the corresponding response exchange.
    */

    localparam int ADRW = $clog2(SIZE);

    typedef enum logic [1:0] {
        Invalid,
        Pending,
        Valid,
        Stale
    } entry_state_e;

    entry_state_e      entry_states [SIZE-1:0];
    logic [DDR_AW-1:0] entry_addrs  [SIZE-1:0];
    logic [     255:0] entry_data   [SIZE-1:0];

    logic [SIZE-1:0] addr_match_mask;
    logic [SIZE-1:0] addr_le_mask; // Addr <= FE.addr (-> invalidate on response)
    logic [SIZE-1:0] valid_mask;
    logic [SIZE-1:0] invalid_mask;
    logic [SIZE-1:0] pending_mask;
    logic [SIZE-1:0] non_pending_mask;

    generate
        for (genvar i = 0; i < SIZE; i++) begin
            // Address memory is used as CAM and thus can't be inferred as RAM resources
            assign addr_match_mask[i]  = entry_addrs[i] == fe_req_i.a_address;
            assign addr_le_mask[i]     = entry_addrs[i] <= fe_req_i.a_address;
            assign valid_mask[i]       = addr_match_mask[i] && entry_states[i] == Valid;
            assign pending_mask[i]     = addr_match_mask[i] && entry_states[i] == Pending;
            assign non_pending_mask[i] = entry_states[i] != Pending;
            assign invalid_mask[i]     = entry_states[i] == Invalid;
        end
    endgenerate

    logic [ADRW-1:0] allocate_addr;
    logic            can_allocate;
    assign can_allocate = |non_pending_mask;

    // Priority encoder for allocation address
    always_comb begin
        allocate_addr = '0;
        for (int i = SIZE; i > 0; i--) begin
            if (non_pending_mask[i-1]) allocate_addr = i-1;
        end
        // Invalid takes priority over non-pending
        for (int i = SIZE; i > 0; i--) begin
            if (invalid_mask[i-1]) allocate_addr = i-1;
        end
    end

    // Prefetch logic
    logic [DDR_AW-1:0] next_prefetch_addr;
    logic              is_prefetching; // whether current BE beat exchange is due to prefetch

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            next_prefetch_addr <= '0;
        end else begin
            if (fe_req_i.a_valid && ~|valid_mask && ~|pending_mask && fe_req_i.a_opcode == Get) begin
                // Miss, update next prefetch address to (miss address) + 1
                // Addresses are in blocks, thus increment by 1
                next_prefetch_addr <= fe_req_i.a_address + 1;
            end else begin
                if (is_prefetching && be_req_o.a_valid && be_rsp_i.a_ready) begin
                    next_prefetch_addr <= next_prefetch_addr + 1;
                end
            end
        end
    end

    // Frontend/Backend Beat exchange signals
    wire fe_req_xchg, fe_rsp_xchg;
    wire be_req_xchg, be_rsp_xchg;
    assign fe_req_xchg = fe_req_i.a_valid && fe_rsp_o.a_ready;
    assign fe_rsp_xchg = fe_rsp_o.d_valid && fe_req_i.d_ready;
    assign be_req_xchg = be_req_o.a_valid && be_rsp_i.a_ready;
    assign be_rsp_xchg = be_rsp_i.d_valid && be_req_o.d_ready;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            for (int i = 0; i < SIZE; i++) begin
                entry_states[i] <= Invalid;
                entry_addrs[i] <= '0;
            end
        end else begin
            // PREFETCH REQUEST
            if (is_prefetching && be_req_xchg) begin
                entry_states[allocate_addr] <= Pending;
                entry_addrs[allocate_addr] <= next_prefetch_addr;
            end

            // MISSED FRONTEND GET REQUEST
            if (fe_req_i.a_valid && ~|valid_mask && ~|pending_mask) begin
                // Incoming, non-prefetched request for which we want to allocate an entry
                if (can_allocate && fe_req_i.a_opcode == Get && be_req_xchg) begin
                    entry_states[allocate_addr] <= Pending;
                    entry_addrs[allocate_addr] <= fe_req_i.a_address;
                end
            end

            // BACKEND DATA RESPONSE
            if (be_rsp_xchg && be_rsp_i.d_opcode == AccessAckData) begin
                // If state is currently pending, set to valid, if stale, set to invalid
                entry_states[be_rsp_i.d_anc] <= entry_states[be_rsp_i.d_anc] == Stale ? Invalid : Valid;
            end

            // FRONTEND PUT REQUEST
            if (fe_req_xchg && fe_req_i.a_opcode != Get) begin
                for (int i = 0; i < SIZE; i++) begin
                    if (addr_match_mask[i] && (pending_mask[i] || valid_mask[i])) begin
                        entry_states[i] <= (pending_mask[i] ? Stale : Invalid);
                    end
                end
            end

            // FRONTEND DATA RESPONSE
            if (fe_rsp_xchg && fe_rsp_o.d_opcode == AccessAckData) begin
                // Invalidate all entries with address <= ack'd address
                for (int i = 0; i < SIZE; i++) begin
                    if (addr_le_mask[i]) entry_states[i] <= (pending_mask[i] ? Stale : Invalid);
                end
            end
        end
    end

    /* Entry data memory interface */

    logic [ADRW-1:0] valid_id;

    always_comb begin
        valid_id = '0;
        for (int i = 0; i < SIZE; i++) begin
            if (valid_mask[i]) valid_id = i;
        end
    end

    always_ff @(posedge clk_i) begin
        if (be_rsp_xchg && be_rsp_i.d_opcode == AccessAckData && entry_states[be_rsp_i.d_anc] != Valid) begin
            // Valid check: if there is a put request to an address matching an outstanding read
            // request, the prefetch buffer will validate the corresponding entry and write its
            // data. The backend response should then, logically, not overwrite with stale data.

            entry_data[be_rsp_i.d_anc] <= be_rsp_i.d_data;
        end
    end

    initial begin
        for (int i = 0; i < SIZE; i++) entry_data[i] = '0;
    end


    /* Output generation */

    always_comb begin
        fe_rsp_o = '{
            d_opcode: AccessAck,
            d_anc: fe_req_i.a_anc,
            default: '0
        };

        if (fe_req_i.a_valid) begin
            // Request
            if (fe_req_i.a_opcode == Get) begin
                // Check the prefetch buffer for match
                for (int i = 0; i < SIZE; i++) begin
                    if (valid_mask[i]) begin
                        fe_rsp_o.d_opcode = AccessAckData;
                        fe_rsp_o.d_valid = '1;
                        fe_rsp_o.a_ready = fe_req_i.d_ready;
                    end
                end
                fe_rsp_o.d_data = entry_data[valid_id]; // allow single read port
            end else begin
                // Put request
                // We forward the request to the backend, and respond once the backend accepts
                // the forwarded request (the backend response is later discarded)
                fe_rsp_o.d_valid = be_rsp_i.a_ready;
                fe_rsp_o.a_ready = fe_req_i.d_ready && be_rsp_i.a_ready;
            end
        end
    end

    always_comb begin
        be_req_o = '{
            a_valid: '0,
            a_opcode: fe_req_i.a_opcode,
            a_address: fe_req_i.a_address,
            a_data: fe_req_i.a_data,
            a_mask: fe_req_i.a_mask,
            a_anc: allocate_addr,
            d_ready: '1
        };
        is_prefetching = '1;

        if (can_allocate) begin
            if (fe_req_i.a_valid) begin
                if (fe_req_i.a_opcode == Get) begin
                    if (~|valid_mask && ~|pending_mask) begin
                        be_req_o.a_valid = '1;
                        is_prefetching = '0;
                    end
                end else begin
                    be_req_o.a_valid = '1;
                    is_prefetching = '0; 
                end
            end
        end

        if (fe_req_i.a_valid && fe_req_i.a_opcode != Get) begin
            be_req_o.a_valid = '1;
            is_prefetching = '0;
        end

        if (is_prefetching && |invalid_mask) begin // we only prefetch to invalid entries
            be_req_o.a_opcode = Get;
            be_req_o.a_address = next_prefetch_addr;
            be_req_o.a_valid = '1;
        end
    end

endmodule
