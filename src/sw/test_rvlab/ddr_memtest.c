/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <rvlab.h>

static void lfsr_init(uint32_t *v) {
    *v = 1;
}

static void lfsr_next(uint32_t *v) {
    unsigned b = (*v) & 1;
    *v = ((*v) >> 1) ^ (-b & 0xc3308398);
}

int memtest(void *start, size_t length) {
    uint32_t lfsr;
    int retval = 0;

    uint32_t cycle_start, cycle_duration, cycles_per_byte_x100;

    lfsr_init(&lfsr);
    uint32_t addr;
    cycle_start = read_csr("mcycle");
    for(addr=(uint32_t) start;addr<(uint32_t) start+length;) {
        for (uint32_t i = 0; i < 0x40000; i++) {
            REG32(addr) = lfsr;
            lfsr_next(&lfsr);
            addr += 4;
        }
        printf("\rWriting address 0x%08x...", addr);
    }
    printf("\nWrite completed.\n");

    cycle_duration = read_csr("mcycle") - cycle_start;
    cycles_per_byte_x100 = cycle_duration / (length / 100);
    printf("Write: %d KB in %u cycles (%u.%u cycles/byte)\n",
        length/1024, cycle_duration,
        cycles_per_byte_x100/100, cycles_per_byte_x100 % 100
    );


    lfsr_init(&lfsr);
    cycle_start = read_csr("mcycle");
    for(addr=(uint32_t) start;addr<(uint32_t) start+length;) {
        for (uint32_t i = 0; i < 0x40000; i++) {
            if(REG32(addr) != lfsr) {
                printf("\rERROR: Incorrect read data at 0x%08x.\n", addr);
                retval = 1;
            }
            lfsr_next(&lfsr);
            addr += 4;
        }
        printf("\rReading address 0x%08x...", addr);
    }

    cycle_duration = read_csr("mcycle") - cycle_start;
    cycles_per_byte_x100 = cycle_duration / (length / 100);
    printf("\nRead: %d KB in %u cycles (%u.%u cycles/byte)\n",
        length/1024, cycle_duration,
        cycles_per_byte_x100/100, cycles_per_byte_x100 % 100
    );

    if(retval) {
        printf("\nMemtest completed with errors.\n\n");
    } else {
        printf("\nMemtest completed without errors.\n\n");
    }

    return retval;
}


int ddr_memtest(void) {
    return memtest((void*)DDR3_BASE_ADDR, DDR3_SIZE);
}
