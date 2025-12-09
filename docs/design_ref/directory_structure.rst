.. _directory_structure:

Directory Structure
===================

- **/docs** -- documentation sources (Sphinx)
- **/flow** -- see :ref:`design_flow`
- **/src** -- hardware + software sources

  - **/src/tb** -- Testbench code for Functional Verification (SystemVerilog)
  - **/src/rtl** -- FPGA register-transfer-level (RTL) design sources (SystemVerilog) 

    - **/src/rtl/rvlab_fpga** -- rvlab main sources
    - **/src/rtl/student** -- Student directory for exercise and project code
    - **/src/rtl/ibex** -- `Ibex <https://github.com/lowRISC/ibex>`_ CPU code
    - **/src/rtl/inc** -- SystemVerilog globally available includes
    - **/src/rtl/prim** -- SystemVerilog synthesizable primitives 
    - **/src/rtl/rv_dm** -- RISC-V debug module, derived from PULP's `riscv-dbg <https://github.com/pulp-platform/riscv-dbg>`_
    - **/src/rtl/rv_timer** -- RISC-V timer `rv_timer <https://github.com/lowRISC/opentitan/tree/master/hw/ip/rv_timer>`_ from OpenTitan
    - **/src/rtl/tlul** -- TL-UL bus components
    
  - **/src/design** -- Miscellaneous design input files
    
    - **/src/design/ip** -- Config file *mig_a.prj* for Xilinx DDR3 IP and *design.txt* for DDR3 simulation.
    - **/src/design/openocd** -- Config file for `OpenOCD <https://openocd.org/>`_ used for JTAG connection and debug on FPGA.
    - **/src/design/pincheck** -- CSV file to check design I/Os before bitstream generation
    - **/src/design/reggen** -- Input HJSON files for register generation (SystemVerilog + C headers)
    - **/src/design/tlgen** -- Input HJSON files for crossbar (xbar) switch generation (SystemVerilog)
    - **/src/design/wave** -- QuestaSim wave window configuration files
    - **/src/design/xdc** -- Xilinx design constraints for FPGA implementation
  
  - **/src/sw** -- see :ref:`software`
    
