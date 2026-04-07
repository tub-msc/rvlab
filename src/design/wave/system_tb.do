onerror {resume}
radix define riscv_instr {
    "32'b00000000000000000000000000000000" "0x00000000",
    "32'b0000000??????????000?????0110011" "ADD",
    "32'b?????????????????000?????0010011" "ADDI",
    "32'b00000????????????010?????0101111" "AMOADD_W",
    "32'b01100????????????010?????0101111" "AMOAND_W",
    "32'b10100????????????010?????0101111" "AMOMAX_W",
    "32'b11100????????????010?????0101111" "AMOMAXU_W",
    "32'b10000????????????010?????0101111" "AMOMIN_W",
    "32'b11000????????????010?????0101111" "AMOMINU_W",
    "32'b01000????????????010?????0101111" "AMOOR_W",
    "32'b00001????????????010?????0101111" "AMOSWAP_W",
    "32'b00100????????????010?????0101111" "AMOXOR_W",
    "32'b0000000??????????111?????0110011" "AND",
    "32'b?????????????????111?????0010011" "ANDI",
    "32'b?????????????????????????0010111" "AUIPC",
    "32'b?????????????????000?????1100011" "BEQ",
    "32'b?????????????????101?????1100011" "BGE",
    "32'b?????????????????111?????1100011" "BGEU",
    "32'b?????????????????100?????1100011" "BLT",
    "32'b?????????????????110?????1100011" "BLTU",
    "32'b?????????????????001?????1100011" "BNE",
    "32'b????????????????1001??????????10" "C_ADD",
    "32'b????????????????000???????????01" "C_ADDI",
    "32'b????????????????011?00010?????01" "C_ADDI16SP",
    "32'b????????????????000???????????00" "C_ADDI4SPN",
    "32'b????????????????100011???11???01" "C_AND",
    "32'b????????????????100?10????????01" "C_ANDI",
    "32'b????????????????110???????????01" "C_BEQZ",
    "32'b????????????????111???????????01" "C_BNEZ",
    "32'b????????????????1001000000000010" "C_EBREAK",
    "32'b????????????????101???????????01" "C_J",
    "32'b????????????????001???????????01" "C_JAL",
    "32'b????????????????1001?????0000010" "C_JALR",
    "32'b????????????????1000?????0000010" "C_JR",
    "32'b????????????????010???????????01" "C_LI",
    "32'b????????????????011???????????01" "C_LUI",
    "32'b????????????????010???????????00" "C_LW",
    "32'b????????????????010???????????10" "C_LWSP",
    "32'b????????????????1000??????????10" "C_MV",
    "32'b????????????????000?00000?????01" "C_NOP",
    "32'b????????????????100011???10???01" "C_OR",
    "32'b????????????????0000??????????10" "C_SLLI",
    "32'b????????????????100001????????01" "C_SRAI",
    "32'b????????????????100000????????01" "C_SRLI",
    "32'b????????????????100011???00???01" "C_SUB",
    "32'b????????????????110???????????00" "C_SW",
    "32'b????????????????110???????????10" "C_SWSP",
    "32'b????????????????100011???01???01" "C_XOR",
    "32'b?????????????????011?????1110011" "CSRRC",
    "32'b?????????????????111?????1110011" "CSRRCI",
    "32'b?????????????????010?????1110011" "CSRRS",
    "32'b?????????????????110?????1110011" "CSRRSI",
    "32'b?????????????????001?????1110011" "CSRRW",
    "32'b?????????????????101?????1110011" "CSRRWI",
    "32'b0000001??????????100?????0110011" "DIV",
    "32'b0000001??????????101?????0110011" "DIVU",
    "32'b00000000000100000000000001110011" "EBREAK",
    "32'b00000000000000000000000001110011" "ECALL",
    "32'b0000001??????????????????1010011" "FADD_D",
    "32'b0000000??????????????????1010011" "FADD_S",
    "32'b111000100000?????001?????1010011" "FCLASS_D",
    "32'b111000000000?????001?????1010011" "FCLASS_S",
    "32'b010000100000?????????????1010011" "FCVT_D_S",
    "32'b110100100000?????????????1010011" "FCVT_D_W",
    "32'b110100100001?????????????1010011" "FCVT_D_WU",
    "32'b010000000001?????????????1010011" "FCVT_S_D",
    "32'b110100000000?????????????1010011" "FCVT_S_W",
    "32'b110100000001?????????????1010011" "FCVT_S_WU",
    "32'b110000100000?????????????1010011" "FCVT_W_D",
    "32'b110000000000?????????????1010011" "FCVT_W_S",
    "32'b110000100001?????????????1010011" "FCVT_WU_D",
    "32'b110000000001?????????????1010011" "FCVT_WU_S",
    "32'b0001101??????????????????1010011" "FDIV_D",
    "32'b0001100??????????????????1010011" "FDIV_S",
    "32'b?????????????????000?????0001111" "FENCE",
    "32'b?????????????????001?????0001111" "FENCE_I",
    "32'b1010001??????????010?????1010011" "FEQ_D",
    "32'b1010000??????????010?????1010011" "FEQ_S",
    "32'b?????????????????011?????0000111" "FLD",
    "32'b1010001??????????000?????1010011" "FLE_D",
    "32'b1010000??????????000?????1010011" "FLE_S",
    "32'b1010001??????????001?????1010011" "FLT_D",
    "32'b1010000??????????001?????1010011" "FLT_S",
    "32'b?????????????????010?????0000111" "FLW",
    "32'b?????01??????????????????1000011" "FMADD_D",
    "32'b?????00??????????????????1000011" "FMADD_S",
    "32'b0010101??????????001?????1010011" "FMAX_D",
    "32'b0010100??????????001?????1010011" "FMAX_S",
    "32'b0010101??????????000?????1010011" "FMIN_D",
    "32'b0010100??????????000?????1010011" "FMIN_S",
    "32'b?????01??????????????????1000111" "FMSUB_D",
    "32'b?????00??????????????????1000111" "FMSUB_S",
    "32'b0001001??????????????????1010011" "FMUL_D",
    "32'b0001000??????????????????1010011" "FMUL_S",
    "32'b111100000000?????000?????1010011" "FMV_W_X",
    "32'b111000000000?????000?????1010011" "FMV_X_W",
    "32'b?????01??????????????????1001111" "FNMADD_D",
    "32'b?????00??????????????????1001111" "FNMADD_S",
    "32'b?????01??????????????????1001011" "FNMSUB_D",
    "32'b?????00??????????????????1001011" "FNMSUB_S",
    "32'b?????????????????011?????0100111" "FSD",
    "32'b0010001??????????000?????1010011" "FSGNJ_D",
    "32'b0010000??????????000?????1010011" "FSGNJ_S",
    "32'b0010001??????????001?????1010011" "FSGNJN_D",
    "32'b0010000??????????001?????1010011" "FSGNJN_S",
    "32'b0010001??????????010?????1010011" "FSGNJX_D",
    "32'b0010000??????????010?????1010011" "FSGNJX_S",
    "32'b010110100000?????????????1010011" "FSQRT_D",
    "32'b010110000000?????????????1010011" "FSQRT_S",
    "32'b0000101??????????????????1010011" "FSUB_D",
    "32'b0000100??????????????????1010011" "FSUB_S",
    "32'b?????????????????010?????0100111" "FSW",
    "32'b?????????????????????????1101111" "JAL",
    "32'b?????????????????000?????1100111" "JALR",
    "32'b?????????????????000?????0000011" "LB",
    "32'b?????????????????100?????0000011" "LBU",
    "32'b?????????????????001?????0000011" "LH",
    "32'b?????????????????101?????0000011" "LHU",
    "32'b00010??00000?????010?????0101111" "LR_W",
    "32'b?????????????????????????0110111" "LUI",
    "32'b?????????????????010?????0000011" "LW",
    "32'b0000001??????????000?????0110011" "MUL",
    "32'b0000001??????????001?????0110011" "MULH",
    "32'b0000001??????????010?????0110011" "MULHSU",
    "32'b0000001??????????011?????0110011" "MULHU",
    "32'b0000000??????????110?????0110011" "OR",
    "32'b?????????????????110?????0010011" "ORI",
    "32'b0000001??????????110?????0110011" "REM",
    "32'b0000001??????????111?????0110011" "REMU",
    "32'b?????????????????000?????0100011" "SB",
    "32'b00011????????????010?????0101111" "SC_W",
    "32'b?????????????????001?????0100011" "SH",
    "32'b0000000??????????001?????0110011" "SLL",
    "32'b0000000??????????001?????0010011" "SLLI",
    "32'b0000000??????????010?????0110011" "SLT",
    "32'b?????????????????010?????0010011" "SLTI",
    "32'b?????????????????011?????0010011" "SLTIU",
    "32'b0000000??????????011?????0110011" "SLTU",
    "32'b0100000??????????101?????0110011" "SRA",
    "32'b0100000??????????101?????0010011" "SRAI",
    "32'b0000000??????????101?????0110011" "SRL",
    "32'b0000000??????????101?????0010011" "SRLI",
    "32'b0100000??????????000?????0110011" "SUB",
    "32'b?????????????????010?????0100011" "SW",
    "32'b0000000??????????100?????0110011" "XOR",
    "32'b?????????????????100?????0010011" "XORI",
    -default default
}
radix define riscv_csrs {
    "12'h1" "CSR_FFLAGS",
    "12'h2" "CSR_FRM",
    "12'h3" "CSR_FCSR",
    "12'h8" "CSR_VSTART",
    "12'h9" "CSR_VXSAT",
    "12'ha" "CSR_VXRM",
    "12'hf" "CSR_VCSR",
    "12'h15" "CSR_SEED",
    "12'h17" "CSR_JVT",
    "12'hc00" "CSR_CYCLE",
    "12'hc01" "CSR_TIME",
    "12'hc02" "CSR_INSTRET",
    "12'hc03" "CSR_HPMCOUNTER3",
    "12'hc04" "CSR_HPMCOUNTER4",
    "12'hc05" "CSR_HPMCOUNTER5",
    "12'hc06" "CSR_HPMCOUNTER6",
    "12'hc07" "CSR_HPMCOUNTER7",
    "12'hc08" "CSR_HPMCOUNTER8",
    "12'hc09" "CSR_HPMCOUNTER9",
    "12'hc0a" "CSR_HPMCOUNTER10",
    "12'hc0b" "CSR_HPMCOUNTER11",
    "12'hc0c" "CSR_HPMCOUNTER12",
    "12'hc0d" "CSR_HPMCOUNTER13",
    "12'hc0e" "CSR_HPMCOUNTER14",
    "12'hc0f" "CSR_HPMCOUNTER15",
    "12'hc10" "CSR_HPMCOUNTER16",
    "12'hc11" "CSR_HPMCOUNTER17",
    "12'hc12" "CSR_HPMCOUNTER18",
    "12'hc13" "CSR_HPMCOUNTER19",
    "12'hc14" "CSR_HPMCOUNTER20",
    "12'hc15" "CSR_HPMCOUNTER21",
    "12'hc16" "CSR_HPMCOUNTER22",
    "12'hc17" "CSR_HPMCOUNTER23",
    "12'hc18" "CSR_HPMCOUNTER24",
    "12'hc19" "CSR_HPMCOUNTER25",
    "12'hc1a" "CSR_HPMCOUNTER26",
    "12'hc1b" "CSR_HPMCOUNTER27",
    "12'hc1c" "CSR_HPMCOUNTER28",
    "12'hc1d" "CSR_HPMCOUNTER29",
    "12'hc1e" "CSR_HPMCOUNTER30",
    "12'hc1f" "CSR_HPMCOUNTER31",
    "12'hc20" "CSR_VL",
    "12'hc21" "CSR_VTYPE",
    "12'hc22" "CSR_VLENB",
    "12'h100" "CSR_SSTATUS",
    "12'h102" "CSR_SEDELEG",
    "12'h103" "CSR_SIDELEG",
    "12'h104" "CSR_SIE",
    "12'h105" "CSR_STVEC",
    "12'h106" "CSR_SCOUNTEREN",
    "12'h10a" "CSR_SENVCFG",
    "12'h10c" "CSR_SSTATEEN0",
    "12'h10d" "CSR_SSTATEEN1",
    "12'h10e" "CSR_SSTATEEN2",
    "12'h10f" "CSR_SSTATEEN3",
    "12'h140" "CSR_SSCRATCH",
    "12'h141" "CSR_SEPC",
    "12'h142" "CSR_SCAUSE",
    "12'h143" "CSR_STVAL",
    "12'h144" "CSR_SIP",
    "12'h14d" "CSR_STIMECMP",
    "12'h150" "CSR_SISELECT",
    "12'h151" "CSR_SIREG",
    "12'h15c" "CSR_STOPEI",
    "12'h180" "CSR_SATP",
    "12'h5a8" "CSR_SCONTEXT",
    "12'h200" "CSR_VSSTATUS",
    "12'h204" "CSR_VSIE",
    "12'h205" "CSR_VSTVEC",
    "12'h240" "CSR_VSSCRATCH",
    "12'h241" "CSR_VSEPC",
    "12'h242" "CSR_VSCAUSE",
    "12'h243" "CSR_VSTVAL",
    "12'h244" "CSR_VSIP",
    "12'h24d" "CSR_VSTIMECMP",
    "12'h250" "CSR_VSISELECT",
    "12'h251" "CSR_VSIREG",
    "12'h25c" "CSR_VSTOPEI",
    "12'h280" "CSR_VSATP",
    "12'h600" "CSR_HSTATUS",
    "12'h602" "CSR_HEDELEG",
    "12'h603" "CSR_HIDELEG",
    "12'h604" "CSR_HIE",
    "12'h605" "CSR_HTIMEDELTA",
    "12'h606" "CSR_HCOUNTEREN",
    "12'h607" "CSR_HGEIE",
    "12'h608" "CSR_HVIEN",
    "12'h609" "CSR_HVICTL",
    "12'h60a" "CSR_HENVCFG",
    "12'h60c" "CSR_HSTATEEN0",
    "12'h60d" "CSR_HSTATEEN1",
    "12'h60e" "CSR_HSTATEEN2",
    "12'h60f" "CSR_HSTATEEN3",
    "12'h643" "CSR_HTVAL",
    "12'h644" "CSR_HIP",
    "12'h645" "CSR_HVIP",
    "12'h646" "CSR_HVIPRIO1",
    "12'h647" "CSR_HVIPRIO2",
    "12'h64a" "CSR_HTINST",
    "12'h680" "CSR_HGATP",
    "12'h6a8" "CSR_HCONTEXT",
    "12'he12" "CSR_HGEIP",
    "12'heb0" "CSR_VSTOPI",
    "12'hda0" "CSR_SCOUNTOVF",
    "12'hdb0" "CSR_STOPI",
    "12'h7" "CSR_UTVT",
    "12'h45" "CSR_UNXTI",
    "12'h46" "CSR_UINTSTATUS",
    "12'h48" "CSR_USCRATCHCSW",
    "12'h49" "CSR_USCRATCHCSWL",
    "12'h107" "CSR_STVT",
    "12'h145" "CSR_SNXTI",
    "12'h146" "CSR_SINTSTATUS",
    "12'h148" "CSR_SSCRATCHCSW",
    "12'h149" "CSR_SSCRATCHCSWL",
    "12'h307" "CSR_MTVT",
    "12'h345" "CSR_MNXTI",
    "12'h346" "CSR_MINTSTATUS",
    "12'h348" "CSR_MSCRATCHCSW",
    "12'h349" "CSR_MSCRATCHCSWL",
    "12'h300" "CSR_MSTATUS",
    "12'h301" "CSR_MISA",
    "12'h302" "CSR_MEDELEG",
    "12'h303" "CSR_MIDELEG",
    "12'h304" "CSR_MIE",
    "12'h305" "CSR_MTVEC",
    "12'h306" "CSR_MCOUNTEREN",
    "12'h308" "CSR_MVIEN",
    "12'h309" "CSR_MVIP",
    "12'h30a" "CSR_MENVCFG",
    "12'h30c" "CSR_MSTATEEN0",
    "12'h30d" "CSR_MSTATEEN1",
    "12'h30e" "CSR_MSTATEEN2",
    "12'h30f" "CSR_MSTATEEN3",
    "12'h320" "CSR_MCOUNTINHIBIT",
    "12'h340" "CSR_MSCRATCH",
    "12'h341" "CSR_MEPC",
    "12'h342" "CSR_MCAUSE",
    "12'h343" "CSR_MTVAL",
    "12'h344" "CSR_MIP",
    "12'h34a" "CSR_MTINST",
    "12'h34b" "CSR_MTVAL2",
    "12'h350" "CSR_MISELECT",
    "12'h351" "CSR_MIREG",
    "12'h35c" "CSR_MTOPEI",
    "12'h3a0" "CSR_PMPCFG0",
    "12'h3a1" "CSR_PMPCFG1",
    "12'h3a2" "CSR_PMPCFG2",
    "12'h3a3" "CSR_PMPCFG3",
    "12'h3a4" "CSR_PMPCFG4",
    "12'h3a5" "CSR_PMPCFG5",
    "12'h3a6" "CSR_PMPCFG6",
    "12'h3a7" "CSR_PMPCFG7",
    "12'h3a8" "CSR_PMPCFG8",
    "12'h3a9" "CSR_PMPCFG9",
    "12'h3aa" "CSR_PMPCFG10",
    "12'h3ab" "CSR_PMPCFG11",
    "12'h3ac" "CSR_PMPCFG12",
    "12'h3ad" "CSR_PMPCFG13",
    "12'h3ae" "CSR_PMPCFG14",
    "12'h3af" "CSR_PMPCFG15",
    "12'h3b0" "CSR_PMPADDR0",
    "12'h3b1" "CSR_PMPADDR1",
    "12'h3b2" "CSR_PMPADDR2",
    "12'h3b3" "CSR_PMPADDR3",
    "12'h3b4" "CSR_PMPADDR4",
    "12'h3b5" "CSR_PMPADDR5",
    "12'h3b6" "CSR_PMPADDR6",
    "12'h3b7" "CSR_PMPADDR7",
    "12'h3b8" "CSR_PMPADDR8",
    "12'h3b9" "CSR_PMPADDR9",
    "12'h3ba" "CSR_PMPADDR10",
    "12'h3bb" "CSR_PMPADDR11",
    "12'h3bc" "CSR_PMPADDR12",
    "12'h3bd" "CSR_PMPADDR13",
    "12'h3be" "CSR_PMPADDR14",
    "12'h3bf" "CSR_PMPADDR15",
    "12'h3c0" "CSR_PMPADDR16",
    "12'h3c1" "CSR_PMPADDR17",
    "12'h3c2" "CSR_PMPADDR18",
    "12'h3c3" "CSR_PMPADDR19",
    "12'h3c4" "CSR_PMPADDR20",
    "12'h3c5" "CSR_PMPADDR21",
    "12'h3c6" "CSR_PMPADDR22",
    "12'h3c7" "CSR_PMPADDR23",
    "12'h3c8" "CSR_PMPADDR24",
    "12'h3c9" "CSR_PMPADDR25",
    "12'h3ca" "CSR_PMPADDR26",
    "12'h3cb" "CSR_PMPADDR27",
    "12'h3cc" "CSR_PMPADDR28",
    "12'h3cd" "CSR_PMPADDR29",
    "12'h3ce" "CSR_PMPADDR30",
    "12'h3cf" "CSR_PMPADDR31",
    "12'h3d0" "CSR_PMPADDR32",
    "12'h3d1" "CSR_PMPADDR33",
    "12'h3d2" "CSR_PMPADDR34",
    "12'h3d3" "CSR_PMPADDR35",
    "12'h3d4" "CSR_PMPADDR36",
    "12'h3d5" "CSR_PMPADDR37",
    "12'h3d6" "CSR_PMPADDR38",
    "12'h3d7" "CSR_PMPADDR39",
    "12'h3d8" "CSR_PMPADDR40",
    "12'h3d9" "CSR_PMPADDR41",
    "12'h3da" "CSR_PMPADDR42",
    "12'h3db" "CSR_PMPADDR43",
    "12'h3dc" "CSR_PMPADDR44",
    "12'h3dd" "CSR_PMPADDR45",
    "12'h3de" "CSR_PMPADDR46",
    "12'h3df" "CSR_PMPADDR47",
    "12'h3e0" "CSR_PMPADDR48",
    "12'h3e1" "CSR_PMPADDR49",
    "12'h3e2" "CSR_PMPADDR50",
    "12'h3e3" "CSR_PMPADDR51",
    "12'h3e4" "CSR_PMPADDR52",
    "12'h3e5" "CSR_PMPADDR53",
    "12'h3e6" "CSR_PMPADDR54",
    "12'h3e7" "CSR_PMPADDR55",
    "12'h3e8" "CSR_PMPADDR56",
    "12'h3e9" "CSR_PMPADDR57",
    "12'h3ea" "CSR_PMPADDR58",
    "12'h3eb" "CSR_PMPADDR59",
    "12'h3ec" "CSR_PMPADDR60",
    "12'h3ed" "CSR_PMPADDR61",
    "12'h3ee" "CSR_PMPADDR62",
    "12'h3ef" "CSR_PMPADDR63",
    "12'h747" "CSR_MSECCFG",
    "12'h7a0" "CSR_TSELECT",
    "12'h7a1" "CSR_TDATA1",
    "12'h7a2" "CSR_TDATA2",
    "12'h7a3" "CSR_TDATA3",
    "12'h7a4" "CSR_TINFO",
    "12'h7a5" "CSR_TCONTROL",
    "12'h7a8" "CSR_MCONTEXT",
    "12'h7aa" "CSR_MSCONTEXT",
    "12'h7b0" "CSR_DCSR",
    "12'h7b1" "CSR_DPC",
    "12'h7b2" "CSR_DSCRATCH0",
    "12'h7b3" "CSR_DSCRATCH1",
    "12'hb00" "CSR_MCYCLE",
    "12'hb02" "CSR_MINSTRET",
    "12'hb03" "CSR_MHPMCOUNTER3",
    "12'hb04" "CSR_MHPMCOUNTER4",
    "12'hb05" "CSR_MHPMCOUNTER5",
    "12'hb06" "CSR_MHPMCOUNTER6",
    "12'hb07" "CSR_MHPMCOUNTER7",
    "12'hb08" "CSR_MHPMCOUNTER8",
    "12'hb09" "CSR_MHPMCOUNTER9",
    "12'hb0a" "CSR_MHPMCOUNTER10",
    "12'hb0b" "CSR_MHPMCOUNTER11",
    "12'hb0c" "CSR_MHPMCOUNTER12",
    "12'hb0d" "CSR_MHPMCOUNTER13",
    "12'hb0e" "CSR_MHPMCOUNTER14",
    "12'hb0f" "CSR_MHPMCOUNTER15",
    "12'hb10" "CSR_MHPMCOUNTER16",
    "12'hb11" "CSR_MHPMCOUNTER17",
    "12'hb12" "CSR_MHPMCOUNTER18",
    "12'hb13" "CSR_MHPMCOUNTER19",
    "12'hb14" "CSR_MHPMCOUNTER20",
    "12'hb15" "CSR_MHPMCOUNTER21",
    "12'hb16" "CSR_MHPMCOUNTER22",
    "12'hb17" "CSR_MHPMCOUNTER23",
    "12'hb18" "CSR_MHPMCOUNTER24",
    "12'hb19" "CSR_MHPMCOUNTER25",
    "12'hb1a" "CSR_MHPMCOUNTER26",
    "12'hb1b" "CSR_MHPMCOUNTER27",
    "12'hb1c" "CSR_MHPMCOUNTER28",
    "12'hb1d" "CSR_MHPMCOUNTER29",
    "12'hb1e" "CSR_MHPMCOUNTER30",
    "12'hb1f" "CSR_MHPMCOUNTER31",
    "12'h323" "CSR_MHPMEVENT3",
    "12'h324" "CSR_MHPMEVENT4",
    "12'h325" "CSR_MHPMEVENT5",
    "12'h326" "CSR_MHPMEVENT6",
    "12'h327" "CSR_MHPMEVENT7",
    "12'h328" "CSR_MHPMEVENT8",
    "12'h329" "CSR_MHPMEVENT9",
    "12'h32a" "CSR_MHPMEVENT10",
    "12'h32b" "CSR_MHPMEVENT11",
    "12'h32c" "CSR_MHPMEVENT12",
    "12'h32d" "CSR_MHPMEVENT13",
    "12'h32e" "CSR_MHPMEVENT14",
    "12'h32f" "CSR_MHPMEVENT15",
    "12'h330" "CSR_MHPMEVENT16",
    "12'h331" "CSR_MHPMEVENT17",
    "12'h332" "CSR_MHPMEVENT18",
    "12'h333" "CSR_MHPMEVENT19",
    "12'h334" "CSR_MHPMEVENT20",
    "12'h335" "CSR_MHPMEVENT21",
    "12'h336" "CSR_MHPMEVENT22",
    "12'h337" "CSR_MHPMEVENT23",
    "12'h338" "CSR_MHPMEVENT24",
    "12'h339" "CSR_MHPMEVENT25",
    "12'h33a" "CSR_MHPMEVENT26",
    "12'h33b" "CSR_MHPMEVENT27",
    "12'h33c" "CSR_MHPMEVENT28",
    "12'h33d" "CSR_MHPMEVENT29",
    "12'h33e" "CSR_MHPMEVENT30",
    "12'h33f" "CSR_MHPMEVENT31",
    "12'hf11" "CSR_MVENDORID",
    "12'hf12" "CSR_MARCHID",
    "12'hf13" "CSR_MIMPID",
    "12'hf14" "CSR_MHARTID",
    "12'hf15" "CSR_MCONFIGPTR",
    "12'hfb0" "CSR_MTOPI",
    "12'h114" "CSR_SIEH",
    "12'h154" "CSR_SIPH",
    "12'h15d" "CSR_STIMECMPH",
    "12'h214" "CSR_VSIEH",
    "12'h254" "CSR_VSIPH",
    "12'h25d" "CSR_VSTIMECMPH",
    "12'h615" "CSR_HTIMEDELTAH",
    "12'h613" "CSR_HIDELEGH",
    "12'h618" "CSR_HVIENH",
    "12'h61a" "CSR_HENVCFGH",
    "12'h655" "CSR_HVIPH",
    "12'h656" "CSR_HVIPRIO1H",
    "12'h657" "CSR_HVIPRIO2H",
    "12'h61c" "CSR_HSTATEEN0H",
    "12'h61d" "CSR_HSTATEEN1H",
    "12'h61e" "CSR_HSTATEEN2H",
    "12'h61f" "CSR_HSTATEEN3H",
    "12'hc80" "CSR_CYCLEH",
    "12'hc81" "CSR_TIMEH",
    "12'hc82" "CSR_INSTRETH",
    "12'hc83" "CSR_HPMCOUNTER3H",
    "12'hc84" "CSR_HPMCOUNTER4H",
    "12'hc85" "CSR_HPMCOUNTER5H",
    "12'hc86" "CSR_HPMCOUNTER6H",
    "12'hc87" "CSR_HPMCOUNTER7H",
    "12'hc88" "CSR_HPMCOUNTER8H",
    "12'hc89" "CSR_HPMCOUNTER9H",
    "12'hc8a" "CSR_HPMCOUNTER10H",
    "12'hc8b" "CSR_HPMCOUNTER11H",
    "12'hc8c" "CSR_HPMCOUNTER12H",
    "12'hc8d" "CSR_HPMCOUNTER13H",
    "12'hc8e" "CSR_HPMCOUNTER14H",
    "12'hc8f" "CSR_HPMCOUNTER15H",
    "12'hc90" "CSR_HPMCOUNTER16H",
    "12'hc91" "CSR_HPMCOUNTER17H",
    "12'hc92" "CSR_HPMCOUNTER18H",
    "12'hc93" "CSR_HPMCOUNTER19H",
    "12'hc94" "CSR_HPMCOUNTER20H",
    "12'hc95" "CSR_HPMCOUNTER21H",
    "12'hc96" "CSR_HPMCOUNTER22H",
    "12'hc97" "CSR_HPMCOUNTER23H",
    "12'hc98" "CSR_HPMCOUNTER24H",
    "12'hc99" "CSR_HPMCOUNTER25H",
    "12'hc9a" "CSR_HPMCOUNTER26H",
    "12'hc9b" "CSR_HPMCOUNTER27H",
    "12'hc9c" "CSR_HPMCOUNTER28H",
    "12'hc9d" "CSR_HPMCOUNTER29H",
    "12'hc9e" "CSR_HPMCOUNTER30H",
    "12'hc9f" "CSR_HPMCOUNTER31H",
    "12'h310" "CSR_MSTATUSH",
    "12'h313" "CSR_MIDELEGH",
    "12'h314" "CSR_MIEH",
    "12'h318" "CSR_MVIENH",
    "12'h319" "CSR_MVIPH",
    "12'h31a" "CSR_MENVCFGH",
    "12'h31c" "CSR_MSTATEEN0H",
    "12'h31d" "CSR_MSTATEEN1H",
    "12'h31e" "CSR_MSTATEEN2H",
    "12'h31f" "CSR_MSTATEEN3H",
    "12'h354" "CSR_MIPH",
    "12'h723" "CSR_MHPMEVENT3H",
    "12'h724" "CSR_MHPMEVENT4H",
    "12'h725" "CSR_MHPMEVENT5H",
    "12'h726" "CSR_MHPMEVENT6H",
    "12'h727" "CSR_MHPMEVENT7H",
    "12'h728" "CSR_MHPMEVENT8H",
    "12'h729" "CSR_MHPMEVENT9H",
    "12'h72a" "CSR_MHPMEVENT10H",
    "12'h72b" "CSR_MHPMEVENT11H",
    "12'h72c" "CSR_MHPMEVENT12H",
    "12'h72d" "CSR_MHPMEVENT13H",
    "12'h72e" "CSR_MHPMEVENT14H",
    "12'h72f" "CSR_MHPMEVENT15H",
    "12'h730" "CSR_MHPMEVENT16H",
    "12'h731" "CSR_MHPMEVENT17H",
    "12'h732" "CSR_MHPMEVENT18H",
    "12'h733" "CSR_MHPMEVENT19H",
    "12'h734" "CSR_MHPMEVENT20H",
    "12'h735" "CSR_MHPMEVENT21H",
    "12'h736" "CSR_MHPMEVENT22H",
    "12'h737" "CSR_MHPMEVENT23H",
    "12'h738" "CSR_MHPMEVENT24H",
    "12'h739" "CSR_MHPMEVENT25H",
    "12'h73a" "CSR_MHPMEVENT26H",
    "12'h73b" "CSR_MHPMEVENT27H",
    "12'h73c" "CSR_MHPMEVENT28H",
    "12'h73d" "CSR_MHPMEVENT29H",
    "12'h73e" "CSR_MHPMEVENT30H",
    "12'h73f" "CSR_MHPMEVENT31H",
    "12'h740" "CSR_MNSCRATCH",
    "12'h741" "CSR_MNEPC",
    "12'h742" "CSR_MNCAUSE",
    "12'h744" "CSR_MNSTATUS",
    "12'h757" "CSR_MSECCFGH",
    "12'hb80" "CSR_MCYCLEH",
    "12'hb82" "CSR_MINSTRETH",
    "12'hb83" "CSR_MHPMCOUNTER3H",
    "12'hb84" "CSR_MHPMCOUNTER4H",
    "12'hb85" "CSR_MHPMCOUNTER5H",
    "12'hb86" "CSR_MHPMCOUNTER6H",
    "12'hb87" "CSR_MHPMCOUNTER7H",
    "12'hb88" "CSR_MHPMCOUNTER8H",
    "12'hb89" "CSR_MHPMCOUNTER9H",
    "12'hb8a" "CSR_MHPMCOUNTER10H",
    "12'hb8b" "CSR_MHPMCOUNTER11H",
    "12'hb8c" "CSR_MHPMCOUNTER12H",
    "12'hb8d" "CSR_MHPMCOUNTER13H",
    "12'hb8e" "CSR_MHPMCOUNTER14H",
    "12'hb8f" "CSR_MHPMCOUNTER15H",
    "12'hb90" "CSR_MHPMCOUNTER16H",
    "12'hb91" "CSR_MHPMCOUNTER17H",
    "12'hb92" "CSR_MHPMCOUNTER18H",
    "12'hb93" "CSR_MHPMCOUNTER19H",
    "12'hb94" "CSR_MHPMCOUNTER20H",
    "12'hb95" "CSR_MHPMCOUNTER21H",
    "12'hb96" "CSR_MHPMCOUNTER22H",
    "12'hb97" "CSR_MHPMCOUNTER23H",
    "12'hb98" "CSR_MHPMCOUNTER24H",
    "12'hb99" "CSR_MHPMCOUNTER25H",
    "12'hb9a" "CSR_MHPMCOUNTER26H",
    "12'hb9b" "CSR_MHPMCOUNTER27H",
    "12'hb9c" "CSR_MHPMCOUNTER28H",
    "12'hb9d" "CSR_MHPMCOUNTER29H",
    "12'hb9e" "CSR_MHPMCOUNTER30H",
    "12'hb9f" "CSR_MHPMCOUNTER31H",
    -default default
}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Input / Output Signals}
add wave -noupdate -group JTAG /system_tb/board/jtag_tck_i
add wave -noupdate -group JTAG /system_tb/board/jtag_tdi_i
add wave -noupdate -group JTAG /system_tb/board/jtag_tdo_o
add wave -noupdate -group JTAG /system_tb/board/jtag_tms_i
add wave -noupdate -group JTAG /system_tb/board/jtag_trst_ni
add wave -noupdate -group JTAG /system_tb/board/jtag_srst_ni
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dq
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dqs_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dqs_p
add wave -noupdate -group DDR3 /system_tb/board/ddr3_addr
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ba
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ras_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_cas_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_we_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_reset_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ck_p
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ck_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_cke
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dm
add wave -noupdate -group DDR3 /system_tb/board/ddr3_odt
add wave -noupdate -group {User I/O} /system_tb/board/switch_i
add wave -noupdate -group {User I/O} /system_tb/board/uart_rx_out
add wave -noupdate -group {User I/O} /system_tb/board/uart_tx_in
add wave -noupdate -group {User I/O} /system_tb/board/ps2_clk
add wave -noupdate -group {User I/O} /system_tb/board/ps2_data
add wave -noupdate -group {User I/O} /system_tb/board/scl
add wave -noupdate -group {User I/O} /system_tb/board/sda
add wave -noupdate -group {User I/O} /system_tb/board/oled_sdin
add wave -noupdate -group {User I/O} /system_tb/board/oled_sclk
add wave -noupdate -group {User I/O} /system_tb/board/oled_dc
add wave -noupdate -group {User I/O} /system_tb/board/oled_res
add wave -noupdate -group {User I/O} /system_tb/board/oled_vbat
add wave -noupdate -group {User I/O} /system_tb/board/oled_vdd
add wave -noupdate -group {User I/O} /system_tb/board/ac_adc_sdata
add wave -noupdate -group {User I/O} /system_tb/board/ac_bclk
add wave -noupdate -group {User I/O} /system_tb/board/ac_lrclk
add wave -noupdate -group {User I/O} /system_tb/board/ac_mclk
add wave -noupdate -group {User I/O} /system_tb/board/ac_dac_sdata
add wave -noupdate -group {User I/O} /system_tb/board/sd_sck
add wave -noupdate -group {User I/O} /system_tb/board/sd_mosi
add wave -noupdate -group {User I/O} /system_tb/board/sd_cs
add wave -noupdate -group {User I/O} /system_tb/board/sd_reset
add wave -noupdate -group {User I/O} /system_tb/board/sd_cd
add wave -noupdate -group {User I/O} /system_tb/board/sd_miso
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_clk_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_clk_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_cec
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_scl
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_sda
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_hpa
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_txen
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_clk_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_clk_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_cec
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_rscl
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_rsda
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_hpd
add wave -noupdate -group {User I/O} /system_tb/board/eth_rxd
add wave -noupdate -group {User I/O} /system_tb/board/eth_rxctl
add wave -noupdate -group {User I/O} /system_tb/board/eth_rxck
add wave -noupdate -group {User I/O} /system_tb/board/eth_txd
add wave -noupdate -group {User I/O} /system_tb/board/eth_txctl
add wave -noupdate -group {User I/O} /system_tb/board/eth_txck
add wave -noupdate -group {User I/O} /system_tb/board/eth_mdio
add wave -noupdate -group {User I/O} /system_tb/board/eth_mdc
add wave -noupdate -group {User I/O} /system_tb/board/eth_int_b
add wave -noupdate -group {User I/O} /system_tb/board/eth_pme_b
add wave -noupdate -group {User I/O} /system_tb/board/eth_rst_b
add wave -noupdate /system_tb/board/led_o
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate /system_tb/board/DUT/sys_clk
add wave -noupdate /system_tb/board/DUT/dbg_rst_n
add wave -noupdate /system_tb/board/DUT/sys_rst_n
add wave -noupdate -divider CPU
add wave -noupdate -group {CPU Registers} -label {ra (x1)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[1]}
add wave -noupdate -group {CPU Registers} -label {sp (x2)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[2]}
add wave -noupdate -group {CPU Registers} -label {gp (x3)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[3]}
add wave -noupdate -group {CPU Registers} -label {tp (x4)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[4]}
add wave -noupdate -group {CPU Registers} -label {t0 (x5)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[5]}
add wave -noupdate -group {CPU Registers} -label {t1 (x6)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[6]}
add wave -noupdate -group {CPU Registers} -label {t2 (x7)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[7]}
add wave -noupdate -group {CPU Registers} -label {s0 (x8)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[8]}
add wave -noupdate -group {CPU Registers} -label {s1 (x9)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[9]}
add wave -noupdate -group {CPU Registers} -label {a0 (x10)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[10]}
add wave -noupdate -group {CPU Registers} -label {a1 (x11)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[11]}
add wave -noupdate -group {CPU Registers} -label {a2 (x12)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[12]}
add wave -noupdate -group {CPU Registers} -label {a3 (x13)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[13]}
add wave -noupdate -group {CPU Registers} -label {a4 (x14)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[14]}
add wave -noupdate -group {CPU Registers} -label {a5 (x15)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[15]}
add wave -noupdate -group {CPU Registers} -label {a6 (x16)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[16]}
add wave -noupdate -group {CPU Registers} -label {a7 (x17)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[17]}
add wave -noupdate -group {CPU Registers} -label {s2 (x18)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[18]}
add wave -noupdate -group {CPU Registers} -label {s3 (x19)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[19]}
add wave -noupdate -group {CPU Registers} -label {s4 (x20)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[20]}
add wave -noupdate -group {CPU Registers} -label {s5 (x21)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[21]}
add wave -noupdate -group {CPU Registers} -label {s6 (x22)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[22]}
add wave -noupdate -group {CPU Registers} -label {s7 (x23)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[23]}
add wave -noupdate -group {CPU Registers} -label {s8 (x24)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[24]}
add wave -noupdate -group {CPU Registers} -label {s9 (x25)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[25]}
add wave -noupdate -group {CPU Registers} -label {s10 (x26)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[26]}
add wave -noupdate -group {CPU Registers} -label {s11 (x27)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[27]}
add wave -noupdate -group {CPU Registers} -label {t3 (x28)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[28]}
add wave -noupdate -group {CPU Registers} -label {t4 (x29)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[29]}
add wave -noupdate -group {CPU Registers} -label {t5 (x30)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[30]}
add wave -noupdate -group {CPU Registers} -label {t6 (x31)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/register_file_i/mem[31]}
add wave -noupdate /system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/pc_id_i
add wave -noupdate /system_tb/board/DUT/core_i/cpu_i/u_core_default/core_i/id_stage_i/instr_rdata_i
add wave -noupdate -divider TL-UL
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpui_h2d
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpui_d2h
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpud_h2d
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpud_d2h
add wave -noupdate /system_tb/board/DUT/core_i/tl_bram_main_h2d
add wave -noupdate /system_tb/board/DUT/core_i/tl_bram_main_d2h
add wave -noupdate -divider {Running Light}
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/led_o
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/regA
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/regB
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/state
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/cnt
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/addr
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/rdata
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/re
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/wdata
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/we
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {40160000000 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 732
configure wave -valuecolwidth 288
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {227074683962 fs}
