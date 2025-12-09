/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdio.h>
#include <rvlab.h>
#include "memset.h"
#include "memcpy.h"

// Test memset
// -----------

static int test_memset_singlecase(uint32_t length_words, uint32_t pattern, void (*func_memset)(void *, uint32_t, uint32_t), int print_cycles) {
    int errcnt = 0;
    unsigned int buf[64];
    int mcycle_start, mcycle_end;
    
    for (int i = 0; i < 64; i++) {
            buf[i] = 0;
    }
    buf[0] = 0xcafe;
    buf[63] = 0xbeef;
    
    mcycle_start = read_csr("mcycle");
    (*func_memset)(buf+1, pattern, length_words*sizeof(int));
    mcycle_end = read_csr("mcycle");

    if(print_cycles) {
        printf("cycles count for %i words: %i\n", length_words, mcycle_end - mcycle_start);
    }

    for (int i = 0; i < 64; i++) {
        int val_expected;
        if(i==0) {
            val_expected = 0xcafe;
        } else if (i<(1+length_words)) {
            val_expected = pattern;
        } else if (i<63) {
            val_expected = 0;
        } else { // i == 63
            val_expected = 0xbeef;
        }
        int val_read = buf[i];
        //printf("%x ", buf[i]);
        if(val_read != val_expected) {
            printf("Error: buf[%i] was %i != %i\n", i, val_read, val_expected);
            errcnt++;
        }
    }
    return errcnt;
}

int test_memset(void (*func_memset)(void *, uint32_t, uint32_t)) {
    int errcnt = 0;

    errcnt += test_memset_singlecase(4, 0x55, func_memset, 0);
    errcnt += test_memset_singlecase(50, 0x12345678, func_memset, 1);
    errcnt += test_memset_singlecase(1, 0xffffffff, func_memset, 0);

    return errcnt;
}

// Test memcpy
// -----------

static int test_memcpy_singlecase(uint32_t length_words, void *src_buf, void (*func_memcpy)(void *, void *, uint32_t), int print_cycles) {
    int errcnt = 0;
    unsigned int buf[64];
    int mcycle_start, mcycle_end;


    for (int i = 0; i < 64; i++) {
            buf[i] = 0;
    }
    buf[0] = 0xcafe;
    buf[63] = 0xbeef;
    
    mcycle_start = read_csr("mcycle");
    (*func_memcpy)(buf+1, src_buf, length_words*sizeof(int));
    mcycle_end = read_csr("mcycle");
    
    if(print_cycles) {
        printf("cycles count for %i words: %i\n", length_words, mcycle_end - mcycle_start);
    }

    for (int i = 0; i < 64; i++) {
        int val_expected;
        if(i==0) {
            val_expected = 0xcafe;
        } else if (i<(1+length_words)) {
            val_expected = ((uint32_t *)src_buf)[i-1];
        } else if (i<63) {
            val_expected = 0;
        } else { // i == 63
            val_expected = 0xbeef;
        }
        int val_read = buf[i];
        //printf("%x ", buf[i]);
        if(val_read != val_expected) {
            printf("Error: buf[%i] was %i != %i\n", i, val_read, val_expected);
            errcnt++;
        }
    }
    return errcnt;
}

int test_memcpy(void (*func_memcpy)(void *, void *, uint32_t)) {
    int errcnt = 0;

    uint32_t src_buf[64];
    for(int i=0;i<64;i++) {
        src_buf[i] = 0x11223300 + i;
    }

    errcnt += test_memcpy_singlecase(4, src_buf, func_memcpy, 0);
    errcnt += test_memcpy_singlecase(50, src_buf, func_memcpy, 1);
    errcnt += test_memcpy_singlecase(1, src_buf + 30, func_memcpy, 0);

    return errcnt;
}

// Main
// ----

int main(void) {
    int res, retval=0;

    printf("test memset_soft:\n");    
    res = test_memset(memset_soft);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");

    printf("test memset_dma:\n");
    res = test_memset(memset_dma);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");

    printf("test memcpy_soft:\n");
    res = test_memcpy(memcpy_soft);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");

    printf("test memcpy_dma:\n");
    res = test_memcpy(memcpy_dma);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");

    return retval;
}
