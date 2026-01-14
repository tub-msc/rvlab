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
	asm volatile ("csrs mie, %0":: "r" (mask));
}

inline void irq_disable(int mask) {
	asm volatile ("csrc mie, %0":: "r" (mask));
}

/*
#define MCYCLE (0xB00)

#define FENCE ({asm volatile("": : :"memory");})
*/

#endif // _REGACCESS_H
