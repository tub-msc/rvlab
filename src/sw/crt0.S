// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2024 RVLab Contributors

    .section .text.boot
    .option push
    .option norvc
    .org 0

    j irq_error     //  0: Exceptions (illegal instruction, ecall, instruction access fault, ...)
    nop             //  1
    nop             //  2
    nop             //  3
    nop             //  4
    nop             //  5
    j irq_error     //  6
    j irq_entry     //  7: Machine timer interrupt (irq_timer_i)
    nop             //  8
    nop             //  9
    j irq_error     // 10
    j irq_entry     // 11: Machine external interrupt (irq_external_i)
    nop             // 12
    nop             // 13
    nop             // 14
    nop             // 15
    nop             // 16 16..31: Vendor specific IRQs. Ibex: 16..30: External fast IRQs
    nop             // 17
    nop             // 18
    nop             // 19
    nop             // 20
    nop             // 21
    nop             // 22
    nop             // 23
    nop             // 24
    nop             // 25
    nop             // 26
    nop             // 27
    nop             // 28
    nop             // 29
    nop             // 30
    j irq_error     // 31  Ibex: NMI
    j _start        // 32: Reset vector / global entry point

    .option pop

    .global _start
_start:

    //  x0 == zero
    li  x1, 0
    //  x2 == sp
    li  x3, 0
    li  x4, 0
    li  x5, 0
    li  x6, 0
    li  x7, 0
    li  x8, 0
    li  x9, 0
    li  x10,0
    li  x11,0
    li  x12,0
    li  x13,0
    li  x14,0
    li  x15,0
    li  x16,0
    li  x17,0
    li  x18,0
    li  x19,0
    li  x20,0
    li  x21,0
    li  x22,0
    li  x23,0
    li  x24,0
    li  x25,0
    li  x26,0
    li  x27,0
    li  x28,0
    li  x29,0
    li  x30,0
    li  x31,0

    csrrci zero, mcountinhibit, 5 // enable mcycle + minstret counters

    // write irq thread stack pointer to mscratch CSR
    lui sp,      %hi(_irq_stack_top)
    addi sp, sp, %lo(_irq_stack_top)
    csrrw zero, mscratch, sp

    // initialize main thread stack pointer
    lui  sp,     %hi(_main_stack_top)
    addi sp, sp, %lo(_main_stack_top)

    jal hostio_init

    csrs mstatus, 0x8 // global interrupt enable

    jal main

    csrc mstatus, 0x8 // global interrupt disable

    lui  t0,     %hi(hostio + 0x800)
    addi t0, t0, %lo(hostio + 0x800)
    sw a0, 4(t0) // _hostid_start.retval = return value of main
    addi t1, zero, 1
    sw t1, 0(t0) // _hostid_start.flags = 1;


irq_error:
end_loop:
    j end_loop


irq_entry:
    // swap main thread sp with irq sp
    csrrw sp,mscratch,sp

    // save registers to irq stack
    addi sp,sp,-0x80
    //  x0 == zero
    sw  x1,  0x00(sp)
    //  x2 == sp
    sw  x3,  0x04(sp)
    sw  x4,  0x08(sp)
    sw  x5,  0x0c(sp)
    sw  x6,  0x10(sp)
    sw  x7,  0x14(sp)
    sw  x8,  0x18(sp)
    sw  x9,  0x1c(sp)
    sw  x10, 0x20(sp)
    sw  x11, 0x24(sp)
    sw  x12, 0x28(sp)
    sw  x13, 0x2c(sp)
    sw  x14, 0x30(sp)
    sw  x15, 0x34(sp)
    sw  x16, 0x38(sp)
    sw  x17, 0x3c(sp)
    sw  x18, 0x40(sp)
    sw  x19, 0x44(sp)
    sw  x20, 0x48(sp)
    sw  x21, 0x4c(sp)
    sw  x22, 0x50(sp)
    sw  x23, 0x54(sp)
    sw  x24, 0x58(sp)
    sw  x25, 0x5c(sp)
    sw  x26, 0x60(sp)
    sw  x27, 0x64(sp)
    sw  x28, 0x68(sp)
    sw  x29, 0x6c(sp)
    sw  x30, 0x70(sp)
    sw  x31, 0x74(sp)

    jal irq_handler

    // restore registers from irq stack
    //  x0 == zero
    lw  x1,  0x00(sp)
    //  x2 == sp
    lw  x3,  0x04(sp)
    lw  x4,  0x08(sp)
    lw  x5,  0x0c(sp)
    lw  x6,  0x10(sp)
    lw  x7,  0x14(sp)
    lw  x8,  0x18(sp)
    lw  x9,  0x1c(sp)
    lw  x10, 0x20(sp)
    lw  x11, 0x24(sp)
    lw  x12, 0x28(sp)
    lw  x13, 0x2c(sp)
    lw  x14, 0x30(sp)
    lw  x15, 0x34(sp)
    lw  x16, 0x38(sp)
    lw  x17, 0x3c(sp)
    lw  x18, 0x40(sp)
    lw  x19, 0x44(sp)
    lw  x20, 0x48(sp)
    lw  x21, 0x4c(sp)
    lw  x22, 0x50(sp)
    lw  x23, 0x54(sp)
    lw  x24, 0x58(sp)
    lw  x25, 0x5c(sp)
    lw  x26, 0x60(sp)
    lw  x27, 0x64(sp)
    lw  x28, 0x68(sp)
    lw  x29, 0x6c(sp)
    lw  x30, 0x70(sp)
    lw  x31, 0x74(sp)
    addi sp,sp, 0x80

    // swap main thread sp with irq sp
    csrrw sp,mscratch,sp

    // return to main thread
    mret
