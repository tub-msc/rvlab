GitLab CI Pipeline
==================

**The use of GitLab CI is not required for the course!**

In 2024, a student group set up a GitLab continuous integration (CI) pipeline for the RISC-V Lab. This can be done by downloading and running the `GitLab runner binary <https://docs.gitlab.com/runner/install/>`_ as regular user (not superuser) on the lab system. The GitLab runner can be connected to the regular GitLab instance of TU Berlin.

A :code:`.gitlab-ci.yml` file must be created in the root directory of your rvlab fork. An example is shown below. The file must be adapted to the needs of your specific project::

    stages:
      - deploy
      - lint
      - build
    pages:
      stage: deploy
      script:
        - cd docs && make clean && make html
        - mv _build/html ../public
      artifacts:
        paths:
          - public
      only:
        - main     
    srcs_lint:
      stage: lint
      script:
        - flow srcs.lint
    srcs_srcs:
      stage: lint
      script:
        - flow srcs.srcs_noddr
    build_game:
      stage: lint
      script:
        - flow sw_project.build
      artifacts:
        paths:
          - build/sw_project/build/sw.elf
    sim_pnr:
      stage: build
      script: 
        - flow simlibs_questa.unisims  
        - flow simlibs_questa.secureip
        - flow rvlab_fpga_top.syn
        - flow rvlab_fpga_top.pnr
        - flow rvlab_fpga_top.bitstream
      artifacts:
        paths:
          - build/rvlab_fpga_top/**/*.log 
          - build/rvlab_fpga_top/**/*.txt 
          - build/rvlab_fpga_top/bitstream/rvlab_fpga_top.bit 
    # - flow systb_test_audio.sim_pnrtime_questa

    sim_batch:
      stage: build
      script:
        - flow systb_test_audio.sim_rtl_questa_batch
