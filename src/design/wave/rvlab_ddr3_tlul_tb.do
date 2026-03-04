onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clocks and Resets}
add wave -noupdate /rvlab_ddr3_tlul_tb/clk100
add wave -noupdate /rvlab_ddr3_tlul_tb/sysclk
add wave -noupdate /rvlab_ddr3_tlul_tb/rstn
add wave -noupdate -divider TL-UL
add wave -noupdate -expand /rvlab_ddr3_tlul_tb/tl_host_h2d
add wave -noupdate -expand /rvlab_ddr3_tlul_tb/tl_host_d2h
add wave -noupdate /rvlab_ddr3_tlul_tb/rdata
add wave -noupdate /rvlab_ddr3_tlul_tb/tl_ctrl_h2d
add wave -noupdate /rvlab_ddr3_tlul_tb/tl_ctrl_d2h
add wave -noupdate -divider {DDR3 signals}
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_we_n
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_reset_n
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_ras_n
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_odt
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_dqs_p
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_dqs_n
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_dq
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_dm
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_cke
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_ck_p
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_ck_n
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_cas_n
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_ba
add wave -noupdate /rvlab_ddr3_tlul_tb/ddr3_addr
add wave -noupdate -divider CDC
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/cdc_fifo_i/wtl_h_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/cdc_fifo_i/wtl_h_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/cdc_fifo_i/wtl_d_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/cdc_fifo_i/wtl_d_i
add wave -noupdate -divider {Block Cache}
add wave -noupdate -expand /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/block_rsp_i
add wave -noupdate -expand /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/block_req_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/blk_cache_rsp
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/blk_cache_req
add wave -noupdate -divider {Cache Internals}
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/tag_rdata
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/tag_mem
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/TAG_BITS
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/stall_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/stall_d
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/stall
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/SETS
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/rst_ni
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/miss
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/IDX_BITS
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/hit
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/fe_rsp_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/fe_req_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/data_rdata
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/data_mem
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/clk_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/modify_clear
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/modified_mem
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/be_rsp_i
add wave -noupdate -expand /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/be_req_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/ancillary_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_type_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_tag_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_tag
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_mask_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_idx_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_idx
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_data_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access_addr
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_llc_i/cache_i/access
add wave -noupdate -divider {Block Manager}
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wmask_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_wmask_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_we_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_wdata_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_stb_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_stall_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_rdata_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_blk_addr_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_aux_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_aux_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/wb_ack_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/state_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/state_d
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/rst_ni
add wave -noupdate -expand /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/req_i
add wave -noupdate -expand /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/rsp_o
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_wptr_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_wptr
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_type_mem
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_state_mem
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/REQBUF_SIZE
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_rptr
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_full
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_data_mem
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/REQBUF_AW
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/reqbuf_anc_mem
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/clk_i
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/blkdata_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/blkaddr_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/AUX_BITS
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/ancillary_data_q
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/blkmgr_i/ack_reqbuf_adr
add wave -noupdate -divider UberDDR3
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_wb_stall
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_wb_err
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_wb_data
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_wb_ack
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_wb2_stall
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_wb2_data
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_wb2_ack
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_debug1
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_we_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_reset_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_ras_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_odt
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_dm
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_cs_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_clk_p
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_clk_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_cke
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_cas_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_ba_addr
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_ddr3_addr
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_calib_complete
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/o_aux
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/io_ddr3_dqs_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/io_ddr3_dqs
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/io_ddr3_dq
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb_we
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb_stb
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb_sel
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb_data
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb_cyc
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb_addr
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb2_we
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb2_stb
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb2_sel
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb2_data
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb2_cyc
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_wb2_addr
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_user_self_refresh
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_rst_n
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_ref_clk
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_ddr3_clk_90
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_ddr3_clk
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_controller_clk
add wave -noupdate /rvlab_ddr3_tlul_tb/DUT/ddr_i/i_aux
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {212437928908 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 301
configure wave -valuecolwidth 181
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {212381735820 fs} {213264119168 fs}
