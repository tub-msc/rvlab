DDR3 Memory
===========

The Nexys Video board comes with 512 MiB of DDR3 memory.

The Open-Source DDR3 Controller 'UberDDR3' is used for interfacing.
It is connected to a 256-bit wide 512-entry (16KiB) direct-mapped last-level cache, which uses a 256-bit-wide bus protocol loosely based on TileLink.
The 256-bit cache is wrapped by a TL-UL adapter to work with the rest of the SoC; if projects require a higher bandwidth, this adapter can be removed.

The RTL source files for the controller can be found in *src/rtl/ddr3*. They also include a prefetch buffer which increases performance, which can be removed if necessary.
The custom, TL-UL based bus protocol is located at *src/rtl/ddr3/pkg/rvlab_ddr_pkg.sv*.

To speed up RTL simulation, the DDR3 Memory Interface is not included in RTL simulations by default. It is however always used in synthesis and therefore always present in netlist simulations.
It can be included in system and module testbench RTL simulations anyway by using the `.sim_rtl_questa_ddr` task on the corresponding PyDesignFlow blocks.
