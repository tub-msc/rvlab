# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

import subprocess
from pathlib import Path
from notcl import TclTool
import os

def plusargs_to_str(plusargs: dict[str,str]) -> str:
    return "".join([f"{key}={value}" for key, value in plusargs.items()])

class Xsim(TclTool):
    def __init__(self, top_module:str, plusargs: dict[str,str], enable_gui:bool, **kwargs):
        super().__init__(**kwargs)
        self.enable_gui = enable_gui
        self.top_module = top_module
        self.plusargs = plusargs
    
    def cmdline(self):
        l = ["xsim",
            "--t", self.script_name(),
            self.top_module]
        if self.enable_gui:
            l += ["--gui"]
        if len(self.plusargs) > 0:
            l += ["--testplusarg", plusargs_to_str(self.plusargs)]
        return l

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
        libs=[]
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

    src_files_xvlog, src_files_xsc = split_sources(src_files)

    xvlog(src_files_xvlog, defines, include_dirs, cwd)
    
    simkernel_name = xelab(top_module, timescale, libs, sdf, cwd)
    
    abort_on_dpi = True

    if len(src_files_xsc) > 0:
        if abort_on_dpi:
            raise Exception("DPI sources found, but abort_on_dpi is enabled!")
        else:
            xsc(src_files_xsc, cwd)
    
    enable_gui=not batch_mode
    with Xsim(simkernel_name, plusargs, enable_gui=enable_gui, interact=enable_gui, cwd=cwd) as t:
        if saif_out:
            t.open_saif(saif_out)
            t.log_saif(t("get_objects -r /*"))
        if vcd_out:
            t.open_vcd(vcd_out)
            t.log_vcd(t("get_objects -r /*"))
        if wave_do and wave_do.exists():
            t.open_wave_config(wave_do)
        if log_all:
            t.log_wave("/*", recursive=True)
        if run_on_start:
            t.run(all=True)

def split_sources(src_files):
    """Splits src_files into .c files (DPI via xsc) and everything else (.sv, .v)"""
    src_files_xvlog = []
    src_files_xsc = []
    for fn in src_files:
        if str(fn).endswith(".c"):
            src_files_xsc.append(fn)
        else:
            src_files_xvlog.append(fn) 
    return src_files_xvlog, src_files_xsc

def xvlog(src_files_xvlog, defines, include_dirs, cwd):
    # xvlog throws mysterious errors if it encounters a SystemVerilog file after already
    # having processed Verilog files, so we must pass all SV files first and then the V files
    v_sources = []
    sv_sources = []
    for f in src_files_xvlog:
        if str(f).endswith('.v'):
            v_sources.append(f)
        else:
            sv_sources.append(f)
    src_files_xvlog = sv_sources + v_sources


    xvlog_opts = ['-sv']

    for i in include_dirs:
        xvlog_opts += ["-i", i]

    for key, value in defines.items():
        xvlog_opts += ["-d", f"{key}={value}"]

    subprocess.check_call(["xvlog"]+xvlog_opts+[str(fn) for fn in src_files_xvlog], cwd=cwd)
    

def xelab(top_module, timescale, libs, sdf, cwd):

    xelab_opts = []
    xelab_opts += ["--timescale", timescale]
    for l in libs:
        xelab_opts += ["-L", str(l)]


    xelab_opts += ['--maxdelay']
    # Make sure not to ['-pulse_r', '0'], ['-pulse_int_r', '0'] , as this breaks the Xilinx MIG 7.
    xelab_opts += ["-transport_int_delays"]

    for key, value in sdf.items():
        xelab_opts += ['--sdfmax', f'{key}={value}']
    
    #xelab_opts += ["--debug", "typical"]
    xelab_opts += ["--debug", "all"]
    
    try:
        multiple_tops = [m for m in top_module] # top_module can be a list of top modules
    except TypeError:
        xelab_opts += [top_module]
        simkernel_name = top_module
    else:
        # we cannot take multiple_tops[0] as simkernel_name, because:
        # When xelab encounters two identical argvs directly following each other,
        # it ignores the second one. (This is the case if we choose
        # multiple_tops[0] as simkernel_name.)
        simkernel_name = 'simk'
        xelab_opts += ['-s', simkernel_name] + multiple_tops
    subprocess.check_call(["xelab"]+xelab_opts, cwd=cwd)
    
    return simkernel_name

def xsc(src_files_xsc, cwd):
    if len(src_files_xsc) == 0:
        return

    xsc_opts = []
    for o in ["-I/usr/include/x86_64-linux-gnu/"]:
        xsc_opts += ["--gcc_compile_options", o]

    for o in ["-B/usr/lib/x86_64-linux-gnu/"]:
        xsc_opts += ["--gcc_link_options", o]

    xsc_opts += [str(fn) for fn in src_files_xsc]

    subprocess.check_call(["xsc"]+xsc_opts, cwd=cwd)
