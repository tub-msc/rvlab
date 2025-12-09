.. _`fpga_upload`:

FPGA Upload
===========

    .. note::
        1. absolutely **no probing** (oscilloscope, voltmeter, logic analyzer) on the FPGA board ! Connect measurement equipment only to PMOD connectors!
        2. **never connect any supply or ground** to an (PMOD) FPGA IO! If you need a fixed logic level connect a supply pin of the PMOD connector **via a resistor** (e.g. 4.7k) to the IO !
        3. Every hardware connected to the board must be cleared by the tutor - especially self build PCBs !
 
*Mechanical pressure over time creates micro interruptions (in solder pads and internal layers). If you want to probe any FPGA IO (e.g. to to an on board device) mirror the FPGA IO in your design to a second FPGA IO of a PMOD connector. For the same reason the push buttons may not be used.*

*A power supply is very low ohmic - connecting it to a wrong place (e.g. output) even briefly will kill the FPGA.*

Load bitstream
--------------

Make sure the FPGA board power is connected, the POWER switch on the board is turned on and the PROG USB port is connected to the host computer. The red LED below the power connector should be alight.

To flash the bitstream to the FPGA, use the following command::

    flow rvlab_fpga_top.program

Sometimes, this command fails on the first attempt. It should work on the second attempt.

Run software
------------

After bitstream flashing, the FPGA is in reset state by default.

To run the *monitor* program, which provides a simple interface for memory accesses::

    flow sw_monitor.run

To run the *student* program::
    
    flow sw_student.run

The *run* targets also perform a system reset. If the program is stuck, terminate the run command with Ctrl+C and restart it. The physical buttons on the FPGA board **cannot** be used for system reset.

Debug via GDB
-------------

**This step is not mandatory!**

After starting the *student* program with :code:`flow sw_student run`, you can also attach the GNU Debugger (GDB) to your running hardware for in-system debugging including single-stepping and full memory access. To do this, run :code:`riscv-none-embed-gdb build/sw_student/build/sw.elf` and establish the connection to OpenOCD with :code:`target extended-remote :3333` (command can also be abbreviated as :code:`tar ext :3333`).

The program is not stopped by default. Use :code:`step` for single stepping, :code:`break cmd_sw` to set a breakpoint on the *cmd_sw* function, :code:`continue` to resume execution etc.

Further reading:

- `GDB tutorial <https://people.astro.umass.edu/~weinberg/a732/gdbtut.html>`_
- `GDB documentation <https://sourceware.org/gdb/current/onlinedocs/gdb.html/>`_
