/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024 RVLab Contributors
 */

#include <stdio.h>
#include <stdbool.h>
#include <rvlab.h>

#include "ddr_memtest.h"
#include "regdemo.h"
#include "rv_timer.h"
#include "test_csrs.h"

typedef struct {
    int n_tests;
    int n_pass;
} test_summary_t;

void test_report(test_summary_t *s, char *name, int status) {
    char *status_str;
    
    s->n_tests++;
    
    if(status) {
        status_str = "FAIL";
    } else {
        status_str = "PASS";
        s->n_pass++;
    }

    printf("[%s] test %i: %s\n\n", status_str, s->n_tests, name);
}

int test_summary(test_summary_t *s) {
    printf("SUMMARY: %i / %i tests passed.\n", s->n_pass, s->n_tests);
    if(s->n_tests == s->n_pass) {
        printf("All tests passed successfully.\n");
        return 0;
    } else {
        printf("ERROR: Some tests failed.\n");
        return 1;
    }
}

int main(void) {
    test_summary_t s;
    s.n_tests = 0;
    s.n_pass = 0;

    bool ddr_available = !ddr_init();

    test_report(&s, "regdemo_test", regdemo_test());
    test_report(&s, "rv_timer_test", rv_timer_test());
    test_report(&s, "test_csrs", test_csrs());
    if(ddr_available)
        test_report(&s, "ddr_memtest", ddr_memtest());

    return test_summary(&s);
}
