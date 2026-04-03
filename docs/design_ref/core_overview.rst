.. _`Core Overview`:

Core Overview
=============

The following block diagram gives an overview of the **rvlab_core** module.

.. figure:: rvlab_core.svg
   :width: 100%

   rvlab_core block diagram

H indicates a TL-UL host port, D a TL-UL device port. 

The system clock and reset are provided to rvlab_core as **clk_i** and **rst_ni**. Please do not use the alternative reset signal rst_dbg_ni outside the rvlab_debug module. Consult :ref:`clocks_resets` for details.

Components:

- **rvlab_cpu** -- contains the CV32E40P CPU implementing the RV32IMC instruction set
- **xbar_main** -- main crossbar switch (fast accesses)
- **xbar_peri** -- periphery crossbar switch (slower accesses)
- **student** -- module for exercises and project implementation
- **bram_main** -- main block RAM for instruction and data storage
- **rvlab_debug** -- contains the RISC-V debug module, and JTAG debug transport module, can interrupt CPU using non-maskable debug_req, provides direct system bus access (SBA) to debug host
- **rvlab_timer** -- simple timer module, can raise interrupt request irq_timer
- **regdemo** -- register generation demo module

The tl_ddr_i/tl_ddr_o and tl_ddr_ctrl_i/tl_ddr_ctrl_o ports connect to a DDR3 memory controller instantiated outside of rvlab_core.

To obtain the most accurate documentation of CV32E40P and OpenTitan for the purposes of the RISC-V Lab, please checkout the commits of CV32E40P and OpenTitan mentioned at :ref:`source_projects`. The latest online documentation of CV32E40P and OpenTitan may differ substantially from the used versions.

Student module
--------------

The student module is equipped with the following inputs / outputs:

- **tl_device_peri_i/tl_device_peri_o** -- TL-UL device port connected to xbar_peri
- **tl_device_fast_i/tl_device_fast_o** -- TL-UL device port connected to xbar_main
- **tl_host_i/tl_host_o** -- TL-UL host port connected to xbar_main
- **irq_o** -- interrupt output (level sensitive) connected to irq_external of the CPU
- **userio_i/userio_o** (types userio_board2fpga_t and userio_fpga2board_t) -- connects external hardware to student module, see :ref:`fpga_board`
