# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools.vivado import vivado_dir
from pathlib import Path
import shutil
import re

def replace_in_file(filepath: Path, x: dict[str,str]):
    pattern = re.compile('|'.join(re.escape(k) for k in sorted(x, key=len, reverse=True)))
    content = filepath.read_text()
    filepath.write_text(pattern.sub(lambda m: x[m.group(0)], content))

class Ddr3Model(Block):
    """Obtain simulation model of DDR3 chip."""


    @task()
    def generate(self, cwd):
        """Generate SystemVerilog + C headers"""

        ddr3_sim_dir = vivado_dir() / 'data/ip/xilinx/mig_7series_v4_2/data/dlib/7series/ddr3_sdram/sim'

        shutil.copy(ddr3_sim_dir / "ddr3_model.sv", cwd / "ddr3.sv")
        shutil.copy(ddr3_sim_dir / "ddr3_model_parameters.vh", cwd / "ddr3_parameters.vh")

        replace_in_file(cwd / 'ddr3.sv', {
                "%cntInfo_lddr3_model": "ddr3",
                "%MEM_DENSITY": "4Gb",
                "%MEM_SPEEDGRADE": "187E",
                "%MEM_DEVICE_WIDTH": "16",
            })

        r = Result()
        r.tb_srcs = [cwd / 'ddr3.sv']
        r.include_dirs = [cwd]

        return r
