# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools import questasim, xsim, vivado, verilator
import shutil

class SystemTb(Block):
    """System testbench"""
    name = "system_tb"

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"
        self.design_dir = self.src_dir / "design"

    def simulate(self, simulator, cwd, srcs, sw, libs=[], netlist=None, sdf={}, batch=False, unisims_dir=None):
        """Generic function that is called by all sim_... tasks."""

        plusargs = {"jtag_prog_mem":sw.deltafile}
        top_modules = [self.name, 'glbl']

        verilog_srcs = srcs.design_srcs + srcs.tb_srcs
        if netlist:
            verilog_srcs.append(netlist)

        kwargs = {}

        if simulator == 'questasim':
            sim = questasim.simulate
            wave_do = [
                self.design_dir / f"wave/riscv.radix.do",
                self.design_dir / f"wave/{self.name}.do",
            ]
            if netlist:
                kwargs['hide_mig_timingcheck_msg'] = True
        elif simulator == 'xsim':
            sim = xsim.simulate
            wave_do = self.design_dir / f"wave/{self.name}.xsim.wcfg"
        elif simulator == 'verilator':
            sim = verilator.simulate
            wave_do = None  # Verilator doesn't use wave_do files
            if unisims_dir is None:
                raise ValueError("unisims_dir must be provided for Verilator simulation")
            kwargs['unisims_dir'] = unisims_dir
        else:
            raise ValueError(f"Unknown simulator '{simulator}'")
        
        # Copy XADC temperature input file
        shutil.copyfile(
            self.design_dir / "ip/design.txt",
            cwd / 'design.txt'
        )

        sim(  # type: ignore
            verilog_srcs,
            top_modules,  # type: ignore
            cwd=cwd,
            include_dirs=srcs.include_dirs,
            defines=srcs.defines,
            plusargs=plusargs,
            libs=libs,
            batch_mode=batch,
            sdf=sdf,
            wave_do=wave_do,  # type: ignore
            **kwargs
            )

    # QuestaSim tasks
    # ---------------

    @task(requires={
        'srcs':'srcs.srcs_noddr',
        'sw':'sw.delta',
        'unisims':'simlibs_questa.unisims',
        })
    def sim_rtl_questa(self, cwd, srcs, sw, unisims):
        """RTL simulation with QuestaSim"""
        self.simulate('questasim', cwd, srcs, sw,
            libs=[unisims.lib])

    @task(requires={
        'srcs':'srcs.srcs',
        'sw':'sw.delta',
        'unisims':'simlibs_questa.unisims',
        'secureip':'simlibs_questa.secureip',
        })
    def sim_rtl_questa_ddr(self, cwd, srcs, sw, unisims, secureip):
        """RTL simulation with QuestaSim including DDR3"""
        self.simulate('questasim', cwd, srcs, sw,
            libs=[unisims.lib, secureip.lib])

    @task(requires={
        'srcs':'srcs.srcs_noddr',
        'sw':'sw.delta',
        'unisims':'simlibs_questa.unisims',
        }, hidden=True)
    def sim_rtl_questa_batch(self, cwd, srcs, sw, unisims):
        """RTL simulation with QuestaSim (batch mode)"""
        self.simulate('questasim', cwd, srcs, sw,
            libs=[unisims.lib],
            batch=True)

    @task(requires={
        'srcs':'srcs.srcs',
        'sw':'sw.delta',
        'unisims':'simlibs_questa.unisims',
        'secureip':'simlibs_questa.secureip',
        'syn':'fpga_top.syn',
        })
    def sim_synfunc_questa(self, cwd, srcs, sw, unisims, secureip, syn):
        """Post-synthesis functional simulation with QuestaSim"""
        self.simulate(
            'questasim', cwd, srcs, sw,
            libs=[unisims.lib, secureip.lib],
            netlist=syn.verilog_funcsim)

    @task(requires={
        'srcs':'srcs.srcs',
        'sw':'sw.delta',
        'simprims':'simlibs_questa.simprims',
        'secureip':'simlibs_questa.secureip',
        'pnr':'fpga_top.pnr',
        })
    def sim_pnrtime_questa(self, cwd, srcs, sw, simprims, secureip, pnr):
        """Post-PNR timing simulation with QuestaSim"""
        self.simulate('questasim', cwd, srcs, sw,
            libs=[simprims.lib, secureip.lib],
            netlist=pnr.verilog_timesim,
            sdf={'system_tb/board/DUT':pnr.sdf})

    # Vivado XSim tasks
    # -----------------

    @task(requires={
        'srcs':'srcs.srcs_noddr',
        'sw':'sw.delta',
        })
    def sim_rtl_xsim(self, cwd, srcs, sw):
        """RTL simulation with XSim"""
        self.simulate('xsim', cwd, srcs, sw,
            libs=['unisims_ver', 'secureip']) # Xilinx XSim has this as builtin library. 

    @task(requires={
        'srcs':'srcs.srcs',
        'sw':'sw.delta',
        })
    def sim_rtl_xsim_ddr(self, cwd, srcs, sw):
        """RTL simulation with XSim including DDR3"""
        self.simulate('xsim', cwd, srcs, sw,
            libs=['unisims_ver', 'secureip']) # Xilinx XSim has this as builtin library. 

    @task(requires={
        'srcs':'srcs.srcs',
        'sw':'sw.delta',
        'syn':'fpga_top.syn',
        })
    def sim_synfunc_xsim(self, cwd, srcs, sw, syn):
        """Post-synthesis functional simulation with XSim"""
        self.simulate('xsim', cwd, srcs, sw,
            libs=['unisims_ver', 'secureip'], # Xilinx XSim has this as builtin library.
            netlist=syn.verilog_funcsim)

    @task(requires={
        'srcs':'srcs.srcs',
        'sw':'sw.delta',
        'pnr':'fpga_top.pnr',
        })
    def sim_pnrtime_xsim(self, cwd, srcs, sw, pnr):
        """Post-PNR timing simulation with XSim"""
        # WARNING: This simulation currently fails!! Compare with sim_pnrtime_questa
        self.simulate('xsim', cwd, srcs, sw,
            libs=['simprims_ver', 'secureip'], # Xilinx XSim has this as builtin library.
            netlist=pnr.verilog_timesim,
            sdf={'system_tb/board/DUT':pnr.sdf})

    # Verilator tasks
    # ---------------

    @task(requires={
        'srcs':'srcs.srcs_noddr_verilator',
        'sw':'sw.delta',
        })
    def sim_rtl_verilator(self, cwd, srcs, sw):
        """RTL simulation with Verilator"""
        self.simulate('verilator', cwd, srcs, sw,
            unisims_dir=srcs.unisims_dir)

    @task(requires={
        'srcs':'srcs.srcs_noddr_verilator',
        'sw':'sw.delta',
        }, hidden=True)
    def sim_rtl_verilator_batch(self, cwd, srcs, sw):
        """RTL simulation with Verilator (batch mode)"""
        self.simulate('verilator', cwd, srcs, sw,
            unisims_dir=srcs.unisims_dir,
            batch=True)
