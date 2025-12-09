.. _resources:

Resources
=========

Xilinx Hardware & Design Tools
------------------------------
- `7 Series Product Tables and Product Selection Guide (XMP101) <https://docs.xilinx.com/v/u/en-US/7-series-product-selection-guide>`_: The last page contains links to the most important user guides (CLBs, rams, DSPs, IOs, ...)
- `Vivado Design Suite User Guide: Synthesis (UG901) <https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis>`_: HDL templates for inferring block rams (inferring as (simpler) alternative to instantiate library primitives). Only works for Vivado.
- `Vivado Design Suite 7 Series FPGA and Zynq-7000 SoC Libraries Guide UG953 (v2021.2) October 22, 2021 <https://www.xilinx.com/content/dam/xilinx/support/documents/sw_manuals/xilinx2021_2/ug953-vivado-7series-libraries.pdf>`_: Instance templates for all library primitives
- `Vivado Design Suite Tcl Command Reference Guide (UG835) <https://docs.xilinx.com/r/en-US/ug835-vivado-tcl-commands>`_
- `Vivado Design Suite Properties Reference Guide (UG912) <https://docs.xilinx.com/r/en-US/ug912-vivado-properties>`_

Digilent Nexys Video FPGA Board
-------------------------------

- `Nexys Video Reference Manual <https://digilent.com/reference/programmable-logic/nexys-video/reference-manual>`_
- `Nexys Video schematic <https://digilent.com/reference/_media/reference/programmable-logic/nexys-video/nexys_video_sch.pdf>`_

RISC-V System
-------------

- `RISC-V Reference card <https://github.com/jameslzhu/riscv-card>`_
- `RISC-V Instruction Set Manual Vol. I: Unprivileged ISA <https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf>`_
- `RISC-V Instruction Set Manual Vol. II: Privileged ISA <https://github.com/riscv/riscv-isa-manual/releases/download/Priv-v1.12/riscv-privileged-20211203.pdf>`_
- `TileLink Spec <https://starfivetech.com/uploads/tilelink_spec_1.8.1.pdf>`_

- OpenTitan's `Reggen manual <https://opentitan.org/book/util/reggen/index.html>`_ (differs in details from the version used in rvlab!)
- OpenTitan's `Crossbar Generation tool manual <https://opentitan.org/book/util/tlgen/index.html>`_ (differs in details from the version used in rvlab!)

- `Ibex Documentation <https://ibex-core.readthedocs.io/en/latest/index.html>`_

SystemVerilog
-------------

- `Verilog Language reference manual (LRM) <https://ieeexplore.ieee.org/document/8299595>`_ (the authoritative source to consult for in depth questions, e.g. how a certain language element is to be handeled by a simulator).
- `Learn FPGA from BrunoLevy <https://github.com/BrunoLevy/learn-fpga>`_

  - The tutorial `From Blinky to RISC-V <https://github.com/BrunoLevy/learn-fpga/tree/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV>`_ starts with the Verilog of a single blinking LED and extends this step by step ending with a minimal but functional RISC-V core (running DOOM!). Verilog, but can be easily adapted to SystemVerilog.

External IP
-----------

Could be useful (i.e. no guarantee) for student projects.

Built in previous rvlabs:

- HDMI input

  - rvlab 2024 project: `DVI/HDMI input for the Artix-7 FPGA with TileLink interface <https://github.com/JnCrMx/fpga-dvi-hdmi-input>`_  
  - Xilinx application note explaining basic concept: `Implementing a TMDS Video Interface in the Spartan-6 FPGA <https://docs.amd.com/v/u/en-US/xapp495_S6TMDS_Video_Interface>`_ 

External:

- GBit Ethernet MAC (used in rvlab 2023): `verilog-ethernet <https://github.com/alexforencich/verilog-ethernet>`_

- HDMI output 

  - basic explanation & (overly simplified - do not use) implementation: `fpga4fun <https://www.fpga4fun.com/HDMI.html>`_
  - DVI only, no sound: `display_controller <https://github.com/projf/display_controller>`_
  - HDMI, with sound: `hdmi <https://github.com/hdl-util/hdmi>`_
