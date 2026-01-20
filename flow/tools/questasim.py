# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

import subprocess
from notcl import TclTool, tclobj
from pathlib import Path
import os

class Vsim(TclTool):
    def __init__(self, sdf, libs, plusargs, top_modules, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.vsim_opts = []
        self.vsim_opts += ["-onfinish", "stop"]

        #self.vsim_opts += ['-v2k_int_delays']
        self.vsim_opts += ['+transport_int_delays']
        self.vsim_opts += ["-voptargs=\"+acc\""]
        for key, value in sdf.items():
            self.vsim_opts += ["-sdfmin", f"{key}={value}"]
            self.vsim_opts += ["-sdfmax", f"{key}={value}"]

        # ** Warning: (vsim-SDF-16107) [...]/rvlab_fpga_top.sdf(180988): The interconnect '/system_tb/DUT/storage_reg_0_3_6_11_i_6/O' is not connected to the destination '/system_tb/DUT/\core_i/debug_i/u_dm_top/dap/i_dmi_cdc/i_cdc_resp/storage_reg_0_3_6_11 /RAMC/I'.
        # The interconnect request will be replaced with a port annotation at the destination.
        self.vsim_opts += ['-suppress', '16107']

        # ** Error (suppressible): (vopt-14408) Intel Starter FPGA Edition recommended capacity is 5000 non-OEM instances. There are 15747 non OEM instances. Expect performance to be severely impacted. 
        self.vsim_opts += ['-suppress', '14408'] 
        
        # ** Error (suppressible): (vsim-SDF-3262) [...]/rvlab_fpga_top.sdf(257181): Failed to find matching specify timing constraint.
        self.vsim_opts += ['-suppress', '3262'] 


        for l in libs:
            self.vsim_opts += ['-L', l]

        for key, val in plusargs.items():
            self.vsim_opts += [f"+{key}={val}"]
        
        self.vsim_opts += [m for m in top_modules]

        if not self.interact:
            self.vsim_opts += ["-batch"]


    def cmdline(self):
        return ["vsim"] + self.vsim_opts + ["-do", self.script_name()]

def simulate(
        src_files: list[Path],
        top_module: str,
        cwd: Path=None,
        include_dirs: list[Path]=[],
        defines: dict[str,str]={},
        wave_do: Path=None,
        sdf: dict[str,Path]={},
        vcd_out: Path=None,
        saif_out: Path=None,
        log_all: bool=False,
        run_on_start: bool=True,
        batch_mode: bool=False,
        timescale: str="1ps/1fs",
        plusargs: dict[str,str]={},
        libs: list=[],
        hide_mig_timingcheck_msg:bool=False,
        ):
    """
    Args:
        src_files: List of Verilog / SystemVerilog source files
        top_module: Name of the top module to simulate
        cwd: Change working directory
        include_dirs: List of all include directories (search paths)
        defines: Dictionary of defines
        wave_do: Tcl file executed after loading the system for automatically
            adding signals to the wave view window.
        sdf: Delay annotation using SDF file.
            Example: {'/DUT':'/path/to/file.sdf'} 
        vcd_out: If set, a full value change dump (VCD) activity file will
            be saved to the specified file.
        saif_out: Output SAIF file or None.
        log_all: Log signals even if they are not shown in the wave view.
        run_on_start: Start simulation immediately.
        batch_mode: If True, run in batch mode instead of GUI.
        plusargs: Parameters passed to simulation,
            accessible via $value$plusargs in SystemVerilog.
    """

    compile(src_files, cwd, 'work', include_dirs, defines, timescale)


    if not isinstance(wave_do, (list, tuple)):
        wave_do = [wave_do]

    with Vsim(sdf, libs, plusargs, top_module, cwd=cwd, interact=(not batch_mode)) as vsim:
        if vcd_out:
            vsim(f"vcd file {str(vcd_out)}")
            vsim("vcd add -r /*")
        #vsim.echo("Hello, world!")
        if not batch_mode:
            for dofile in wave_do: 
                if not dofile.exists():
                    with open(dofile, "x") as f:
                        f.write("\n")
                vsim.do(str(dofile))
            fn_enc = tclobj.encode(str(wave_do[-1])) # assumption: last dofile in list is the one containing the wave view

            vsim(f'add button "Save Wave Format" {{write format wave {fn_enc}; echo "Wave format saved to {fn_enc}."}} NoDisable {{-bg #0c0}}')

        if log_all: 
            vsim("add log -r *")

        if saif_out:
            vsim("power add -in -inout -internal -out /*")

        if hide_mig_timingcheck_msg:
            # Suppresses messages (at start of simulation), but keeps X generation.
            vsim('tcheck_set /board/DUT/tlul_ddr_i/mig_i -r "(PERIOD)" OFF ON')
            vsim('tcheck_set /board/DUT/tlul_ddr_i/mig_i -r "(HOLD)" OFF ON')
            vsim('tcheck_set /board/DUT/tlul_ddr_i/mig_i -r "(SETUP)" OFF ON')
            vsim('tcheck_set /board/DUT/tlul_ddr_i/mig_i -r "(WIDTH)" OFF ON')

        if run_on_start or batch_mode:
            vsim('run -a')

        if not batch_mode:
            vsim("view .main_pane.wave")

        if saif_out:
            vsim(f"power report -all -bsaif {str(saif_out)}")


def compile(
        src_files: list[Path],
        cwd: Path=None,
        lib_name: str="work",
        include_dirs: list[Path]=[],
        defines: dict[str,str]={},
        timescale: str="1ps/1fs"
        ):



    vlog_opts = [
        "+nowarnSVCHK",
        f"-timescale={timescale}",
        "-mfcu=macro",
        '-work', lib_name,
        "-svinputport=relaxed", # net, relaxed, var, compat 
        '-lint',
    ]

    # ** Error (suppressible): [...]/rvlab/src/rtl/rvlab_fpga/rvlab_fpga_top.sv(100): (vlog-7061) Variable 'locked_q' driven in an always_ff block, may not be driven by any other process. See [...]/rvlab/src/rtl/rvlab_fpga/rvlab_fpga_top.sv(117).
    vlog_opts += ['-suppress', '7061']

    # ** Warning: ** while parsing macro expansion: 'ASSERT_VALID_DATA' starting at [...]/tlul_assert.sv(273)
    # ** at [...]/tlul_assert.sv(273): (vlog-2643) Unterminated string literal continues onto next line.
    vlog_opts += ['-suppress', '2643']

    # ** Warning: [...]/glbl.v(6): (vlog-2605) empty port name in port list.
    vlog_opts += ['-suppress', '2605']

    # ** Warning: [...]/mig_7series_v4_2_rank_cntrl.v(327): (vlog-2573) Unconditional generate blocks are not permitted in Verilog 1364-2005.
    vlog_opts += ['-suppress', '2573']



    vlog_opts += [f"+incdir+{i}" for i in include_dirs]
    vlog_opts += [f"+define+{k}={v}" for k, v in defines.items()]

    vlog_opts += [str(fn) for fn in src_files]
    subprocess.check_call(["vlog"]+vlog_opts, cwd=cwd)

    return cwd / lib_name
