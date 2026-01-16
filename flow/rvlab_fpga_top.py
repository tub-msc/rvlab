# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools.vivado import Vivado
from .tools import pincheck
import datetime
from pathlib import Path

class RvlabFpgaTop(Block):
    """
    Top-level FPGA design
    """

    name = "rvlab_fpga_top"
    part = "xc7a200tsbg484-1"

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"
        self.design_dir = self.src_dir / "design"
        self.xdc_in = self.design_dir / "xdc" / f"{self.name}.xdc"

    @task(requires={'srcs':'srcs.srcs'}, hidden=True)
    def rtl_elaborate(self, cwd, srcs):
        """RTL elaboration in Vivado"""
        with Vivado(cwd=cwd, interact=True) as t:
            t.read_verilog(srcs.design_srcs)
            for xci in srcs.xcis:
                t.import_ip(xci)
            t.read_xdc(self.xdc_in)
            defines = []
            for k, v in srcs.defines.items():
                defines += ['-verilog_define', f"{k}={v}"]

            t.synth_design(top=self.name, part=self.part, rtl=True, *defines)
            t.start_gui()

    def vivado_generate_reports(self, cwd: Path, r: Result, t: Vivado):
        disable_methodology_checks = [
            "XDCH-2",
            "XDCB-5",
            "REQP-1959",
            "SYNTH-6",
            "SYNTH-15",
            "TIMING-47",
            "TIMING-9",
            "TIMING-10",
            "TIMING-18",
            "PDRC-190", # Suboptimally placed synchronized register chain
        ]
        disable_drc_checks = [
            "BUFC-1", # Input buffer with no load
            "REQP-1839", # RAMB36 async control check (potential problem?)
            "REQP-1709", # clock output buffering
        ]
        t.get_methodology_checks(disable_methodology_checks).set_property('IS_ENABLED', 'FALSE')
        t.get_drc_checks(disable_drc_checks).set_property('IS_ENABLED', 'FALSE')

        t.create_waiver(strings="tlul_ddr_i/mig_i", id="LUTAR-1", description="In Xilinx IP")
        t.create_waiver(strings="tlul_ddr_i/mig_i", id="REQP-1709", description="In Xilinx IP")
        t.create_waiver(strings="tdo_flop_i", id="TIMING-14", description="Needed for TDO")

        r.report_utilization = cwd / f"{self.name}.utilization.txt"
        r.report_timing_summary = cwd / f"{self.name}.timing_summary.txt"
        r.report_qor_assessment = cwd / f"{self.name}.qor_assessment.txt"
        r.report_methodology = cwd / f"{self.name}.methodology.txt"
        r.report_drc = cwd / f"{self.name}.drc.txt"

        t.report_utilization(file=r.report_utilization)
        t.report_timing_summary(file=r.report_timing_summary)
        t.report_qor_assessment(file=r.report_qor_assessment)
        t.report_methodology(file=r.report_methodology)
        t.report_drc(file=r.report_drc)

    @task(requires={'srcs':'srcs.srcs',})
    def syn(self, cwd, srcs):
        """Synthesize FPGA netlist from RTL sources"""

        r = Result()
        r.dcp = cwd / f"{self.name}.dcp"
        r.verilog_funcsim = cwd / f"{self.name}.funcsim.v"


        with Vivado(cwd=cwd) as t:
            t.set_part(self.part)
            t.read_verilog(srcs.design_srcs)
            for xci in srcs.xcis:
                t.import_ip(xci)
            t.read_xdc(self.xdc_in)
            defines = []
            for k, v in srcs.defines.items():
                defines += ['-verilog_define', f"{k}={v}"]

            t.synth_design(top=self.name, part=self.part,
                directive="PerformanceOptimized",
                flatten_hierarchy="rebuilt", # choices: full, none, rebuilt
                *defines 
            )
            t.opt_design(directive="NoBramPowerOpt")
            t.write_checkpoint(r.dcp)
            t.write_verilog(r.verilog_funcsim, mode="funcsim")

            self.vivado_generate_reports(cwd, r, t)            

        return r

    @task(requires={'syn':'.syn'})
    def pnr(self, cwd, syn):
        """Place and route netlist"""

        r = Result()
        r.dcp = cwd / f"{self.name}.dcp"
        r.verilog_timesim = cwd / f"{self.name}.timesim.v"
        r.verilog_funcsim = cwd / f"{self.name}.funcsim.v"
        r.sdf = cwd / f"{self.name}.sdf"
        
        with Vivado(cwd=cwd) as t:
            t.read_checkpoint(syn.dcp)
            t.link_design(name=self.name)
            
            t.place_design()
            t.route_design()

            t.write_checkpoint(r.dcp)
            t.write_verilog(r.verilog_funcsim, mode="funcsim")
            t.write_verilog(r.verilog_timesim, mode="timesim")
            t.write_sdf(r.sdf)

            self.vivado_generate_reports(cwd, r, t)

        return r

    @task(requires={'pnr':'.pnr'})
    def bitstream(self, cwd, pnr):
        """Generate bitstream from PNR result"""

        r = Result()
        r.dcp = cwd / f"{self.name}.dcp"
        r.bit_file = cwd / f"{self.name}.bit"
        r.ltx_file = cwd / f"{self.name}.ltx"
    
        r.io_xml = cwd / f'{self.name}.io.xml'
        r.io_rpt = cwd / f'{self.name}.io_report.txt'
        io_ref_csv = self.design_dir / 'pincheck/pincheck.csv'

        with Vivado(cwd=cwd) as t:
            t.read_checkpoint(pnr.dcp)
            t.link_design(name=self.name)
        
            t.report_io(format='xml', file=r.io_xml)

            pins_design = pincheck.signalpins_from_xml(r.io_xml)
            pins_ref = pincheck.signalpins_from_csv(io_ref_csv)
            report = pincheck.signalpins_check(pins_design, pins_ref)
            ts = datetime.datetime.now().strftime("%d.%m.%Y %H:%M:%S")
            with open(r.io_rpt, "w") as f:
                f.write(f"Pin check report ({ts})\n")
                for l in report:
                    f.write(l+'\n')

            t.write_bitstream(r.bit_file)
            t.write_debug_probes(r.ltx_file)

        return r
    
    @task(requires={'bitstream':'.bitstream'})
    def program(self, cwd, bitstream):
        """Load bitstream to FPGA"""
        with Vivado(cwd=cwd) as t:
            t.open_hw_manager()
            t.connect_hw_server(allow_non_jtag=True)

            hw_targets = t.get_hw_targets()
            hw_target = t.lindex(hw_targets, 1)
            t.current_hw_target(hw_target)

            t.open_hw_target()

            device = t.get_hw_devices("xc7a200t_0")
            t.refresh_hw_device(device, update_hw_probes="false")
            t.set_property("PROBES.FILE", "", device)
            t.set_property("FULL_PROBES.FILE", "", device)
            t.set_property("PROGRAM.FILE", bitstream.bit_file, device)

            t.program_hw_devices(device)
