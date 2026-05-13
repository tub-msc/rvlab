/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdint.h>
#include <stdio.h>
#include <rvlab.h>

int ddr_init(void) {
    printf("Initializing DDR3. If a STORE_FAULT is triggered, the DDR is not present.\n");
    *((uint32_t *)DDR3_BASE_ADDR) = 0u;
    return 0;
}
