.. _`design_flow`:

Design Flow Recipes
===================

The design flow uses `PyDesignFlow <https://pydesignflow.readthedocs.io/>`_. To build task T of block B, run the following command in the *rvlab/* folder::

    flow B.T

For example, to run RTL simulation using XSIM::

    flow rvlab_tb_minimal.sim_rtl_xsim

When a target such as *rvlab_tb_minimal.sim_rtl_xsim* is requested, missing targets on which it depends are also built automatically. **Existing dependencies are not re-built, regardless of whether they are up-to-date or not**, unless you invoke :code:`flow`  the :code:`-R` flag.

Running :code:`flow` without arguments shows a list of all flow targets and their current build status. Build results are placed in the *build/* subdirectory and are thus strictly separated from user-defined source files.

To remove all build results, run :code:`flow --clean` or delete the *build/* folder.

Module Simulation
-----------------

Simulate *rlight_tb* module-level testbench::

    flow rlight_tb.sim_rtl_questa

System Simulation
-----------------

RTL system simulation with "student" program running on the system::

    flow sw_student.build
    flow systb_student.sim_rtl_questa

To run other programs on the system, replace **student** with the name of the desired program (see :ref:`software` for available programs and how to add more programs). For example, to run the test_rvlab program, run::

    flow sw_test_rvlab.build
    flow systb_test_rvlab.sim_rtl_questa

By default, RTL (= pre-synthesis) system simulation excludes the DDR3 memory and corresponding memory controller to speed up simulation. Use the *sim_rtl_questa_ddr* target in the rare case that you need to include the DDR3 memory in your simulation.

.. _`synthesis_tutorial`:

FPGA Implementation (Synthesis, Place and Route)
------------------------------------------------

**Check design before implementation:** Before you synthesize your design, please make sure that you only use synthesizable code as described in the SystemVerilog crash course.
Make sure that no warnings occur during compilation or design loading when you run system simulation with :code:`flow systb_student sim_rtl_questa`.
Furthermore, it is recommended to run :code:`flow srcs lint` to detect some common SystemVerilog design mistakes.
It is much easier to debug hardware problems in the early RTL design stage than later in netlist simulation or in hardware!

Before you go ahead with FPGA implementation, delete any previous implementation results::

    flow rvlab_fpga_top --clean

To start synthesis, run the following commond::

    flow rvlab_fpga_top.syn

Check the reports generated in */build/rvlab_fpga_top/syn*:

- *rvlab_fpga_top.qor_assessment.txt* -- checks overall quality of results, should list status "OK" for utilization, clocking, congestion and timing
- *rvlab_fpga_top.timing_summary.txt* -- somewhat detailed timing summary, should show zero "TNS Failing Endpoints" under "Design Timing Summary". After synthesis, a few hold violations are expected to occur ("THS Failing Endpoints" not zero). After place & route, all hold violations should be resolved and the report should show "All user specified timing constraints are met."
- *rvlab_fpga_top.methodology.txt* -- lists potential methodologic problems in the design, should show "Violations found: 0"
- *rvlab_fpga_top.drc.txt* -- lists potential design rule check errors or warnings, show show no errors or warnings except for CHECK-1 warning ("Report disabled checks") 
- *rvlab_fpga_top.utilization.txt* -- lists the design's FPGA resource usage

To run place-and route::

    flow rvlab_fpga_top.pnr

After place-and-route, check the new reports generated in */build/rvlab_fpga_top/pnr*.
If the reports look good, continue with :ref:`netlist_sim`.

To generate a bitstream from the place and route result, run::

    flow rvlab_fpga_top.bitstream

The :ref:`fpga_upload` tutorial describes how to load bitstream and software into the FPGA.

.. _`netlist_sim`:

Netlist Simulation
------------------

To run post-implementation netlist simulation with the student software running on the system::

    flow systb_student.sim_pnrtime_questa

Adding module-level testbenches
-------------------------------

With *rlight_tb*, only a single module-level testbench is predefined. To add an additional module-level testbench, place the SystemVerilog testbench code in */src/tb* and register the new testbench in the *module_tbs* list defined in  */flow/__init__.py*, for example::

    module_tbs = [
        "rlight_tb",
        "mynewmodule_tb",
    ]

Extending the crossbar switches
-------------------------------

You can add more host or device ports to the two predefined crossbar switches *xbar_main* and *xbar_peri*.

For a new host port *myhost* to *xbar_main*, add the following code to the list of nodes::

    { 
        name: "myhost"
        type: "host"
        pipeline: "true"
    }

You also need to add the desired connections to the *connection* dictionary below::

    myhost: ["bram_main", "peri", "ddr", "student_device_fast"]

A new TL-UL device *mydevice* can be added to the node list of either *xbar_main* or *xbar_peri* with following code::

    {
        name: "mydevice"
        type: "device"
        pipeline: "true"
        addr_range: [{base_addr: "0x40000000", size_byte: "0x10000000"}]
    }   

Make sure that the specified address range does not overlap with other devices and, in case *xbar_peri* is extended, the address range lies in the periphery region 0x10000000 - 0x20000000.

Devices also need to be added to the *connection* dictionary, for example::

    connections: {
        corei:        ["bram_main", "peri", "ddr", "student_device_fast", "mydevice"]
        cored:        ["bram_main", "peri", "ddr", "student_device_fast", "mydevice"]
        dbgsba:       ["bram_main", "peri", "ddr", "student_device_fast", "mydevice"]
        student_host: ["bram_main", "peri", "ddr", "student_device_fast", "mydevice"]
    }

After changes to the crossbar configuration are made, regenerate crossbar source files with :code:`flow xbar.generate` and connect the new ports in */src/rtl/rvlab_fpga/rvlab_fpga_top.sv*.

Behind the scenes
-----------------

This list outlines the Python sources located in the */flow* directory:

- **/flow/__init__.py** -- design flow setup, instantiates the blocks that are defined in the other Python files in this directory, contains (extensible) list of programs and list of testbenches
- **/flow/tools** -- encapsulates tools used in the design flow

  - **/flow/tools/vivado.py** -- makes Vivado functionality accessible in Python via `NoTcl <https://notcl.readthedocs.io/en/latest/>`_
  - **/flow/tools/build_sw.py** -- provides a simple Python interface for building RISC-V ELF binaries and static libraries from C code using GCC
  - **/flow/tools/elf2mem.py** -- converts RISC-V ELF binaries to full memory images (sw.mem files) and differential images (delta files)
  - **/flow/tools/openocd.py** -- loads RISC-V ELF binaries into FPGA system using OpenOCD and connects stdout/stdin to host system (see :ref:`host_io`)
  - **/flow/tools/pincheck.py**  -- checks design pinout before bitstream generation
  - **/flow/tools/questasim.py** -- provides a simple Python interface for QuestaSim
  - **/flow/tools/xsim.py** -- provides a simple Python interface for XSim, the simulator that ships with Vivado
  - **/flow/tools/reggen** -- sources copied from OpenTitan's reggen
  - **/flow/tools/reggen_wrapper.py** -- custom wrapper for reggen
  - **/flow/tools/reggen_sphinx_ext.py** -- automatically generates register documentation for Sphinx using reggen_wrapper
  - **/flow/tools/tlgen** -- sources copied from OpenTitan's tlgen
  - **/flow/tools/tlgen_wrapper.py** -- custom wrapper for tlgen

- **/flow/reggen.py** -- defines the RegisterGenerator Block
- **/flow/xbar.py** -- defines the XbarGenerator Block
- **/flow/sw.py** -- defines the Program and Libsys Blocks
- **/flow/sources.py** -- defines Sources block
- **/flow/module_tb.py** -- defines the ModuleTb block used for module testbench simulations
- **/flow/system_tb.py** -- defines the SystemTb Block used for system testbench simulations
- **/flow/rvlab_mig.py** -- defines the RvlabMig Block used for generating the Xilinx Memory Interface generator (MIG) IP block
- **/flow/simlibs_questa.py** -- defines the SimlibsQuesta Block to build Xilinx simulation libraries for QuestaSim
