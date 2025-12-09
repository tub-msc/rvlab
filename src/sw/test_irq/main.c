/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdio.h>
#include <rvlab.h>

void irq_handler(void) {
    fputs("I am interrupt\n", stdout);
    // clears the timer interrupt
    REG32(RV_TIMER_INTR_STATE0(0)) = 1;
    REG32(RV_TIMER_INTR_ENABLE0(0)) = 0;
}

static void run_timer_irq(int n_cycles) {
    // set current timer value
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
    REG32(RV_TIMER_TIMER_V_UPPER0(0)) = 0;
    // set timer value to compare current value against
    REG32(RV_TIMER_COMPARE_LOWER0_0(0)) = n_cycles;
    REG32(RV_TIMER_COMPARE_UPPER0_0(0)) = 0;
    // turn the timer on
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
}

int main(void) {
    irq_enable((1<<IRQ_TIMER) | (1<<IRQ_EXTERNAL));

    int i = 1234;
    int counter = 0;
    while(counter < 5) {
        // enables the timer interrupt
        REG32(RV_TIMER_INTR_ENABLE0(0)) = 1;
        run_timer_irq(5);
        counter++;
        printf("I am loop (%i)\n", i++);
    }

    return 0;
}
