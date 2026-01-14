/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2026 RVLab Contributors
 */

#ifndef RVLAB_CLOCKING_H
#define RVLAB_CLOCKING_H


/* Performance-related macros */

#define MCOUNTINHIBIT_MCYCLE   (1 << 0)
#define MCOUNTINHIBIT_MINSTRET (1 << 2)
#define disable_performance_counters() set_csr_bits("mcountinhibit", MCOUNTINHIBIT_MCYCLE | MCOUNTINHIBIT_MINSTRET)
#define enable_performance_counters() clear_csr_bits("mcountinhibit", MCOUNTINHIBIT_MCYCLE | MCOUNTINHIBIT_MINSTRET)


/* Getter functions */

// You may rename the clocks here and in the corresponding
// definitions (sw/sys/clocking.c)

uint32_t rvlab_get_sysclock();

inline uint32_t rv_clk_get_clk1_div();

inline uint32_t rv_clk_get_clk2_div();

inline uint32_t rv_clk_get_clk3_div();

inline uint32_t rv_clk_get_clk4_div();

inline uint32_t rv_clk_get_clk5_div();

inline uint32_t rv_clk_get_clk6_div();

/* Setter functions */

void rvlab_set_sysclock(uint32_t div);

inline void rv_clk_set_clk1_div(uint32_t div);

inline void rv_clk_set_clk2_div(uint32_t div);

inline void rv_clk_set_clk3_div(uint32_t div);

inline void rv_clk_set_clk4_div(uint32_t div);

inline void rv_clk_set_clk5_div(uint32_t div);

inline void rv_clk_set_clk6_div(uint32_t div);

#endif // RVLAB_CLOCKING_H
