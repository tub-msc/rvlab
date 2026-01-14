/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#ifndef _RVLAB_H
#define _RVLAB_H

#define IRQ_TIMER 7
#define IRQ_EXTERNAL 11

#define DDR3_BASE_ADDR ((void *) 0x80000000)
#define DDR3_SIZE      ((size_t) 0x20000000)

int ddr_init(void);

#include <regaccess.h>

#include <reggen/ddr_ctrl.h>
#define DDR_CTRL0_BASE_ADDR 0x1f001000

#include <reggen/regdemo.h>
#define REGDEMO0_BASE_ADDR 0x1f002000

#include <reggen/rv_timer.h>
#define RV_TIMER0_BASE_ADDR 0x1f000000

#include <reggen/student_dma.h>
#define STUDENT_DMA0_BASE_ADDR 0x20000000

// Variable clocking
#define RV_CLK_BASE_ADDR 0x1d000000

// Add includes for additional register definition headers
// and define corresponding _BASE_ADDR values here.

#endif // _RVLAB_H
