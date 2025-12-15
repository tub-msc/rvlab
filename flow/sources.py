# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools import vivado
import subprocess
from .tools.overlay import filter_solutions_overlay

class Sources(Block):
    """Hardware sources"""

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"

    @task(requires={
        'xbar':'xbar.generate',
        'reggen':'reggen.generate',
        'swinit':'swinit.build',
        }, always_rebuild=True, hidden=True)
    def srcs_noddr(self, cwd, xbar, reggen, swinit):
        """RTL + verification sources without DDR3"""
        r = Result()

        design_srcs_pkg = []
        design_srcs_pkg += [self.src_dir / "rtl/inc/prim_assert.sv"]
        for d in ["rvlab_fpga", "prim", "prim2", "cv32e40p", "tlul", "rv_dm"]:
            design_srcs_pkg += [x for x in self.src_dir.glob(f"rtl/{d}/pkg/*.sv")]
        design_srcs = []
        design_srcs += [x for x in self.src_dir.glob("rtl/*/*.sv")]    

        r.tb_srcs = [x for x in self.src_dir.glob("tb/*.sv")]
        r.tb_srcs += [vivado.vivado_dir() / "data/verilog/src/glbl.v"]
        r.tb_srcs = filter_solutions_overlay(r.tb_srcs, self.src_dir)


        r.design_srcs = design_srcs_pkg + xbar.rtl_srcs + reggen.rtl_srcs + design_srcs
        r.design_srcs = filter_solutions_overlay(r.design_srcs, self.src_dir)

        r.defines = {
            'INIT_MEM_FILE':swinit.mem,
        }
        
        r.include_dirs = [self.src_dir/"rtl/inc"]
        
        r.xcis = []
        
        return r

    @task(requires={
        'noddr':'.srcs_noddr',
        'mig':'mig.generate',
        }, always_rebuild=True, hidden=True)
    def srcs(self, cwd, noddr, mig):
        """RTL + verification sources including DDR3"""
        r = Result()
        r.design_srcs = noddr.design_srcs
        r.defines = noddr.defines | {'WITH_EXT_DRAM':'1'}
        r.include_dirs = noddr.include_dirs + mig.include_dirs
        r.tb_srcs = noddr.tb_srcs + mig.sim_verilog
        r.xcis = noddr.xcis + [mig.xci]
        return r

    @task(requires={"srcs":".srcs_noddr"})
    def lint(self, cwd, srcs):
        """Run static code quality assessment"""
        rules = [
            'always-comb',
            'always-comb-blocking',
            'always-ff-non-blocking',
            'case-missing-default',
            'explicit-function-lifetime',
            'explicit-function-task-parameter-type',
            'explicit-parameter-storage-type',
            'explicit-task-lifetime',
            'forbid-consecutive-null-statements',
            'forbid-defparam',
            'forbid-line-continuations',
            'generate-label',
            'module-begin-block',
            'module-filename',
            'module-parameter',
            'module-port',
            'one-module-per-file',
            'package-filename',
            'packed-dimensions-range-ordering',
            #'port-name-suffix',
            'undersized-binary-literal',
            'v2001-generate-begin',
            'void-cast',
        ]
        try:
            subprocess.check_call(['verible-verilog-lint', '--ruleset', 'none', '--rules', ",".join(rules)]+srcs.design_srcs, cwd=cwd)
        except subprocess.CalledProcessError as e:
            print(f"WARNING: verible-verilog-lint returned {e.returncode} errors.")
        else:
            print("Lint returned no errors.")
