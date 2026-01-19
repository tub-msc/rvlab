# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools import questasim, xsim, vivado

class ModuleTb(Block):
    """Module-level testbench"""

    def __init__(self, name, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.name = name

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"
        self.design_dir = self.src_dir / "design"

    def simulate(self, simulator, cwd, srcs, libs=[], batch=False):
        """Generic function that is called by all sim_... tasks."""

        verilog_srcs = srcs.design_srcs + srcs.tb_srcs
        top_modules = [self.name, 'glbl']

        if simulator == 'questasim':
            sim = questasim.simulate
            wave_do = self.design_dir / f"wave/{self.name}.do"
        elif simulator == 'xsim':
            sim = xsim.simulate
            wave_do = self.design_dir / f"wave/{self.name}.xsim.wcfg"            
        else:
            raise ValueError(f"Unknown simulator '{simulator}'")
        
        sim(
            verilog_srcs,
            top_modules,
            cwd=cwd,
            include_dirs=srcs.include_dirs,
            defines=srcs.defines,
            libs=libs,
            batch_mode=batch,
            wave_do=wave_do,
            )

    # QuestaSim tasks
    # ---------------

    @task(requires={'srcs':'srcs.srcs_noddr', 'unisims':'simlibs_questa.unisims'})
    def sim_rtl_questa(self, cwd, srcs, unisims):
        """RTL simulation with QuestaSim"""
        self.simulate('questasim', cwd, srcs,
            libs=[unisims.lib])

    @task(requires={'srcs':'srcs.srcs_noddr', 'unisims':'simlibs_questa.unisims'}, hidden=True)
    def sim_rtl_questa_batch(self, cwd, srcs, unisims):
        """RTL simulation with QuestaSim (batch mode)"""
        self.simulate('questasim', cwd, srcs,
            libs=[unisims.lib],
            batch=True)

    # Vivado XSim tasks
    # -----------------

    @task(requires={'srcs':'srcs.srcs_noddr'})
    def sim_rtl_xsim(self, cwd, srcs):
        """RTL simulation with XSim"""
        self.simulate('xsim', cwd, srcs,
            libs=['unisims_ver', 'secureip']) # Xilinx XSim has this as builtin library. 
            
