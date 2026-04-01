// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module rvlab_test_utils(
    jtag_master jtag
);
  import rvlab_tap_pkg::*;

  localparam int dmi_idle_cycles = 20; // Set this to a value high enough for the DMI to complete a transaction.
  localparam bit dm_check_sbbusy = '1; // disable for quicker simulation

  localparam verbose_dmi = '0;
  localparam verbose_hostio = '0;

  // Test reporting
  // --------------

  task test_start(string test_name);
    $display("[    ] %s", test_name);
  endtask

  task test_end(string test_name, int errcnt);
    if(errcnt == 0) begin
      $display("[pass] %s", test_name);
    end
    else begin
      $display("[FAIL] %s, errcnt=%d", test_name, errcnt);
    end
  endtask

  // RISC-V Debug module interface
  // -----------------------------

  task dmi_read(input logic [6:0] raddr, output logic [31:0] rdata, inout int errcnt);
    dm::dmi_t request;
    dm::dmi_t result;
    int i;
    
    jtag.set_ir(DMIACCESS);
    
    request = '{address:raddr, data:'0, op: dm::DTM_READ};
    jtag.cycle_dr_dmi(result, request);

    for(i=0;i<dmi_idle_cycles;i++) begin
      jtag.cycle_idle();
    end

    request = '{address:'0, data:'0, op: dm::DTM_NOP};
    jtag.cycle_dr_dmi(result, request);
        
    //$display("dmi addr: %x, data: %x, op: %x", result.address, result.data, result.op);

    case (result.op)
      dm::DMINoError: begin
        rdata = result.data;
      end
      dm::DMIBusy: begin
        $error("DMI busy (read).");
        rdata = 'x;
        errcnt++;
      end
      default: begin
        $error("DMI operation failed (read).");
        rdata = 'x;
        errcnt++;
      end
    endcase
  endtask

  task dmi_write(input logic [6:0] waddr, input logic [31:0] wdata, inout int errcnt);
    dm::dmi_t request;
    dm::dmi_t result;
    int i;
    
    jtag.set_ir(DMIACCESS);
    
    request = '{address:waddr, data:wdata, op: dm::DTM_WRITE};
    jtag.cycle_dr_dmi(result, request);

    for(i=0;i<dmi_idle_cycles;i++) begin
      jtag.cycle_idle();
    end

    request = '{address:'0, data:'0, op: dm::DTM_NOP};
    jtag.cycle_dr_dmi(result, request);
        
    //$display("dmi addr: %x, data: %x, op: %x", result.address, result.data, result.op);

    case (result.op)
      dm::DMINoError: begin
      end
      dm::DMIBusy: begin
        $error("DMI busy (write).");
        errcnt++;
      end
      default: begin
        $error("DMI operation failed (write).");
        errcnt++;
      end
    endcase
  endtask

  // RISC-V Debug
  // ------------

  dm::dmcontrol_t dmcontrol;
  dm::sbcs_t sbcs;
  dm::dmstatus_t dmstatus;
  string rx_line_buf;
  string full_output; // check this to verify full output of program.

  initial begin
    dmcontrol = '{default:0};

    sbcs = '{default: 0};
    sbcs.sbreadonaddr = '0;
    sbcs.sbaccess = 2; // 32-bit access

    rx_line_buf = "";
    full_output = "";
  end

  task dm_start(inout int errcnt);
    dmcontrol.hartsello = '0;
    dmcontrol.hartselhi = '0;
    dmcontrol.dmactive = '1;
    dmi_write(dm::DMControl, dmcontrol, errcnt);
  endtask

  task dm_stop(inout int errcnt);
    dmcontrol = '{default: '0};
    dmi_write(dm::DMControl, dmcontrol, errcnt);
  endtask

  task dm_halt(inout int errcnt);
    dmcontrol.haltreq = '1;
    dmi_write(dm::DMControl, dmcontrol, errcnt);
    dmcontrol.haltreq = '0;

    do begin
      tu.dmi_read(dm::DMStatus, dmstatus, errcnt);
    end while(~dmstatus.allhalted);
  endtask

  task dm_resume(inout int errcnt);
    dmcontrol.resumereq = '1;
    dmi_write(dm::DMControl, dmcontrol, errcnt);
    dmcontrol.resumereq = '0;

    do begin
      tu.dmi_read(dm::DMStatus, dmstatus, errcnt);
    end while(~dmstatus.allrunning);
  endtask

  task dm_write_cpureg(input logic [15:0] regno, input logic [31:0] wdata, inout int errcnt);
    dm::ac_ar_cmd_t ac_ar; // abstract command: access register
    dm::command_t cmd;

    dmi_write(dm::Data0, wdata, errcnt);

    ac_ar = '{
      aarsize: 2, // access 32 bits
      transfer: '1,
      write: '1,
      regno: regno, // debug pc (dpc)
      default: '0
    };
    cmd = '{
      cmdtype: dm::AccessRegister,
      control: ac_ar
    };
    dmi_write(dm::Command, cmd, errcnt);
  endtask

  task dm_sba_write(input logic [31:0] waddr, input logic [31:0] wdata, inout int errcnt);
    if (sbcs.sbreadonaddr) begin
      sbcs.sbreadonaddr = '0;
      tu.dmi_write(dm::SBCS, sbcs, errcnt);
    end

    tu.dmi_write(dm::SBAddress0, waddr, errcnt);
    tu.dmi_write(dm::SBData0, wdata, errcnt); 

    if(dm_check_sbbusy) begin
      do begin
        tu.dmi_read(dm::SBCS, sbcs, errcnt);    
      end while(sbcs.sbbusy);
    end
  endtask

  task dm_sba_write_successive(input logic [31:0] waddr, input logic [31:0] wdata, input bit send_addr, inout int errcnt);
    if (sbcs.sbreadonaddr || (!sbcs.sbautoincrement)) begin
      sbcs.sbreadonaddr = '0;
      sbcs.sbautoincrement = '1;
      tu.dmi_write(dm::SBCS, sbcs, errcnt);
    end

    if(send_addr) begin
      tu.dmi_write(dm::SBAddress0, waddr, errcnt);
    end
    tu.dmi_write(dm::SBData0, wdata, errcnt); 

    if(dm_check_sbbusy) begin
      do begin
        tu.dmi_read(dm::SBCS, sbcs, errcnt);    
      end while(sbcs.sbbusy);
    end
  endtask


  task dm_sba_read(input logic [31:0] raddr, output logic [31:0] rdata, inout int errcnt);
    if (~sbcs.sbreadonaddr) begin
      sbcs.sbreadonaddr = '1;
      tu.dmi_write(dm::SBCS, sbcs, errcnt);
    end

    tu.dmi_write(dm::SBAddress0, raddr, errcnt);
    
    if(dm_check_sbbusy) begin
      do begin
        tu.dmi_read(dm::SBCS, sbcs, errcnt);    
      end while(sbcs.sbbusy);
    end
    
    tu.dmi_read(dm::SBData0, rdata, errcnt); 

  endtask

  task dm_load_mem(string mem_filename, inout int errcnt);
    bit [31:0] wdata;
    bit send_addr; // track whether resend is required or not due to sbautoincrement
    logic [7:0] sw_mem[0:2**18];
    int i;
    
    send_addr = '1;

    for(i=0;i<2**18;i++) begin
      sw_mem[i] = '0;
    end

    $readmemh (mem_filename, sw_mem);
    
    for(i=0;i<2**16;i++) begin
      wdata = {sw_mem[i<<2 | 3],sw_mem[i<<2 | 2],sw_mem[i<<2 | 1],sw_mem[i<<2 | 0]};
      if(wdata != '0) begin
        dm_sba_write_successive(i<<2, wdata, send_addr, errcnt);
        send_addr = '0;
        if(verbose_dmi) begin
          $display("write(addr=0x%08x, data=0x%08x)", i<<2, wdata);
        end
        else begin
          $write(".");
          if(i%32 == 31) begin
            $write("\n");
          end
        end
      end
      else begin
        send_addr = '1;
      end
    end
    if(!verbose_dmi) begin
      $write("\n");
    end
  endtask
  
  task dm_load_delta(string delta_filename, inout int errcnt);
    bit [31:0] wdata;
    bit [31:0] addr;
    bit [31:0] i;
    string s;
    bit send_addr;
    int f;
    int r;

    f = $fopen(delta_filename, "r");

    send_addr = '1;
    addr = '0;

    while(! $feof(f)) begin
      r = $fscanf(f, "%s %x", s, i);
      if(r != 2) begin
        if($feof(f))
          break;
        $error("dm_load_delta: fscanf could not parse line in delta file.");
      end
      if (s == "addr") begin
        send_addr = '1;
        addr = i;
      end
      else if (s == "data") begin
        wdata = i;
        if(verbose_dmi)
          $display("dm_load_delta: write %08x: %08x", addr, wdata);
        dm_sba_write_successive(addr, wdata, send_addr, errcnt);
        send_addr = '0;
        addr += 4;
      end
      else begin
        $error("dm_load_delta: unexpected line in delta file.");
      end
    end

    $fclose(f);

  endtask

  task putc(input bit [7:0] char);
    string char_str;

    char_str = "?";
    char_str.putc(0, char);
    
    if(verbose_hostio) begin
      $display("Received char %02x (%c)", char, char);
    end

    full_output = {full_output, char_str};
    if (char == "\n") begin
      $display("hostio: %s", rx_line_buf);
      rx_line_buf = "";
    end else begin
      rx_line_buf = {rx_line_buf, char_str};
    end
  endtask

  localparam bit [31:0] HOSTIO_OBUF_SIZE = 1024;
  localparam bit [31:0] HOSTIO_IBUF_SIZE = 1024;
  localparam bit [31:0] HOSTIO_OBUF      = 32'h0003F000;
  localparam bit [31:0] HOSTIO_IBUF      = 32'h0003F400;
  localparam bit [31:0] HOSTIO_FLAGS     = 32'h0003F800;
  localparam bit [31:0] HOSTIO_RETVAL    = 32'h0003F804;
  localparam bit [31:0] HOSTIO_OBUF_WIDX = 32'h0003F808;
  localparam bit [31:0] HOSTIO_OBUF_RIDX = 32'h0003F80C;
  localparam bit [31:0] HOSTIO_IBUF_WIDX = 32'h0003F810;
  localparam bit [31:0] HOSTIO_IBUF_RIDX = 32'h0003F814;


  task wait_prog(inout int errcnt);
    bit [31:0] hostio_flags;
    bit [31:0] hostio_retval;
    bit [31:0] hostio_widx;
    bit [31:0] hostio_ridx;
    bit        hostio_ridx_dirty;
    bit [31:0] buf_addr;
    bit [31:0] addr_next;
    bit        buf_data_valid;
    bit [31:0] buf_data;

    hostio_flags = '0;
    hostio_ridx = '0;
    buf_data_valid = '0;
    hostio_ridx_dirty = '0;

    while (~hostio_flags[0]) begin
      tu.dm_sba_read(HOSTIO_FLAGS, hostio_flags, errcnt);
      //$display("hostio_flags = %x", hostio_flags);
      tu.dm_sba_read(HOSTIO_OBUF_WIDX, hostio_widx, errcnt);
      //$display("hostio_widx = %x", hostio_widx);

      while(hostio_widx != hostio_ridx) begin
        addr_next = HOSTIO_OBUF + (hostio_ridx&~3);

        if(!buf_data_valid || (buf_addr != addr_next)) begin
          buf_addr = addr_next;
          tu.dm_sba_read(buf_addr, buf_data, errcnt);
          buf_data_valid = (hostio_ridx & ~3) != (hostio_widx & ~3);
          // If ridx and widx are too close together so that we cannot use
          // the buf_data for more than one character read, buf_data_valid
          // remains low to make sure it is not reused (even though at least
          // the byte we are interested in in this loop iteration is valid.)
        end

        putc( (buf_data >> ((hostio_ridx&3)*8)) & 8'hFF );

        hostio_ridx = (hostio_ridx + 1) & (HOSTIO_OBUF_SIZE-1);
        hostio_ridx_dirty = '1;

        if(hostio_ridx_dirty && (hostio_ridx & 127 == 0)) begin
          // Send a ridx update every 128 reads, even if we are still busy with reading.
          tu.dm_sba_write(HOSTIO_OBUF_RIDX, hostio_ridx, errcnt);
          hostio_ridx_dirty = '0;
        end
        //$display("hostio_ridx = %x", hostio_ridx);
      end
    
      if(hostio_ridx_dirty) begin
        // always send a ridx update when we are no longer busy with reading:
        tu.dm_sba_write(HOSTIO_OBUF_RIDX, hostio_ridx, errcnt);
        hostio_ridx_dirty = '0;
      end
    end

    if(rx_line_buf.len()>0) begin
      putc("\n");
      $display("(Missing newline at end of output.)");
    end
    tu.dm_sba_read(HOSTIO_RETVAL, hostio_retval, errcnt);
    $display("Execution finished. Return value: %d", hostio_retval);

    if(hostio_retval) begin
      errcnt += 1;
    end

  endtask

endmodule
