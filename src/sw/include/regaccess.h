/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#ifndef _REGACCESS_H
#define _REGACCESS_H

#include <stdint.h>

// Main memory access macros:

#define REG8(addr) *((volatile uint8_t *)(addr))
#define REG16(addr) *((volatile uint16_t *)(addr))
#define REG32(addr) *((volatile uint32_t *)(addr))

// CPU CSR access macros:

#define read_csr(reg) ({ unsigned long __tmp; \
    asm volatile ("csrr %0, " reg : "=r"(__tmp)); \
    __tmp; })

#define write_csr(reg, val) ({ \
    asm volatile ("csrw " reg ", %0" :: "rK"(val)); })

#define clear_csr_bits(reg, bitmask) ({ \
    asm volatile ("csrc " reg ", %0" :: "r"(bitmask)); })

#define set_csr_bits(reg, bitmask) ({ \
    asm volatile ("csrs " reg ", %0" :: "r"(bitmask)); })

inline void irq_enable(int mask) {
    set_csr_bits("mie", mask);
}

inline void irq_disable(int mask) {
    clear_csr_bits("mie", mask);
}

#define MCOUNTINHIBIT_MCYCLE   (1 << 0)
#define MCOUNTINHIBIT_MINSTRET (1 << 2)

/* Specific CSR Access Wrappers */

// MHPM Event names (Assigned by OpenHW Group)
#define MHPM_EVENT_LD_STALL     (1 << 2)
#define MHPM_EVENT_JMP_STALL    (1 << 3)
#define MHPM_EVENT_IMISS        (1 << 4)
#define MHPM_EVENT_LD           (1 << 5)
#define MHPM_EVENT_ST           (1 << 6)
#define MHPM_EVENT_JUMP         (1 << 7)
#define MHPM_EVENT_BRANCH       (1 << 8)
#define MHPM_EVENT_BRANCH_TAKEN (1 << 9)
#define MHPM_EVENT_COMP_INSTR   (1 << 10)
#define MHPM_EVENT_PIPE_STALL   (1 << 11)

// Assigned MHPM Counter registers (arbitrary choice)
// Note: CV32E40P has MHPM Counters indexed 3-31, so
//       index 2 cannot be used to start
//       See https://docs.openhwgroup.org/projects/cv32e40p-user-manual/en/latest/control_status_registers.html
#define MHPM_LD_STALL     3
#define MHPM_JMP_STALL    4
#define MHPM_IMISS        5
#define MHPM_LD           6
#define MHPM_ST           7
#define MHPM_JUMP         8
#define MHPM_BRANCH       9
#define MHPM_BRANCH_TAKEN 10
#define MHPM_COMP_INSTR   11
#define MHPM_PIPE_STALL   12

#endif // _REGACCESS_H
