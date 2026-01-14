/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2024-2026 RVLab Contributors
 */

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <rvlab.h>
#include <clocking.h>

#define LINE_SIZE 256
char *readline(void) {
    static char line[LINE_SIZE];
    int line_idx = 0;

    printf("> ");

    while(1) {
        int c=fgetc(stdin);
        
        if(c=='\n' || c=='\r') {
            fputc('\n', stdout);
            break;
        } else if (c==127) { // backspace
            if(line_idx > 0) {
                printf("\10\33[K");
                line_idx--;
            }
        } else if (c=='\x1b') {
            // Idea here is to ignore ANSI escape sequences coming from the user keyboard:
            while(1) {
                c = fgetc(stdin);
                if(c>='A' && c<='D') { // arrow up, down, left, right
                    break;
                }
            }
        } else {
            if(line_idx < LINE_SIZE - 1) {
                fputc(c, stdout);
                //printf("char %d\n", c);
                line[line_idx++] = c;
            }
        }
    }
    line[line_idx] = '\0';
    return line;

}

/* Commands */
void cmd_help(char *args[]);
void cmd_lw(char *args[]);
void cmd_sw(char *args[]);
void cmd_dump(char *args[]);
void cmd_sysclk_get(char *args[]);
void cmd_sysclk_set(char *args[]);
void cmd_get_cpi(char *args[]);
void cmd_quit(char *args[]);

struct cmd {
    char *name;
    char *help;
    int nargs;
    void (*handler) (char *args[]);
} cmds[] = {
    {"help", ": Print help.", 0, cmd_help},
    {"lw", " ADDR: Load word.", 1, cmd_lw},
    {"sw", " ADDR DATA: Store word.", 2, cmd_sw},
    {"dump", " ADDR WORDS: Dump memory.", 2, cmd_dump},
    {"sysclk_get", ": Get sys_clk clock divisor.", 0, cmd_sysclk_get},
    {"sysclk_set", " DIV: Set sys_clk clock divisor.", 1, cmd_sysclk_set},
    {"get_cpi", ": Retrieve performance counters.", 0, cmd_get_cpi},
    {"quit", ": Exit the program", 0, cmd_quit},
    {NULL, NULL, 0, NULL}
};

void cmd_help(char *args[]) {
    printf("Help:\n");
    struct cmd *c;
        
    for(c = cmds;c->name;c++) {
        printf("\t%s%s\n", c->name, c->help);
    }   
}

void cmd_lw(char *args[]) {
    char *endptr;

    unsigned addr, data;

    addr = strtoul(args[1], &endptr, 0);
    if(*args[1]=='\0' || *endptr!='\0') {
        printf("Error: Failed to parse ADDR.\n");
        return;
    }

    data = *((unsigned *) addr);

    printf("read 0x%08x: 0x%08x\n", addr, data);
}

void cmd_dump(char *args[]) {
    char *endptr;

    unsigned addr, size, data;

    addr = strtoul(args[1], &endptr, 0);
    if(*args[1]=='\0' || *endptr!='\0') {
        printf("Error: Failed to parse ADDR.\n");
        return;
    }

    size = strtoul(args[2], &endptr, 0);
    if(*args[2]=='\0' || *endptr!='\0') {
        printf("Error: Failed to parse DATA.\n");
        return;
    }

    int i;
    for(i=0;i<size;i++) {
        data = *((unsigned char *) addr);
        if((i&0xf) == 0) {
            printf("\n%08x:", addr);
        }
        printf(" %02x", data);
        addr+=1;
    }
    printf("\n");
}


void cmd_sw(char *args[]) {
    char *endptr;

    unsigned addr, data;

    addr = strtoul(args[1], &endptr, 0);
    if(*args[1]=='\0' || *endptr!='\0') {
        printf("Error: Failed to parse ADDR.\n");
        return;
    }

    data = strtoul(args[2], &endptr, 0);
    if(*args[2]=='\0' || *endptr!='\0') {
        printf("Error: Failed to parse DATA.\n");
        return;
    }

    *((unsigned *) addr) = data;

    printf("wrote 0x%08x: 0x%08x\n", addr, data);
}



void cmd_sysclk_get(char *args[]) {
    uint32_t sysclk_val = rvlab_get_sysclock();
    printf("sys_clk divider value: %u\n", sysclk_val);
}


void cmd_sysclk_set(char *args[]) {
    char *endptr;

    unsigned div = strtoul(args[1], &endptr, 0);
    if (*args[1]=='\0' || *endptr!='\0') {
        printf("Error: Failed to parse DIV.\n");
        return;
    }

    rvlab_set_sysclock(div);
    printf("updated system clock divisor to %u.\n", div);
}


void cmd_get_cpi(char *args[]) {
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
    printf("cpi      : %d.%02d \n", cpi_natural, cpi_fractional);
    printf("mcycle   : 0x%08x_%08x\n", (uint32_t)cycle_h, (uint32_t)cycle_l);
    printf("minstret : 0x%08x_%08x\n", (uint32_t)instret_h, (uint32_t)instret_l);
}


void cmd_quit(char *args[]) {
    _exit(0);
}



int main(void) {
    ddr_init();

    printf("Welcome to rvlab monitor.\n");

    while(1) {
        char *cmd = readline();
        char *args[5];
        struct cmd *c;
        args[0] = strtok(cmd," ");

        for(c = cmds;c->name;c++) {
            if(strcmp(args[0], c->name)==0)
                break;
        }
        if(!c->handler) {
            printf("Unknown command. Use 'help' for help.\n");
            c = NULL;
        }
        if(c) {
            for(int i=0;i<c->nargs;i++) {
                if((args[i+1] = strtok(NULL, " "))==NULL) {
                    printf("Too few arguments provided to %s.\n", c->name);
                    c = NULL;
                    break;
                }
            }
        }
        if(c) {
            if(strtok(NULL, " ")!=NULL) {
                printf("Too many arguments provided to %s.\n", c->name);
                c = NULL;
            }
        }
        if(c) {
            c->handler(args);
        }
    }
    return 0;
}
