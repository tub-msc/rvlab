# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 RVLab Contributors

import subprocess
import shlex
import re
from pathlib import Path
from typing import Optional
import os
import sys

def xilinx_sources(unisim_src_dir: Path) -> list[Path]:
    return [
        unisim_src_dir / "glbl.v",
        unisim_src_dir / "unisims/OBUFDS.v",
        unisim_src_dir / "unisims/IBUFDS.v",
        unisim_src_dir / "unisims/FDRE.v",
        unisim_src_dir / "unisims/BUFGCE.v",
        unisim_src_dir / "unisims/IOBUF.v",
        unisim_src_dir / "unisims/BUFG.v",
        unisim_src_dir / "unisims/MMCME2_BASE.v",
        unisim_src_dir / "unisims/MMCME2_ADV.v",
    ]

def compile(
        src_files: list[Path],
        cwd: Path,
        include_dirs: list[Path],
        defines: dict[str, str],
        timescale: str,
        top_module):
    """Compile Verilog sources with Verilator"""
    verilator_opts = [
        '--Wno-fatal',
        '--Wno-EOFNEWLINE',
        '--bbox-unsup',  # Blackbox unsupported constructs like 'deassign'
        '--timing',
        '--binary',
        '--trace',
        '--main',
        '--exe',
        '--cc',
        '--top-module', top_module,
        '--timescale', timescale,
    ]

    verilator_opts += [f"-D{key}={value}" for key, value in defines.items()]
    verilator_opts += [f"-I{include_dir}" for include_dir in include_dirs]
    verilator_opts += [str(src) for src in src_files]

    full_cmd = ['verilator'] + verilator_opts
    print("Running Verilator compile command:")
    print(shlex.join(full_cmd))
    subprocess.check_call(full_cmd, cwd=cwd)

    # Build the simulation 
    make_cmd = ["make", "-j", "-C", "obj_dir", "-f", f"V{top_module}.mk", f"V{top_module}"]
    print("Building Verilator simulation:")
    print(shlex.join(make_cmd))
    subprocess.check_call(make_cmd, cwd=cwd)

def simulate(
        src_files: list[Path],
        top_modules: list[str],
        cwd: Optional[Path] = None,
        include_dirs: Optional[list[Path]] = None,
        defines: dict[str, str] = {},
        wave_do: Optional[Path] = None,  # Unused, kept for API compatibility
        sdf: Optional[dict[str, Path]] = None,  # Unused, kept for API compatibility
        vcd_out: Optional[Path] = None,
        batch_mode: bool = False,  # Unused, kept for API compatibility
        timescale: str = "1ps/1fs",
        plusargs: dict[str, str] = {},
        libs: Optional[list] = None,  # Unused, kept for API compatibility
        ):
    """Run simulation with Verilator"""

    if len(top_modules) > 1:
        raise Exception("Verilator supports only a single top-level module at the moment.")
    top_module = top_modules[0]

    # Compile and build with Verilator
    compile(src_files, cwd, include_dirs, defines, timescale, top_module)

    executable_path = Path(cwd) / "obj_dir" / f"V{top_module}"

    if not executable_path.exists():
        raise FileNotFoundError(f"Verilator simulation executable {executable_path} not found.")

    sim_cmd = [str(executable_path)]
    sim_cmd += [f"+{key}={value}" for key, value in plusargs.items()]

    if vcd_out:
        sim_cmd.append("+vcd")

    print("Running Verilator simulation command:")
    print(shlex.join(sim_cmd))
    subprocess.check_call(sim_cmd, cwd=cwd)
    if vcd_out:
        # The default trace file from Verilator's --main is trace.vcd in the CWD.
        default_vcd = cwd / "trace.vcd"
        if not default_vcd.is_file():
            raise FileNotFoundError(f"Expected output file {default_vcd} not found.")
        vcd_out.parent.mkdir(parents=True, exist_ok=True)
        default_vcd.rename(vcd_out)
        print(f"VCD trace file moved to {vcd_out}")
