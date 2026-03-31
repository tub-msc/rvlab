/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <rvlab.h>

static volatile uint32_t *M = DDR3_BASE_ADDR;


static volatile uint16_t *Mh = DDR3_BASE_ADDR;
static volatile uint8_t *Mb = DDR3_BASE_ADDR;


static int test_size_reads(void) {

    M[1] = 0x12345678;
    M[2] = 0xFF00FF00;
    M[3] = 0x00000000;
    Mb[0] = 0xAB;
    Mb[1] = 0xCD;
    Mh[1] = 0xEF01;

    bool word_read_correct =
        (M[0] == 0xef01cdab) && (M[1] == 0x12345678) &&
        (M[2] == 0xff00ff00) && (M[3] == 0x00000000);
    bool byte_read_correct =
        (Mh[0] == 0xcdab) && (Mh[1] == 0xef01) &&
        (Mh[2] == 0x5678) && (Mh[3] == 0x1234);
    bool hword_read_correct =
        (Mb[0] == 0xab) && (Mb[1] == 0xcd) &&
        (Mb[2] == 0x01) && (Mb[3] == 0xef);

    printf("correct reads: word=%i, hword=%i, byte=%i\n",
        word_read_correct, hword_read_correct, byte_read_correct);    
    return !word_read_correct || !hword_read_correct || !byte_read_correct;
}

static int test_ddr(void) {
    M[0] = 0x01234567;
    M[4] = 0x89ABCDEF;
    M[8] = 0x11111111;

    bool M0_correct = (M[0] == 0x01234567);
    bool M4_correct = (M[4] == 0x89ABCDEF);
    bool M8_correct = (M[8] == 0x11111111);

    printf("correct reads: M0=%i, M4=%i, M8=%i\n",
        M0_correct, M4_correct, M8_correct);
    return !M0_correct || !M4_correct || !M8_correct;
}


static int check_bank_addr(void) {
    int i;
    int errors = 0;
    for(i=0;i<16;i++) {
        M[i<<23] = i;
    }
    for(i=0;i<16;i++) {
        if(M[i<<23] != i)
            errors++;
    }
    printf("check_bank_addr errors=%i\n", errors);
    return errors;
}


static int test_stream(void) {
    int i;
    int errors = 0;

    for(i=0;i<32;i++) {
        M[i] = i;
    }
    for(i=0;i<32;i++) {
        if(M[i]!=i)
            errors++;
    }

    for(i=0;i<32;i++) {
        M[100+i] = i;
    }
    for(i=0;i<32;i++) {
        if(M[100+i]!=i)
            errors++;
    }


    printf("test_stream errors=%i\n", errors);
    return errors;
}


int main(void) {
    if (ddr_init())
        return 1;
    
    if (test_size_reads())
        return 1;

    if (test_ddr())
        return 1;

    if (test_stream())
        return 1;

    return 0;
}
