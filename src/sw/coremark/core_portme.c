/*
Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Original Author: Shay Gal-on
*/

/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2026 RVLab Contributors
 */

#include "coremark.h"
#include "core_portme.h"

#include "regaccess.h"

#include <stdint.h>
#include <inttypes.h>

#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;


// Pretty string for colorful printing :)
#define RVLAB_STRING "[\033[36mRVLAB\033[0m]"
#define RVLAB_HEADER ee_printf(RVLAB_STRING " ");


/* Performance measurement related utilities */
#define disable_performance_counters() set_csr_bits("mcountinhibit", MCOUNTINHIBIT_MCYCLE | MCOUNTINHIBIT_MINSTRET)
#define enable_performance_counters() clear_csr_bits("mcountinhibit", MCOUNTINHIBIT_MCYCLE | MCOUNTINHIBIT_MINSTRET)

#define __STRINGIFY(name) #name
#define __STR_EVAL(name) __STRINGIFY(name) // preprocessor hack

// e.g. passing LD to name   -> write_csr("mhpmevent6", (1 << 5))
#define SETUP_MHPMCOUNTER(name) write_csr("mhpmevent" __STR_EVAL(MHPM_ ## name), MHPM_EVENT_ ## name)

// e.g. passing LD to name  -> printf("Number of load instructions : %d\n", read_csr("mhpmcounter6"))
#define DUMP_MHPMCOUNTER(name) printf("Number of " MHPM_NAME_ ## name " : %10d [0x%08x_%08x]\n", \
  (uint32_t)read_csr("mhpmcounter" __STR_EVAL(MHPM_ ## name)), \
  (uint32_t)read_csr("mhpmcounter" __STR_EVAL(MHPM_ ## name) "h"), read_csr("mhpmcounter" __STR_EVAL(MHPM_ ## name)))


/* Porting : Timing functions
        How to capture time and convert to seconds must be ported to whatever is
   supported by the platform. e.g. Read value from on board RTC, read value from
   cpu clock cycles performance counter etc. Sample implementation for standard
   time.h and windows.h definitions included.
*/


/* Clock- and timing-related utilities */
#define VCO_MHz 1200

 // Synchronize with clkmgr's sysclk clock divisor
#define CM_STATIC_SYSCLK_PRESCALER 24
#define CM_STATIC_SYSCLK_MHZ (VCO_MHz / CM_STATIC_SYSCLK_PRESCALER)
// ticks per second
#define CM_STATIC_TPS ((VCO_MHz * 1000000) / CM_STATIC_SYSCLK_PRESCALER)

static inline uint32_t get_sysclk_mhz() {
    return CM_STATIC_SYSCLK_MHZ;
}

static inline uint32_t get_sysclk_khz() {
    return (1000 * VCO_MHz) / CM_STATIC_SYSCLK_PRESCALER;
}

static inline uint32_t get_ticks_per_second() {
    // 1 tick = 1 cycle, i.e. return clock speed in Hz
    return CM_STATIC_TPS;
}


CORETIMETYPE
barebones_clock()
{
    /* Read out full 64 bits of mcycle */

    disable_performance_counters();

    // Read mcycle and mcycleh
    uint64_t mcycle_l = read_csr("mcycle");
    uint64_t mcycle_h = read_csr("mcycleh");
    uint64_t mcycle = (mcycle_h << 32) | mcycle_l;

    enable_performance_counters();

    /* mcycle value = CoreMark ticks */
    // This 1-to-1 mapping allows for a maximum execution time of
    // ~2^32 cycles, or about 42 seconds @ 100MHz (thus being
    // sufficient for CoreMark)

	return (CORETIMETYPE)(mcycle);
}
/* Define : TIMER_RES_DIVIDER
        Divider to trade off timer resolution and total time that can be
   measured.

        Use lower values to increase resolution, but make sure that overflow
   does not occur. If there are issues with the return value overflowing,
   increase this value.
        */
#define GETMYTIME(_t)              (*_t = barebones_clock())
#define MYTIMEDIFF(fin, ini)       ((fin) - (ini))

/** Define Host specific (POSIX), or target specific global time variables. */
static CORETIMETYPE start_time_val, stop_time_val;

/* Function : start_time
        This function will be called right before starting the timed portion of
   the benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or zeroing some system parameters - e.g. setting the cpu clocks
   cycles to 0.
*/
void
start_time(void)
{
    GETMYTIME(&start_time_val);
}
/* Function : stop_time
        This function will be called right after ending the timed portion of the
   benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or other system parameters - e.g. reading the current value of
   cpu cycles counter.
*/
void
stop_time(void)
{
    GETMYTIME(&stop_time_val);

    // This function is called once right before main CoreMark output, so:
    RVLAB_HEADER ee_printf("CoreMark output:\033[1m\n\n");
}
/* Function : get_time
        Return an abstract "ticks" number that signifies time on the system.

        Actual value returned may be cpu cycles, milliseconds or any other
   value, as long as it can be converted to seconds by <time_in_secs>. This
   methodology is taken to accommodate any hardware or simulated platform. The
   sample implementation returns millisecs by default, and the resolution is
   controlled by <TIMER_RES_DIVIDER>
*/
CORE_TICKS
get_time(void)
{
    CORE_TICKS elapsed
        = (CORE_TICKS)(MYTIMEDIFF(stop_time_val, start_time_val));
    return elapsed;
}

/* Function : time_in_secs
        Convert the value returned by get_time to seconds.

        The <secs_ret> type is used to accommodate systems with no support for
   floating point. Default implementation implemented by the EE_TICKS_PER_SEC
   macro above.
*/
secs_ret
time_in_secs(CORE_TICKS ticks)
{
    // Calculate ticks per second

    secs_ret retval = ticks / get_ticks_per_second();

    return retval;
}

ee_u32 default_num_contexts = 1;

/* Function : portable_init
        Target specific initialization code
        Test for some common mistakes.
*/
void
portable_init(core_portable *p, int *argc, char *argv[])
{
    RVLAB_HEADER ee_printf("Initializing RVLab SoC for CoreMark benchmark!\n");

    p->portable_id = 1;
    
    /* Set up Performance Counters */
	SETUP_MHPMCOUNTER(LD_STALL);
	SETUP_MHPMCOUNTER(JMP_STALL);
	SETUP_MHPMCOUNTER(IMISS);
	SETUP_MHPMCOUNTER(LD);
	SETUP_MHPMCOUNTER(ST);
	SETUP_MHPMCOUNTER(JUMP);
	SETUP_MHPMCOUNTER(BRANCH);
	SETUP_MHPMCOUNTER(BRANCH_TAKEN);
	SETUP_MHPMCOUNTER(COMP_INSTR);
	SETUP_MHPMCOUNTER(PIPE_STALL);

	// Enable counters
	write_csr("mcountinhibit", 0);

    RVLAB_HEADER ee_printf("Starting CoreMark benchmark!\n");
}

/* Function : portable_fini
        Target specific final code
*/
void
portable_fini(core_portable *p)
{
	// Inhibit performance counters
	write_csr("mcountinhibit", ~5); // keep mcycle + minstret active
	
    p->portable_id = 0;


    /* Determine CPI */

    // Fetch 64-bit mcycle + minstret counters
    disable_performance_counters();
    
    uint64_t cycle_l, cycle_h, instret_l, instret_h;
    cycle_l = read_csr("mcycle");
    instret_l = read_csr("minstret"); // might be off by a few but doesn't impact result
    cycle_h = read_csr("mcycleh");
    instret_h = read_csr("minstreth");

    enable_performance_counters();

    uint64_t mcycle = (cycle_h << 32) | cycle_l;
    uint64_t minstret = (instret_h << 32) | instret_l;


    // Compute CPI
    uint32_t cpi_x100 = (100 * mcycle) / minstret;
    uint32_t cpi_natural, cpi_fractional;
    cpi_natural = cpi_x100 / 100;
    cpi_fractional = cpi_x100 % 100;


    // Output
    ee_printf("\033[0m\n");
    RVLAB_HEADER ee_printf("Average CPI during CoreMark execution: %d.%d [0x%08x_%08x/0x%08x_%08x]\n",
    		  cpi_natural, cpi_fractional, (uint32_t)cycle_h, (uint32_t)cycle_l, (uint32_t)instret_h, (uint32_t)instret_l);
    

    /* MHPM Counter Output */
    
    RVLAB_HEADER ee_printf("----- MHPM Counter Dump -----\n");
	RVLAB_HEADER DUMP_MHPMCOUNTER(LD_STALL);
	RVLAB_HEADER DUMP_MHPMCOUNTER(JMP_STALL);
	RVLAB_HEADER DUMP_MHPMCOUNTER(IMISS);
	RVLAB_HEADER DUMP_MHPMCOUNTER(LD);
	RVLAB_HEADER DUMP_MHPMCOUNTER(ST);
	RVLAB_HEADER DUMP_MHPMCOUNTER(JUMP);
	RVLAB_HEADER DUMP_MHPMCOUNTER(BRANCH);
	RVLAB_HEADER DUMP_MHPMCOUNTER(BRANCH_TAKEN);
	RVLAB_HEADER DUMP_MHPMCOUNTER(COMP_INSTR);
	RVLAB_HEADER DUMP_MHPMCOUNTER(PIPE_STALL);


    /* Clock speed output */

    int mhz_integer = get_sysclk_mhz();
    int mhz_fractional = get_sysclk_khz() % 1000;
    RVLAB_HEADER ee_printf("Clock Speed: %d.%03dMHz\n", mhz_integer, mhz_fractional);
}
