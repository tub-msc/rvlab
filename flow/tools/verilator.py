# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 RVLab Contributors

import subprocess
import shlex
import re
from pathlib import Path
from typing import Optional, List, Dict
import os
import sys

def find_verilator_executable() -> List[str]:
    """Find Verilator executable, handling Windows/MSYS2 environment"""
    if sys.platform == "win32":
        # Windows/MSYS2: verilator is a Perl script
        # Try to find perl and verilator script
        perl_exe = None
        verilator_script = None
        
        # Look for MSYS2 perl
        mingw_prefix = os.getenv('MINGW_PREFIX')
        if mingw_prefix:
            # Typical MSYS2 path: /mingw64/bin/perl.exe or /usr/bin/perl.exe
            potential_perl = Path(mingw_prefix) / "bin" / "perl.exe"
            if potential_perl.exists():
                perl_exe = str(potential_perl)
            else:
                # Try parent/usr/bin
                potential_perl = Path(mingw_prefix).parent / "usr" / "bin" / "perl.exe"
                if potential_perl.exists():
                    perl_exe = str(potential_perl)
        
        # Look for verilator script
        if mingw_prefix:
            potential_verilator = Path(mingw_prefix) / "bin" / "verilator"
            if potential_verilator.exists():
                verilator_script = str(potential_verilator)
        
        if perl_exe and verilator_script:
            return [perl_exe, verilator_script]
        else:
            # Fallback to just "verilator" and hope it's in PATH
            print("Warning: Could not find MSYS2 Perl or Verilator script, using 'verilator' from PATH")
            return ["verilator"]
    else:
        # Unix-like systems
        return ["verilator"]

def compile(
        src_files: List[Path],
        cwd: Optional[Path] = None,
        include_dirs: Optional[List[Path]] = None,
        defines: Optional[Dict[str, str]] = None,
        timescale: str = "1ps/1fs",
        top_modules: Optional[List[str]] = None,
        unisims_dir: Optional[Path] = None):
    """Compile Verilog sources with Verilator"""
    if cwd is None:
        cwd = Path.cwd()
    if unisims_dir is None:
        raise ValueError("unisims_dir must be provided for Verilator simulation")
    
    # Initialize mutable defaults
    include_dirs = include_dirs or []
    defines = defines or {}
    top_modules = top_modules or ["top"]
    
    # Validate top_modules
    if not top_modules:
        raise ValueError("top_modules list cannot be empty")
    if len(top_modules) > 1:
        print(f"Warning: Multiple top modules provided: {top_modules}. Using first one: {top_modules[0]}")
    
    top_module = top_modules[0]  # Using the first top module as the primary one
    
    # Validate top_module is a safe identifier (basic check)
    # Verilog module names should be valid identifiers
    if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', top_module):
        raise ValueError(f"Invalid top module name: '{top_module}'. Must be a valid Verilog identifier.")

    # Deduplicate source files while preserving order
    seen = set()
    unique_src_files = []
    for src in src_files:
        src_str = str(src)
        if src_str not in seen:
            seen.add(src_str)
            unique_src_files.append(src)
    if len(unique_src_files) != len(src_files):
        print(f"Warning: Removed {len(src_files) - len(unique_src_files)} duplicate source files")

    verilator_opts = [
        '-y', str(unisims_dir),
        '--Wno-fatal',
        '--Wno-EOFNEWLINE',
        '--bbox-unsup',  # Blackbox modules with unsupported constructs like 'deassign'
        '--bbox-sys',    # Blackbox unknown $system calls
        '--timing',
        '--binary',
        '--trace',
        '--main',
        '--exe',
        '--cc',
        '--top-module', top_module,
        '--timescale', f"{timescale}",
    ]

    # Validate defines keys for safety
    # Define keys should be valid C/Verilog identifiers
    define_pattern = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]*$')
    for key, value in defines.items():
        if not define_pattern.match(key):
            raise ValueError(f"Invalid define key: '{key}'. Must be a valid identifier.")
        # Value can be any string, safe with subprocess and list arguments
        verilator_opts += [f"-D{key}={value}"]

    for include_dir in include_dirs:
        verilator_opts += [f"-I{include_dir}"]

    verilator_opts += [str(src) for src in unique_src_files]

    # Get verilator command
    verilator_cmd = find_verilator_executable()
    
    full_cmd = verilator_cmd + verilator_opts
    print(f"Running Verilator compile command:\n{shlex.join(full_cmd)}")
    subprocess.check_call(full_cmd, cwd=cwd)  # nosec: B603 - using list arguments, not shell=True

    # Build the simulation
    executable_basename = f"V{top_module}"
    make_cmd = ["make", "-j", "-C", "obj_dir", "-f", f"{executable_basename}.mk", executable_basename]
    print(f"Building Verilator simulation:\n{shlex.join(make_cmd)}")
    subprocess.check_call(make_cmd, cwd=cwd)  # nosec: B603 - using list arguments, not shell=True

def simulate(
        src_files: List[Path],
        top_modules: List[str],
        unisims_dir: Path,
        cwd: Optional[Path] = None,
        include_dirs: Optional[List[Path]] = None,
        defines: Optional[Dict[str, str]] = None,
        wave_do: Optional[Path] = None,  # Unused, kept for API compatibility
        sdf: Optional[Dict[str, Path]] = None,  # Unused, kept for API compatibility
        vcd_out: Optional[Path] = None,
        saif_out: Optional[Path] = None,  # Unused, kept for API compatibility
        log_all: bool = False,  # Unused, kept for API compatibility
        run_on_start: bool = True,  # Unused, kept for API compatibility
        batch_mode: bool = False,  # Unused, kept for API compatibility
        timescale: str = "1ps/1fs",
        plusargs: Optional[Dict[str, str]] = None,
        netlist_sim = None,  # Unused, kept for API compatibility
        libs: Optional[List] = None,  # Unused, kept for API compatibility
        hide_mig_timingcheck_msg: bool = False,  # Unused, kept for API compatibility
        ):
    """Run simulation with Verilator"""
    if cwd is None:
        cwd = Path.cwd()
    
    # Initialize mutable defaults
    include_dirs = include_dirs or []
    defines = defines or {}
    plusargs = plusargs or {}
    # Note: _sdf and _libs are unused but kept for API compatibility
    
    # Validate top_modules before compilation
    if not top_modules:
        raise ValueError("top_modules list cannot be empty")
    top_module = top_modules[0]
    
    # Validate top_module is a safe identifier (basic check)
    # Verilog module names should be valid identifiers
    if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', top_module):
        raise ValueError(f"Invalid top module name: '{top_module}'. Must be a valid Verilog identifier.")

    # Compile and build with Verilator
    compile(src_files, cwd, include_dirs, defines, timescale, top_modules, unisims_dir)

    executable_basename = f"V{top_module}"
    executable_path = Path(cwd) / "obj_dir" / executable_basename

    if sys.platform == "win32":
        executable_path = executable_path.with_suffix(".exe")

    if not executable_path.exists():
        raise FileNotFoundError(f"Verilator simulation executable {executable_path} not found.")

    # Build command line with plusargs
    sim_cmd = [str(executable_path)]
    
    # Validate plusargs keys and values for safety
    # Plusargs should be simple identifiers and values
    plusarg_pattern = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]*$')
    for key, value in plusargs.items():
        if not plusarg_pattern.match(key):
            raise ValueError(f"Invalid plusarg key: '{key}'. Must be a valid identifier.")
        # Value can be any string, but we'll check it doesn't contain shell metacharacters
        # when used with subprocess.run() with list arguments, it's safe
        sim_cmd.append(f"+{key}={value}")

    # Add VCD dump if requested
    if vcd_out:
        sim_cmd.append("+vcd")

    print(f"Running Verilator simulation command:\n{shlex.join(sim_cmd)}")
    try:
        result = subprocess.run(  # nosec: B603 - using list arguments, not shell=True
            sim_cmd,
            cwd=cwd,
            text=True,
            check=True
        )
        print(f"Verilator simulation completed successfully (return code {result.returncode}).")
        if vcd_out:
            # The default trace file from Verilator's --main is trace.vcd in the CWD.
            default_vcd = cwd / "trace.vcd"
            if default_vcd.is_file():
                vcd_out.parent.mkdir(parents=True, exist_ok=True)
                default_vcd.rename(vcd_out)
                print(f"VCD trace file moved to {vcd_out}")
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Verilator simulation failed with return code {e.returncode}.", file=sys.stderr)
        raise
    except FileNotFoundError:
        print(f"ERROR: Verilator simulation executable not found.", file=sys.stderr)
        raise