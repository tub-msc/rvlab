# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from pydesignflow import Flow

from .rvlab_fpga_top import RvlabFpgaTop
from .rvlab_mig import RvlabMig
from .system_tb import SystemTb
from .xbar import XbarGenerator
from .sw import Program, Libsys
from .simlibs_questa import SimlibsQuesta
from .module_tb import ModuleTb
from .sources import Sources
from .reggen import RegisterGenerator

flow = Flow()

# Software
# --------

sw_dirs = [
    "monitor",
    "minimal",
    "test_sim_ddr",
    "test_rvlab",
    "coremark",
    "test_irq",
    "rlight",
    "dma",
    "project",
]

flow['libsys'] = Libsys(dependency_map={'reggen': 'reggen'})
for sw_dir in sw_dirs:
    flow[f'sw_{sw_dir}'] = Program(sw_dir, dependency_map={
        'libsys':'libsys', 'ref':'sw_test_rvlab', 'reggen': 'reggen'})

# Hardware
# --------

flow['xbar'] = XbarGenerator()
flow['reggen'] = RegisterGenerator()
flow['simlibs_questa'] = SimlibsQuesta()
flow['srcs'] = Sources(dependency_map={
    'xbar': 'xbar',
    'reggen': 'reggen',
    'swinit': 'sw_test_rvlab',
    'mig':'rvlab_mig',
})

flow['rvlab_mig'] = RvlabMig()
flow['rvlab_fpga_top'] = RvlabFpgaTop(dependency_map={'srcs':'srcs'})


# Testbenches
# -----------

module_tbs = [
    "student_rlight_tb",
    "student_tlul_mux_tb",
]

for name in module_tbs:
    flow[name] = ModuleTb(name, dependency_map={
        'srcs':'srcs',
        'simlibs_questa':'simlibs_questa',
    })

for sw_dir in sw_dirs:
    flow[f'systb_{sw_dir}'] = SystemTb(dependency_map={
        'srcs':'srcs',
        'sw':f'sw_{sw_dir}',
        'simlibs_questa':'simlibs_questa',
        'fpga_top':'rvlab_fpga_top',
    })
