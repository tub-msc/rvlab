.. _setup:

Setup
=====

This page describes the tool setup required to work with rvlab. **No setup is required when working with the university lab computers.**
It has been tested on Xubuntu 22.04.

Support status
--------------

Supported simulators:

+-------------------------------------------+-----------------+--------------+--------------------------+
| Step                                      | Vivado XSim     | Questa-Intel | Full Questa (university) |
+===========================================+=================+==============+==========================+
| RTL simulation                            | supported       | supported    | supported                |
+-------------------------------------------+-----------------+--------------+--------------------------+
| Post-synthesis functional simulation      | supported       | (supported)  | supported                |
+-------------------------------------------+-----------------+--------------+--------------------------+
| Post-synthesis timing simulation          | timing mismatch | (supported)  | supported                |
+-------------------------------------------+-----------------+--------------+--------------------------+
| Post-implementation functional simulation | supported       | (supported)  | supported                |
+-------------------------------------------+-----------------+--------------+--------------------------+
| Post-implementation timing simulation     | timing mismatch | (supported)  | supported                |
+-------------------------------------------+-----------------+--------------+--------------------------+

Icarus with sv2v for simulation is currently not supported, but could be added in the future.

For synthesis and place and route, only Xilinx Vivado is supported.

**Timing mismatch problem with Vivado XSim:** SDF annotation does not work properly with Vivado XSim at the moment. For example, observe difference in the delay from TCK (FPGA input) falling edge to TDO (FPGA output) falling/rising edge between Questa and XSim. Debugging this further showed that */rvlab_fpga_top/tdo_flop_i* CQ delay is not properly annotated. Make sure to use *-debug all* and *-v 2* options for xelab or debugging. Debug output shows that the timing values of the library are overridden, when they are in fact not. A minimal test case should be created and submitted to Xilinx. With Questa, timing annotation works properly. The recommended *-sdf_anno true* switch to *write_verilog* in Vivado does not change the simulator behavior in this regard.

Install open-source components
------------------------------

Make sure you have a recent Python version (3.10+?) installed.

Install pip and libraries required by Vivado as Debian / Ubuntu packages::
    
    sudo apt-get install python3-pip libtinfo6 libtinfo5 libtinfo-dev

Install Python dependencies, including PyDesignFlow_  and NoTcl_, using pip (likely, this needs to be done in the context of a `Python virtual environment <https://docs.python.org/3/library/venv.html>`_)::

    pip install -r requirements.txt

.. _PyDesignFlow: https://github.com/TobiasKaiser/pydesignflow
.. _NoTcl: https://github.com/TobiasKaiser/notcl

Add the flow executable to the search PATH:

.. code-block:: bash

    # Execute in every new shell before starting the flow.
    export PATH=~/.local/bin:$PATH

As RISC-V tool chain, we recommend to use precompiled gcc binaries from riscv-none-elf-gcc-xpack_. To make the binaries accessible, unpack the archive somewhere and add the *bin/* sub directory to the *PATH* environment variable.

.. _riscv-none-elf-gcc-xpack: https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/

If you wan to use the linter, we recommend to use precompiled gcc binaries from verible_. To make the binaries accessible, unpack the archive somewhere and add the *bin/* sub directory to the *PATH* environment variable.

.. _verible: https://github.com/chipsalliance/verible/releases


Install Xilinx Vivado (proprietary)
-----------------------------------

Install Xilinx Vivado ML Edition 2022.2 Standard (Free Version) from the `Xilinx Download Center <https://www.xilinx.com/support/download.html>`_. You need to create a free Xilinx account for downloading and during installation, but no license is required. (The free version sends some metadata to Xilinx during usage.) I recommend the web-based installer instead of the full download (80+ GB). Instructions for the installer:

1. *"Select Product to Install"* → Vivado
2. *"Select Edition to Install"* → Vivado ML Standard
3. *"Customize your installation"* → Select at least:
  
   - "Design Tools → Vivado Design Suite → Vivado",
   - "Design Tools → DocNav", and
   - "Devices → Production Devices → 7 Series".

During installation Vivado generates an installation dependent script settings64.sh which needs to be sourced. For the flow to find the FPGA library sources and binaries the XILINX_VIVADO and PATH variables need to be set, respectively:

.. code-block:: bash

    # Execute in every new shell before starting the flow.
    # Adapt the paths for your installation.
    ~/bin/Xilinx/Vivado/2022.2/settings64.sh
    export XILINX_VIVADO=~/bin/Xilinx/Vivado/2022.2
    export PATH=~/bin/Xilinx/Vivado/2022.2/bin:$PATH

Install Questa-Intel (proprietary)
----------------------------------

Intel offers `Questa-Intel`_ Starter FPGA edition, a free version of the QuestaSim SystemVerilog simulator. QuestaSim is the preferred simulator for rvlab, but XSim, included in Vivado, can also be used. To run Questa-Intel on Linux, you need to register an Intel account and generate a free license for your computer using its MAC address. In order for Questa-Intel to find the license file you need to create a shell variable to point to the license file you received from Intel. Furthermore for the flow Questa-Intel needs to be added to the search path:

.. code-block:: bash

    # Execute in every new shell before starting the flow.
    # Adapt the paths for your installation.
    export LM_LICENSE_FILE=~/bin/intelFPGA_pro/LR-113703_License.dat
    export PATH=~/bin/intelFPGA_pro/22.4/questa_fse/bin:$PATH

Its main limitation seems to be a limit of 5000 module instances during simulation. This seems to be more than sufficient for rvlab RTL simulation, which presently uses around 195 instances. Netlist simulation is (probably?) not possible due to the limitation. The following TCL command in QuestaSim supposedly counts the number of module instances during simulation::

    llength [find instances -recursive /*]

.. _Questa-Intel: https://www.intel.de/content/www/de/de/software/programmable/quartus-prime/questa-edition.html


Example Setup
-------------
With

- Xilinx installed in ~/bin/Xilinx
- Intel-Questa installed in ~/bin/intelFPGA_pro
- RISC-V tool chain unpacked into ~/bin/riscv
- Verible unpacked into ~/bin/verible

Content of ~/bin/rvlab.sh combining all previous shell scripts of this page:

.. code-block:: bash

    export LM_LICENSE_FILE=~/bin/intelFPGA_pro/LR-231294_License.dat
    ~/bin/Xilinx/Vivado/2022.2/settings64.sh
    export XILINX_VIVADO=~/bin/Xilinx/Vivado/2022.2
    export PATH=~/.local/bin:~/bin/intelFPGA_pro/22.4/questa_fse/bin:~/bin/riscv/bin:~/bin/Xilinx/Vivado/2022.2/bin:~/bin/verible/bin:$PATH

In a new shell execute::

    . ~/bin/rvlab.sh

to setup the rvlab environment.


