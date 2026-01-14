/* Copyright David Schröder 2025. */
/* TL-UL <-> TL-UL Variable Clocking manager */
/* Allows the getting and setting of the current system clock divider */
/* Implements a CDC to prevent spurious resets on reconfiguration */

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
│   │ └──────────────┘ │ <------ this module
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

module rvlab_clk_reconfig #(
  parameter int FALLBACK_CLKDIV = 18,
  parameter int USE_SAFETY_NET = 1
) (
  input  logic board_clk_i, // Same clock driving MMCM
  input  logic sys_clk_i, // System clock
  input  logic board_rst_ni, // Master reset (JTAG SRST)
  input  logic sys_rst_ni, // System reset - for CDC

  /* Host: SoC [submodule] */
  input  tlul_pkg::tl_h2d_t tl_host_i,
  output tlul_pkg::tl_d2h_t tl_host_o,
  /* Device: TL-UL <-> DRP adapter */
  output tlul_pkg::tl_h2d_t tl_device_o,
  input  tlul_pkg::tl_d2h_t tl_device_i,

  input  logic mmcm_locked_i,
  output logic sys_rst_no,

  output logic [1:0] status_o
);

  /* How It Works */
  /*
    The variable clocking configurator has a single [virtual] register accessed by TL-UL.
    This register is the main system clock divider register. Upon read, the reconfiguration
    module makes a request to the MMCM (via DRP) to fetch the CLKOUT0 ClkReg1 value, to get
    the high/low VCO cycle counters. When added together, these equal the sysclock divider.
    Upon a write, the desired divider value needs to be split into three parts:
    - # High VCO Cycles
    - # Low VCO Cycles
    - Edge bit
    The high cycle counter is the divider value right shifted by one, and the low cycle
    counter is the same value plus the LSB of the divider value. This ensures that the sum
    of high and low counters is the desired value. The edge bit is directly equal to the
    divider value's LSB.

    The high and low cycle counters are concatenated and zero-filled to 16 bits to form
    the new ClkReg1 value (PHASE MUX and the reserved bit can be set to zero safely), and
    the edge bit is placed at the right position (bit 7) to form the new ClkReg2 Value.
    For each register, one bus request to the DRP adapter is executed using an FSM.

    ---

    On the host (SoC) side, a CDC is implemented using two asynchronous TL-UL FIFOs.

  */

  import tlul_pkg::*;
  import top_pkg::*;

  /* CDC */

  tl_h2d_t tl_safety_h_h2d;
  tl_d2h_t tl_safety_h_d2h;

  tlul_fifo_async vc_cdc_fifo_i (
    .clk_h_i (sys_clk_i),
    .rst_h_ni(sys_rst_ni),
    .clk_d_i (board_clk_i),
    .rst_d_ni(sys_rst_ni),
    .tl_h_i  (tl_host_i),
    .tl_h_o  (tl_host_o),
    .tl_d_i  (tl_safety_h_d2h),
    .tl_d_o  (tl_safety_h_h2d)
  );

  /* From here, same clock domain reconfig module between tl_reconf and tl_device */

  /* Safety net */

  tl_h2d_t tl_reconf_h2d;
  tl_d2h_t tl_reconf_d2h;

  generate
    if (USE_SAFETY_NET == 1) begin : gen_safety
      rvlab_clk_safety_net #(
        .FALLBACK_CLKDIV           (FALLBACK_CLKDIV),
        .SYSCLK_VADDR              (12'h100),
        .STATUS_ADDR               (12'h108),
        .DUMMY_ADDR                (12'h10C),
        .DUMMY_READ_VALUE          (32'hCA32E40B), // supposed to resemble cpu name :)
        .DUMMY_EXPECTED_WRITE_VALUE(32'h172E4A55),
        .TIMER_HIGH                (1000)
      ) safety_i (
        .clk_i (board_clk_i),
        .rst_ni(board_rst_ni),

        .tl_h_i(tl_safety_h_h2d),
        .tl_h_o(tl_safety_h_d2h),
        .tl_d_i(tl_reconf_d2h),
        .tl_d_o(tl_reconf_h2d),

        .mmcm_locked_i,
        .sys_rst_no,

        .status_o
      );
    end else begin
      assign tl_reconf_h2d = tl_safety_h_h2d;
      assign tl_safety_h_d2h = tl_reconf_d2h;
      assign sys_rst_no = '1;
      assign status_o = '0;
    end
  endgenerate

  /* Reconfiguration FSM */

  typedef enum logic [2:0] {
    Await     = 3'h0, // Waiting for host request
    Fetch     = 3'h1, // Waiting for device handshake
    Receive   = 3'h2, // Wait for device response
    WriteReg1 = 3'h3,
    RecvWAck1 = 3'h4, // Wait for device response for reg 1 write
    WriteReg2 = 3'h5,
    RecvWAck2 = 3'h6  // Wait for device response for reg 2 write
  } clk_reconf_state_e;

  clk_reconf_state_e state_q;
  clk_reconf_state_e state_d;

  logic [5:0] cfg_high_vco_cycles, cfg_low_vco_cycles;
  logic       cfg_edge;

  logic [TL_AIW-1:0] req_source;
  logic [      31:0] req_address;
  logic [      31:0] remapped_addr;

  always_comb begin
    /* Reconfig TL-UL (to safety / CDC) */

    tl_reconf_d2h = '{
      d_opcode: AccessAckData,
      d_size: 2'h2,
      d_source: req_source,
      default: '0
    };
    case (state_q)
      Await: begin
        tl_reconf_d2h.a_ready = '1;
      end
      Receive: begin
        tl_reconf_d2h.d_valid = tl_device_i.d_valid;
        // Clock divider is high cycles + low cycles
        tl_reconf_d2h.d_data = tl_device_i.d_data[11:6] + tl_device_i.d_data[5:0];
      end
      RecvWAck2: begin
        tl_reconf_d2h.d_valid = tl_device_i.d_valid;
        tl_reconf_d2h.d_opcode = AccessAck;
      end
      default : /* */;
    endcase
  end

  always_comb begin
    /* Device TL-UL (to DRP adapter) */
    tl_device_o = '{a_opcode: Get, a_address: remapped_addr, a_size: 2'h2, default: '0};
    case (state_q)
      Fetch: tl_device_o.a_valid = '1;
      Receive: tl_device_o.d_ready = tl_reconf_h2d.d_ready;
      WriteReg1: begin
        tl_device_o.a_opcode = PutFullData;
        tl_device_o.a_data = {4'h1, cfg_high_vco_cycles, cfg_low_vco_cycles};
        tl_device_o.a_valid = '1;
      end
      RecvWAck1: tl_device_o.d_ready = '1;
      WriteReg2: begin
        tl_device_o.a_opcode = PutFullData;
        tl_device_o.a_data = {8'h0, cfg_edge, 7'h0};
        tl_device_o.a_valid = '1;
      end
      RecvWAck2: tl_device_o.d_ready = tl_reconf_h2d.d_ready;
    endcase
  end

  always_comb begin
    /* State */
    state_d = state_q;
    case (state_q)
      Await: begin
        if (tl_reconf_h2d.a_valid) state_d = tl_reconf_h2d.a_opcode == Get ? Fetch : WriteReg1;
      end
      Fetch: begin
        if (tl_device_i.a_ready) state_d = Receive;
      end
      Receive: begin
        if (tl_device_i.d_valid && tl_reconf_h2d.d_ready) state_d = Await;
      end
      WriteReg1: begin
        if (tl_device_i.a_ready) state_d = RecvWAck1;
      end
      RecvWAck1: begin
        if (tl_device_i.d_valid) state_d = WriteReg2;
      end
      WriteReg2: begin
        if (tl_device_i.a_ready) state_d = RecvWAck2;
      end
      RecvWAck2: begin
        if (tl_device_i.d_valid && tl_reconf_h2d.d_ready) state_d = Await;
      end
      default: /* */;
    endcase
  end

  always_ff @(posedge board_clk_i or negedge board_rst_ni) begin
    if(~board_rst_ni) begin
      state_q <= Await;
      cfg_high_vco_cycles <= '1;
      cfg_low_vco_cycles <= '1;
      cfg_edge <= '0;
      req_source <= '0;
      req_address <= '0;
    end else begin
      state_q <= state_d;
      if (state_q == Await) begin
        if (tl_reconf_h2d.a_valid && tl_reconf_d2h.a_ready) begin
          req_source <= tl_reconf_h2d.a_source;
          req_address <= tl_reconf_h2d.a_address;
        end
        if (tl_reconf_h2d.a_valid && tl_reconf_h2d.a_opcode == PutFullData) begin
          cfg_high_vco_cycles <= tl_reconf_h2d.a_data[6:1];
          cfg_low_vco_cycles <= tl_reconf_h2d.a_data[6:1] + tl_reconf_h2d.a_data[0]; // See description
          cfg_edge <= tl_reconf_h2d.a_data[0];
        end
      end
    end
  end

  /* Address Remapper */

  rvlab_clk_remap_addr addr_remapper_i (
    .vaddr_i     (req_address),
    .clkreg_mux_i(state_q == WriteReg2),
    .drp_addr_o  (remapped_addr)
  );

endmodule
