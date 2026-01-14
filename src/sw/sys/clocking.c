// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

#include <stdio.h>
#include <stdint.h>

#include "rvlab.h"
#include "clocking.h"

/////////////////////
//                 //
// SYSCLOCK (CLK0) //
//                 //
/////////////////////


/* Safety features */

#define RV_CLK_CLKSAFETY_STATUS (RV_CLK_BASE_ADDR + 0x108)
#define RV_CLK_CLKSAFETY_DUMMY (RV_CLK_BASE_ADDR + 0x10C)

// Safety Module status (error code)
// Used on reset to determine whether reset was caused by Safety Module
static inline uint32_t rv_clk_get_clksafety_status() {
    return REG32(RV_CLK_CLKSAFETY_STATUS); // swro
}

// Obtain special read-only value for safety calculation
static inline uint32_t rv_clk_get_clksafety_dummy() {
    return REG32(RV_CLK_CLKSAFETY_DUMMY);
}

// Update safety module
// (to help determine whether system is stable)
static inline void rv_clk_set_clksafety_dummy(uint32_t val) {
    REG32(RV_CLK_CLKSAFETY_DUMMY) = val;
}

// noinline attribute forces use of call/ret instructions + stack usage
__attribute__((noinline)) uint32_t __rv_clk_sysclk_safety_calculation(volatile uint32_t *initial_value) {
	volatile uint32_t safety = *initial_value;								// LW, SW
	volatile uint8_t safety_lower = safety & 0xFF; 							// AND, SB
	volatile uint8_t safety_lowest_inverted = safety_lower | 0xFFFFFFF0; 	// OR, LBU, LUI
	safety_lowest_inverted = ~safety_lowest_inverted;
	safety = safety + 0x326b; 												// ADDI
	safety = safety << safety_lowest_inverted;								// LSH
	safety = safety - safety_lower;											// SUB
	safety = safety >> safety_lowest_inverted;								// SRL
	register uint8_t tmp = safety > 0xCBA ? safety_lower & 0x2 : 0x24; 		// SLT
	safety = safety | (tmp << 2);
	safety = safety / safety_lower;
	safety = safety * 25;
	safety = safety == 0xbb22d947 ? safety - 200 : safety + 3;
	return safety;
}

// Called once on init from crt0.S
int sysclk_status_check(void) {
	uint32_t status = rv_clk_get_clksafety_status();
	if (status == 0) return 0;

	#define RVLAB_STRING "[\033[36mRVLAB\033[0m]"

	/* SoC has undergone a safety reset */
	printf(
		"\n"
		"\n"
		" -------------------- \033[31;1mCRITICAL ERROR\033[0m -------------------- \n"
		RVLAB_STRING " The RVLab SoC has performed a safety reset.\n"
		RVLAB_STRING " This is most likely because you tried to set\n"
		RVLAB_STRING " the system clock to a too high frequency.\n"
		RVLAB_STRING " Consider using a higher divider value.\n"
		RVLAB_STRING " \n"
		RVLAB_STRING " If you believe this to be an error, consult the\n"
		RVLAB_STRING " RVLab documentation section on variable clocking.\n"
		RVLAB_STRING " \n"
		RVLAB_STRING " If you would like to change default behavior,\n"
		RVLAB_STRING " edit \033[3msw/sys/clocking.c\033[0m and rebuild\n"
		RVLAB_STRING " libc using \033[1mflow libsys.build\033[0m.\n"
		RVLAB_STRING " \n"
		RVLAB_STRING " Error code: "
	);
	switch (status) {
		case 1:
			printf("01 FetchWait Timeout\n");
			break;
		case 2:
			printf("10 Wrong Safety Data\n");
			break;
		case 3:
			printf("11 Verification Timeout\n");
			break;
		default:
			printf("(Unknown error 0x%08x)\n", status);
			break;
	}

	/* Busy wait loop to ensure messages get printed */
	for (int i = 0; i < 100000; i++);
	return -2;
}

/* Actual SysClock */

#define RV_CLK_CLKDIV_SYS (RV_CLK_BASE_ADDR + 0x100)

uint32_t rvlab_get_sysclock() {
    return REG32(RV_CLK_CLKDIV_SYS);
}

void rvlab_set_sysclock(uint32_t div) {
	REG32(RV_CLK_CLKDIV_SYS) = div;
	/* Memory fence to ensure clock div gets written to before dummy value fetch */
	__asm__ volatile("fence w, w" ::: "memory");
	/* Safety value calculation */
	uint32_t __rv_clk_clksafety_val = rv_clk_get_clksafety_dummy();
	__rv_clk_clksafety_val = __rv_clk_sysclk_safety_calculation(&__rv_clk_clksafety_val);
	/* Setting safety value will reset SoC / sysclock divider if it is incorrect */
	rv_clk_set_clksafety_dummy(__rv_clk_clksafety_val);
}



//////////////////////////////
//                          //
// Other MMCM output clocks //
//                          //
//////////////////////////////

/* Addresses */

/* Feel free to rename these */
#define RV_CLK_CLKDIV_1 (RV_CLK_BASE_ADDR + 0x110)
#define RV_CLK_CLKDIV_2 (RV_CLK_BASE_ADDR + 0x120)
#define RV_CLK_CLKDIV_3 (RV_CLK_BASE_ADDR + 0x130)
#define RV_CLK_CLKDIV_4 (RV_CLK_BASE_ADDR + 0x140)
#define RV_CLK_CLKDIV_5 (RV_CLK_BASE_ADDR + 0x150)
#define RV_CLK_CLKDIV_6 (RV_CLK_BASE_ADDR + 0x160)

/* Getter functions */

inline uint32_t rv_clk_get_clk1_div() {
    return REG32(RV_CLK_CLKDIV_1);
}

inline uint32_t rv_clk_get_clk2_div() {
    return REG32(RV_CLK_CLKDIV_2);
}

inline uint32_t rv_clk_get_clk3_div() {
    return REG32(RV_CLK_CLKDIV_3);
}

inline uint32_t rv_clk_get_clk4_div() {
    return REG32(RV_CLK_CLKDIV_4);
}

inline uint32_t rv_clk_get_clk5_div() {
    return REG32(RV_CLK_CLKDIV_5);
}

inline uint32_t rv_clk_get_clk6_div() {
    return REG32(RV_CLK_CLKDIV_6);
}

/* Setter functions */

inline void rv_clk_set_clk1_div(uint32_t div) {
    REG32(RV_CLK_CLKDIV_1) = div;
}

inline void rv_clk_set_clk2_div(uint32_t div) {
    REG32(RV_CLK_CLKDIV_2) = div;
}

inline void rv_clk_set_clk3_div(uint32_t div) {
    REG32(RV_CLK_CLKDIV_3) = div;
}

inline void rv_clk_set_clk4_div(uint32_t div) {
    REG32(RV_CLK_CLKDIV_4) = div;
}

inline void rv_clk_set_clk5_div(uint32_t div) {
    REG32(RV_CLK_CLKDIV_5) = div;
}

inline void rv_clk_set_clk6_div(uint32_t div) {
    REG32(RV_CLK_CLKDIV_6) = div;
}