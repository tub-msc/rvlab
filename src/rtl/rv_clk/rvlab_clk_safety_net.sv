// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2025 RVLab Contributors

// Safety fallback to prevent clock speed changes from irrevocably
// making the SoC unresponsive


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
│   │ │  ADDR REMAP  │ │      │
│   │ └──────────────┘ │      │
│   │ ┌──────────────┐ │      │
│   │ │  SAFETY NET  │ <------ this module
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

module rvlab_clk_safety_net #(
    parameter int          FALLBACK_CLKDIV = 18,
    parameter logic [31:0] AR_MASK = 32'h00000FFF, // Address range mask
    parameter logic [31:0] SYSCLK_VADDR = 12'h0, // Address of virtual system clock divider register
    parameter logic [31:0] STATUS_ADDR = 12'h008,
    parameter logic [31:0] DUMMY_ADDR = 12'h00C,
    parameter logic [31:0] DUMMY_READ_VALUE = 32'hC4,
    parameter logic [31:0] DUMMY_EXPECTED_WRITE_VALUE = 32'hBC4,
    parameter int          TIMER_HIGH = 1000 // Timer duration in clock cycles
) (
    input logic clk_i,
    input logic rst_ni,

    input  tlul_pkg::tl_h2d_t tl_h_i,
    output tlul_pkg::tl_d2h_t tl_h_o,
    input  tlul_pkg::tl_d2h_t tl_d_i,
    output tlul_pkg::tl_h2d_t tl_d_o,

    input  logic mmcm_locked_i,
    output logic sys_rst_no,

    output logic [1:0] status_o
);

    import tlul_pkg::*;

    /*

    How it works
    ----------

    The job of the safety net is to prevent the SoC from becoming unresponsive if a clock speed reconfiguration
    causes fatal timing violations. In other words, after a put request to the SYSCLK_VADDR via the tl_h port,
    the SoC is at risk of breaking. To prevent this problem, the safety net starts a countdown timer (counting
    down from TIMER_HIGH). The SoC must answer this timer by sending a write request containing the correct
    data to DUMMY_ADDR. If it does not respond in time, or if the data is incorrect, the SoC is in an unstable
    state. If this occurs, the safety net updates the system clock divider to FALLBACK_CLKDIV and further
    resets the SoC via sys_rst_n. A better solution would be to interrupt the CPU instead of resetting it, but
    this would introduce further complexity to the SoC and has thus been avoided.

    To recap, the flow upon update of the clock divider value is as follows:

    1. Write request to SYSCLK_VADDR
    2. Countdown from TIMER_HIGH is initiated
    3. Get request from DUMMY_ADDR
    4. If timer runs out:
        4.1 Update system clock divider to FALLBACK_CLKDIV
        4.2 Reset SoC
    5. Else: Write request to DUMMY_ADDR
    6. If write data does not match expected data, perform 4.1 and 4.2
    7. Finally, go back to idle state

    Steps 3 and 6 are crucial for the verification of the SoC's functionality. The principal idea is that
    the CPU loads data from the volatile address DUMMY_ADDR, performs a somewhat complicated (10-100 cycles)
    computation using said data, and writes the result data back to DUMMY_ADDR. "Loads data" and "writes back"
    are however unfaithful descriptions, as there need not be a physical register at DUMMY_ADDR. The data
    provided in the get request can be a constant, and the result data is thus also constant. As long as the
    compiler cannot fold constants in the section of code responsible for the SoC verification, using constants
    suffices.

    */

    logic [31:0] expected_data;
    assign expected_data = DUMMY_EXPECTED_WRITE_VALUE;

    logic [31:0] timer_value;

    logic [1:0] status;
    assign status_o = status;

    typedef enum logic [2:0] { // State description                     Valid next states
        Idle       = 3'b000,   // Idle state                            RspWait
        RspWait    = 3'b001,   // Wait for DRP to respond after write   FetchWait
        FetchWait  = 3'b010,   // Wait for Get request                  VerifyWait, Violation
        VerifyWait = 3'b011,   // Wait for Put request                  Violation, Idle
        Violation  = 3'b100,   // SoC is unstable; reset                ResetWait
        ResetWait  = 3'b101    // Wait for DRP to respond after reset   Idle
    } safety_state_e;

    safety_state_e state_q, state_d;

    logic  system_unstable;
    assign system_unstable = state_q == Violation || state_q == ResetWait;
    assign sys_rst_no = !system_unstable;

    tl_h2d_t tl_d_override;
    tl_d2h_t tl_h_override;

    always_comb begin
        tl_d_override = '{
            a_valid: state_q == Violation ? '1 : '0,
            a_opcode: PutFullData,
            a_address: SYSCLK_VADDR,
            a_data: FALLBACK_CLKDIV,
            a_size: 2'h2,
            d_ready: '1,
            default: '0
        };
        tl_h_override = '{d_opcode: AccessAck, default: '0};
        tl_h_o = system_unstable ? tl_h_override : tl_d_i;
        tl_d_o = system_unstable ? tl_d_override : tl_h_i;

        if (state_q == RspWait) begin
            tl_d_o.a_valid = '0;
            tl_h_o.a_ready = '0;
        end else begin
            if (tl_h_i.a_valid && (tl_h_i.a_address & AR_MASK) == DUMMY_ADDR) begin
                tl_d_o.a_valid = '0;
                tl_d_o.d_ready = '0;
                tl_h_o = '{
                    d_valid: '1,
                    d_opcode: tl_h_i.a_opcode == Get ? AccessAckData : AccessAck,
                    d_size: 2'h2,
                    d_source: tl_h_i.a_source,
                    d_data: DUMMY_READ_VALUE,
                    a_ready: tl_h_i.d_ready,
                    default: '0
                };
            end
            if (tl_h_i.a_valid && (tl_h_i.a_address & AR_MASK) == STATUS_ADDR) begin
                tl_d_o.a_valid = '0;
                tl_d_o.d_ready = '0;
                tl_h_o = '{
                    d_valid: '1,
                    // AccessAck means nothing; status_addr is an SWRO field
                    d_opcode: tl_h_i.a_opcode == Get ? AccessAckData : AccessAck,
                    d_size: 2'h2,
                    d_source: tl_h_i.a_source,
                    d_data: status,
                    a_ready: tl_h_i.d_ready,
                    default: '0
                };
            end
        end
    end

    always_comb begin
        state_d = state_q;
        case (state_q)
            Idle: begin
                if (tl_d_o.a_valid && tl_d_i.a_ready && tl_d_o.a_opcode != Get) begin
                    if ((tl_d_o.a_address & AR_MASK) == SYSCLK_VADDR) begin
                        state_d = RspWait;
                    end
                end
            end
            RspWait: begin
                if (tl_d_i.d_valid && tl_d_o.d_ready) state_d = FetchWait;
            end
            FetchWait: begin
                if (tl_h_i.a_valid && tl_h_i.a_opcode == Get && (tl_h_i.a_address & AR_MASK) == DUMMY_ADDR) begin
                    state_d = VerifyWait;
                end else if (timer_value == 0) state_d = Violation;
            end
            VerifyWait: begin
                if (tl_h_i.a_valid && tl_h_i.a_opcode != Get && (tl_h_i.a_address & AR_MASK) == DUMMY_ADDR) begin
                    state_d = tl_d_o.a_data == expected_data ? Idle : Violation;
                end else if (timer_value == 0) state_d = Violation;
            end
            Violation: begin
                if (tl_d_o.a_valid && tl_d_i.a_ready) state_d = ResetWait;
            end
            ResetWait: begin
                if (tl_d_i.d_valid && tl_d_o.d_ready) state_d = Idle;
            end
            default: ;
        endcase
    end

    logic is_init_resetting;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            // Immediately trigger a reset to the default
            // sysclk divider value. Set is_init_resetting though,
            // to ensure that status doesn't get spuriously
            // written with a FetchWait error when none occurred.
            timer_value <= 32'h1;
            state_q <= FetchWait;
            status <= '0; // no error
            is_init_resetting <= '1;
        end else begin
            state_q <= state_d;
            if (mmcm_locked_i) begin
                case (state_q) 
                    Idle       : timer_value <= '0;
                    RspWait    : timer_value <= TIMER_HIGH;
                    FetchWait  : timer_value <= timer_value - 1;
                    VerifyWait : timer_value <= timer_value - 1;
                    Violation  : timer_value <= '0;
                    ResetWait  : timer_value <= '0;
                    default    : timer_value <= '0;
                endcase
                if (state_q != RspWait && timer_value == 0) timer_value <= '0; // don't overflow
            end
            if (state_d == Violation) begin
                if (state_q == FetchWait) status <= 2'b01; // fetch timeout
                else if (state_q == VerifyWait) begin
                    if (tl_h_i.a_valid && tl_h_i.a_opcode != Get && (tl_h_i.a_address & AR_MASK) == DUMMY_ADDR) begin
                        status <= 2'b10; // wrong verification data
                    end else status <= '1; // verification timeout
                    // TODO: find bug causing verification timeout status to brick system
                end
            end else if (state_d == Idle) begin
                if (state_q == VerifyWait) begin
                    // successful writes to sysclk reset status
                    status <= '0;
                end
            end
            if (status != '0 && is_init_resetting) begin
                // status will unfortunately be nonzero for 1CC.
                // this is an acceptable compromise for the
                // simplicity of the is_init_resetting solution.
                status <= '0;
                is_init_resetting <= '0;
            end
        end
    end

endmodule
