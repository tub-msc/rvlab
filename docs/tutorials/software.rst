.. _software:

Software
========

Multiple programs are defined and can be built from the rvlab codebase:

- **rlight** -- student program for running light (exercises 2, 3 and possibly exercise 5)
- **dma** -- student program for exercise 4
- **project** -- student program for project work (and exercise 5?)
- **minimal** -- minimal example program, can be used as template when adding programs
- **monitor** -- simple shell-like interface for interactive reading / writing of SoC memory locations
- **test_rvlab** -- tests various system components (simulation and FPGA). If the DDR3 memory controller is found, a time-intensive DDR3 memory test (infeasible for simulation) is performed.
- **test_sim_ddr** -- minimal test of DDR3 memory functionality, intended for RTL simulation with included DDR3 memory controller 

Each program corresponds to one subfolder in */src/sw*.
In addition to that, the */src/sw* folder contains following resources shared by all programs:

- **crt0.S** -- Assembly code for system boot and interrupt handling
- **sys** -- Shared system files (hostio.c, irq.c, ddr_init.c) and minimal libc implementation
- **include** -- Shared system headers (rvlab.h, regaccess.h) and libc headers (stdio.h etc.), can be include via ``#include <...>``.
- **link.ld** -- Linker script

The provided libsys provides some noteforthy functionality besides basic functions like *memset*, *sprintf* and *strlen*:

- :ref:`dynamic_memory_management`
- :ref:`host_io`
- predefined interrupt service routines


Adding programs
---------------

To define a new program *"myprog"*, create the folder */src/sw/myprog* and place source code in it. You can place one or multiple .c and .S (assembly) files in this folder.

To define the progarm for *flow*, add "myprog" to the list *sw_dirs* in */flow/__init__.py*.


.. _`host_io`:

Host I/O
--------

**stdout** and **stdin**, the C standard output and standard input streams, are available for communication with the testbench or the host computer connected to the FPGA.

Both stdout and stdin are implemented with ring buffers (software FIFOs) allocated in main BRAM. The data that Ibex writes to the stdout ring buffer is read by the testbench or host computer by system bus access through the RISC-V debug module. For stdin, this process is reversed.

When the stdout ring buffer is full, writes to stdout block until pending data is read by the debugger. Writes to stdout can block indefinitely when no debugger is attached to the system. 

Key source files for host I/O;

- */src/sw/sys/hostio.c* -- implements stdout/stdin ring buffers on RISC-V CPU
- */src/tb/rvlab_test_utils.sv* -- During simulation, task *wait_prog* reads lines from stdout via JTAG and prints them to simulator output. (Newlines are required!)
- */flow/tools/openocd.py* -- When running programs on the :ref:`fpga_board`, this Python script connects stdin and stdout of the FPGA system to the host machine. JTAG-based memory accesses are performed via OpenOCD's RPC interface.  

.. _`dynamic_memory_management`:

Initializing DDR3
-----------------

The DDR3 memory controller must be initialized before use. If you want to use DDR3 memory in your project, feel free to copy *init.c* and *init.h* from */src/sw/monitor* into your program path and call :code:`ddr_init();` to initialize the memory controller.

DDR3 initialization will fail during RTL simulations without DDR3 enabled. Simulation of the DDR3 memory is only feasible pre-synthesis using the special *sim_rtl_questa_ddr* (or *sim_rtl_xsim_ddr*) target. Pre-synthesis, a shortened memory reset and calibration sequence is used. Post-synthesis, the full reset and calibration sequence would be used, which is infeasible in terms of simulation time.

Dynamic memory management
-------------------------

The provided libc comes with a simple malloc implementation for dynamic memory management. Before it can be used, :code:`add_malloc_block` needs to be called to add memory to the pool of available memory.

Example, using the entire DDR3 memory as memory pool:

.. code-block:: c

    #include <stdlib.h>
    #include <stdio.h>

    ...

    add_malloc_block(0x80000000, 0x20000000);
    char *myAlloc = malloc(100);
    printf("myAlloc = %08x\n", myAlloc);
    free(myAlloc);
