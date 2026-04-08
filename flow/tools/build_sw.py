# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

import shutil
import shlex
import subprocess
from pathlib import Path
from .elf2mem import elf2mem

command = 'ls'
shutil.which(command) is not None

cfg_arch = "rv32imc_zicsr"
cfg_abi  = "ilp32"

def find_toolchain_prefix():
    # List of (prefix, zicsr_compat, needs_multilib_test)
    # riscv32 toolchains don't need multilib test - they're already 32-bit
    # riscv64 needs test to verify rv32 multilib support
    prefixes = [
        ("riscv32-unknown-elf-", True, False),
        ("riscv-none-elf-", True, False),
        ("riscv64-unknown-elf-", True, True),  # needs multilib test
        ("riscv-none-embed-", False, False),
    ]

    for prefix, zicsr_compat, needs_test in prefixes:
        if not shutil.which(f"{prefix}gcc"):
            continue

        # For riscv32 toolchains, no need to test - they support rv32 by definition
        if not needs_test:
            return prefix, zicsr_compat

        # For riscv64, check if rv32 multilib is available via -print-multi-lib
        try:
            result = subprocess.run(
                [f"{prefix}gcc", "-print-multi-lib"],
                capture_output=True, text=True
            )
            if result.returncode == 0 and "rv32" in result.stdout:
                return prefix, zicsr_compat
        except Exception as e:
            print(f"Warning: Could not check multilib for {prefix}: {e}")
            continue

    raise Exception("Could not find RISC-V GCC toolchain.")


def get_cflags(abi, arch, funciton_sections=True):
    o = [
        "-Wall",
        "-ffreestanding",
        "-fno-builtin",
        "-nostdlib",
        "-g",
        #"-msave-restore",
        #"-Wl,-gc-sections",
        "-Wl,-lgcc,--whole-archive",
        "-Os",
        f"-mabi={abi}",
        f"-march={arch}",
        "-DNO_UNISTD_H",  # Prevent inclusion of unistd.h in baselibc
    ]
    
    # Try to add --specs=nosys.specs if available, but don't fail if it's not
    # This flag is optional and some toolchains don't have it
    #if funciton_sections:
    #    o+=["-ffunction-sections"]
    return o

def build_static_lib(cwd, srcs: list[Path], output_a_filename:Path,
    arch: str=cfg_arch, abi: str=cfg_abi, include_system: list[Path]=[], include_quote: list[Path]=[]):
    
    prefix, zicsr_compat = find_toolchain_prefix()
    if not zicsr_compat and arch.endswith('_zicsr'):
        arch = arch.rsplit('_', 1)[0]

    cc_cmdline = [f"{prefix}gcc", "-c"] 
    cc_cmdline += list(map(str, srcs)) 
    for path in include_system:
        cc_cmdline += ["-isystem", str(path)]
    for path in include_quote:
        cc_cmdline += ["-iquote", str(path)]
    cc_cmdline += get_cflags(abi, arch, funciton_sections=False)
    print("Building static lib:\n\t", shlex.join(cc_cmdline))
    subprocess.check_call(cc_cmdline, cwd=cwd)
    object_files = list(cwd.glob("*.o"))
    ar_cmdline = ["ar", "rcs", str(output_a_filename)] + list(map(str, object_files))
    print(shlex.join(ar_cmdline))
    subprocess.check_call(ar_cmdline, cwd=cwd)


def build_sw(cwd, srcs: list[Path], ldscript: Path,
    output_elf_filename:Path, output_disasm_filename:Path=None, output_mem_filename:Path=None,
    arch: str=cfg_arch, abi: str=cfg_abi, include_system: list[Path]=[], include_quote: list[Path]=[], static_libs: list[Path]=[]):
    
    prefix, zicsr_compat = find_toolchain_prefix()
    if not zicsr_compat and arch.endswith('_zicsr'):
        arch = arch.rsplit('_', 1)[0]

    #libs = ["-lgcc"]
    libs=[]

    cc_cmdline = [f"{prefix}gcc"]
    cc_cmdline += ["-T", str(ldscript)]
    cc_cmdline += ["-o", str(output_elf_filename)] 
    cc_cmdline += list(map(str, srcs)) 
    for path in include_system:
        cc_cmdline += ["-isystem", str(path)]
    for path in include_quote:
        cc_cmdline += ["-iquote", str(path)]
    cc_cmdline += get_cflags(abi, arch)
    cc_cmdline += libs
    for l in static_libs:
        cc_cmdline += [str(l)]
    print("Building sw:\n\t", shlex.join(cc_cmdline))
    subprocess.check_call(cc_cmdline, cwd=cwd)

    # Separate size call is not required anymore, as it is now included in elf2mem:
    #print("Output size:")
    #subprocess.check_call([f"{prefix}size", "--format=gnu", str(output_elf_filename)])

    if output_disasm_filename:
        disassemble(output_elf_filename, output_disasm_filename, cwd, prefix)

    if output_mem_filename:
        #objcopy_to_verilog_mem(output_elf_filename, output_mem_filename, cwd, prefix)
        elf2mem(output_elf_filename, output_mem_filename)

def objcopy_to_verilog_mem(input_elf_filename, output_mem_filename, cwd, prefix):
    subprocess.check_call([
        f"{prefix}objcopy",
        "-O", "verilog",
        #"--verilog-data-width=4", <-- this leads to problem with wrong @addresses in verilog
        #"--only-section=.text.boot",
        #"--only-section=.text",
        #"--only-section=.data",
        input_elf_filename,
        output_mem_filename
        ], cwd=cwd)

def disassemble(input_elf_filename, output_disasm_filename, cwd, prefix):
    disasm = subprocess.check_output([f"{prefix}objdump", "--disassemble", input_elf_filename])
    with open(output_disasm_filename, 'wb') as f:
        f.write(disasm)
