/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdint.h>
#include <stdio.h>
#include <rvlab.h>

int ddr_init(void) {
    if(!(REG32(DDR_CTRL_STATUS(0)) & (1<<DDR_CTRL_STATUS_PRESENT_LSB))) {
        printf("Error: DDR not present.\n");
        return 1;
    }
    REG32(DDR_CTRL_CTRL(0)) |= (1<<DDR_CTRL_CTRL_RST_N_LSB); // deassert reset

    // wait for calibration to complete:
    while(!(REG32(DDR_CTRL_STATUS(0)) & (1<<DDR_CTRL_STATUS_CALIB_COMPLETE_LSB))); 

    printf("DDR3 calibration completed.\n");
    return 0;
}
