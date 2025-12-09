/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdio.h>
#include <rvlab.h>

#define REGA   0x10000000
#define REGB   0x10000004


static void delay_cycles(int n_cycles) {
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
    while(REG32(RV_TIMER_TIMER_V_LOWER0(0)) < n_cycles);
}

int main(void) {

    // Implement tests here.

    // Example:

    printf("REGA 0x%08x\n", REG32(REGA));
    REG32(REGA) = 0x12345678;
    printf("REGA 0x%08x\n", REG32(REGA));
    delay_cycles(2);

    REG32(REGB) = 0xFFFFFF01;
    printf("REGB 0x%08x\n", REG32(REGB));
    delay_cycles(10);
    
    return 0;
}
