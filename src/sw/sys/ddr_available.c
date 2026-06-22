/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2026 RVLab Contributors
 */

#include <stdbool.h>
#include <stdio.h>
#include <rvlab.h>

static volatile bool ddr_present = 1;
static volatile bool is_checking_ddr_availability = 0;

__attribute__ ((noreturn)) void return_from_trap();
int trap_handler_default();

int load_fault_handler(void) {
	if (is_checking_ddr_availability) {
		ddr_present = 0;

		// Go to next instruction (after faulting instruction @ mepc)
		uint32_t mepc = read_csr("mepc");
		uint16_t insn_halfword = *(uint16_t*)mepc;

		if ((insn_halfword & 0x3) == 0x3) {
			write_csr("mepc", mepc + 4);
		} else {
			write_csr("mepc", mepc + 2);
		}

		return_from_trap();
	} else return trap_handler_default();
}

bool ddr_available() {
	is_checking_ddr_availability = 1;

	asm volatile ("" ::: "memory");	// Prevent compiler memory access reordering
	*((volatile uint32_t *)DDR3_BASE_ADDR);
	asm volatile ("" ::: "memory");

	is_checking_ddr_availability = 0;
	return ddr_present;
}
