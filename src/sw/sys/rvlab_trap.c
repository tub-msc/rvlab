/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2026 RVLab Contributors
 */

#include <stdio.h>
#include <rvlab.h>
#include <stdbool.h>

///////////////
//           //
// UTILITIES //
//           //
///////////////

// Exception Causes [adapted from src/rtl/cv32e40p/pkg/cv32e40p_pkg.sv]
#define EXC_CAUSE_INSTR_FAULT 0x01
#define EXC_CAUSE_ILLEGAL_INSN 0x02
#define EXC_CAUSE_BREAKPOINT 0x03
#define EXC_CAUSE_LOAD_FAULT 0x05
#define EXC_CAUSE_STORE_FAULT 0x07
#define EXC_CAUSE_ECALL_UMODE 0x08
#define EXC_CAUSE_ECALL_MMODE 0x0B

static const char *mcause_to_string(uint32_t mcause) {
	mcause = mcause & 0x1F; // extract exception code
	switch (mcause) {
		case EXC_CAUSE_INSTR_FAULT : return "INSTR_FAULT";
		case EXC_CAUSE_ILLEGAL_INSN: return "ILLEGAL_INSN";
		case EXC_CAUSE_BREAKPOINT  : return "BREAKPOINT";
		case EXC_CAUSE_LOAD_FAULT  : return "LOAD_FAULT";
		case EXC_CAUSE_STORE_FAULT : return "STORE_FAULT";
		case EXC_CAUSE_ECALL_UMODE : return "ECALL_UMODE";
		case EXC_CAUSE_ECALL_MMODE : return "ECALL_MMODE";
		default: return "Unknown mcause";
	}
}

int trap_handler_default() {
	uint32_t mepc = read_csr("mepc");
	uint32_t mcause = read_csr("mcause");
	bool is_exception = !(mcause & 0x80000000);

	if (is_exception) {
		printf("Encountered internal exception, MEPC: 0x%08x, MCAUSE: %s\n",
			mepc, mcause_to_string(mcause));
		return -2;
	}

	printf("Encountered IRQ Error, MEPC: 0x%08x, MCAUSE: 0x%08x\n", mepc, mcause);
	return -1;
}

// To resume execution of a program after trapping, trap handler overrides
// should call this function:
__attribute__((noreturn))
void return_from_trap(void)
{
	asm volatile (
		// IRQ stack position may have been modified by the handler
		// Restore it for the next call
		"lui  sp,     %hi(_irq_stack_top)\n"
		"addi sp, sp, %lo(_irq_stack_top)\n"
		"addi sp, sp, -0x80\n"
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

///////////////////////////////
//                           //
// OVERRIDABLE TRAP HANDLERS //
//                           //
///////////////////////////////


int __attribute__((weak)) instr_fault_handler(void) { return trap_handler_default(); }

int __attribute__((weak)) illegal_insn_handler(void) { return trap_handler_default(); }

int __attribute__((weak)) breakpoint_handler(void) { return trap_handler_default(); }

// load_fault_handler is overridden by DDR3 availability check
int __attribute__((weak)) load_fault_handler(void) { return trap_handler_default(); }

int __attribute__((weak)) store_fault_handler(void) { return trap_handler_default(); }

int __attribute__((weak)) ecall_umode_handler(void) { return trap_handler_default(); }

int __attribute__((weak)) ecall_mmode_handler(void) { return trap_handler_default(); }

int __attribute__((weak)) irq_error_handler(void) { return trap_handler_default(); }


//////////////////////////
//                      //
// MAIN TRAP ENTRYPOINT //
//                      //
//////////////////////////

int rvlab_trap(void) {
	// IRQ error or exception encountered, read MCause to direct handling

	uint32_t mcause = read_csr("mcause");
	uint32_t masked_mcause = mcause & 0x1F;
	bool is_irq_error = mcause & 0x80000000;

	if (is_irq_error) {
		return irq_error_handler();
	}

	// Exception
	switch (masked_mcause) {
		case EXC_CAUSE_INSTR_FAULT : return instr_fault_handler();
		case EXC_CAUSE_ILLEGAL_INSN: return illegal_insn_handler();
		case EXC_CAUSE_BREAKPOINT  : return breakpoint_handler();
		case EXC_CAUSE_LOAD_FAULT  : return load_fault_handler();
		case EXC_CAUSE_STORE_FAULT : return store_fault_handler();
		case EXC_CAUSE_ECALL_UMODE : return ecall_umode_handler();
		case EXC_CAUSE_ECALL_MMODE : return ecall_mmode_handler();
		default: ;
	}

	return -3;
}
