/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2026 RVLab Contributors
 */

#include <stdbool.h>
#include <stdio.h>
#include <rvlab.h>

static volatile bool ddr_present = 1;
static volatile bool is_checking_ddr_availability = 0;

__attribute__((noreturn))
static void return_from_trap(void)
{
    asm volatile (
    	// restore registers from irq stack
	    //  x0 == zero
	    "lw  x1,  0x00(sp)\n"
	    //  x2 == sp
	    "lw  x3,  0x04(sp)\n"
	    "lw  x4,  0x08(sp)\n"
	    "lw  x5,  0x0c(sp)\n"
	    "lw  x6,  0x10(sp)\n"
	    "lw  x7,  0x14(sp)\n"
	    "lw  x8,  0x18(sp)\n"
	    "lw  x9,  0x1c(sp)\n"
	    "lw  x10, 0x20(sp)\n"
	    "lw  x11, 0x24(sp)\n"
	    "lw  x12, 0x28(sp)\n"
	    "lw  x13, 0x2c(sp)\n"
	    "lw  x14, 0x30(sp)\n"
	    "lw  x15, 0x34(sp)\n"
	    "lw  x16, 0x38(sp)\n"
	    "lw  x17, 0x3c(sp)\n"
	    "lw  x18, 0x40(sp)\n"
	    "lw  x19, 0x44(sp)\n"
	    "lw  x20, 0x48(sp)\n"
	    "lw  x21, 0x4c(sp)\n"
	    "lw  x22, 0x50(sp)\n"
	    "lw  x23, 0x54(sp)\n"
	    "lw  x24, 0x58(sp)\n"
	    "lw  x25, 0x5c(sp)\n"
	    "lw  x26, 0x60(sp)\n"
	    "lw  x27, 0x64(sp)\n"
	    "lw  x28, 0x68(sp)\n"
	    "lw  x29, 0x6c(sp)\n"
	    "lw  x30, 0x70(sp)\n"
	    "lw  x31, 0x74(sp)\n"
	    "addi sp,sp, 0x80\n"

	    // swap main thread sp with irq sp
	    "csrrw sp,mscratch,sp\n"
    	"mret"
    );
    __builtin_unreachable();
}

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
