onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand /rvlab_ddr3_tb/blockmgr_rsp
add wave -noupdate -expand /rvlab_ddr3_tb/blockmgr_req
add wave -noupdate /rvlab_ddr3_tb/sysclk
add wave -noupdate /rvlab_ddr3_tb/rstn
add wave -noupdate /rvlab_ddr3_tb/rdata
add wave -noupdate /rvlab_ddr3_tb/ddr3if_we
add wave -noupdate /rvlab_ddr3_tb/ddr3if_wdata
add wave -noupdate /rvlab_ddr3_tb/ddr3if_stb
add wave -noupdate /rvlab_ddr3_tb/ddr3if_stall
add wave -noupdate /rvlab_ddr3_tb/ddr3if_rdata
add wave -noupdate /rvlab_ddr3_tb/ddr3if_blk_addr
add wave -noupdate /rvlab_ddr3_tb/ddr3if_ack
add wave -noupdate /rvlab_ddr3_tb/ddr3_we_n
add wave -noupdate /rvlab_ddr3_tb/ddr3_reset_n
add wave -noupdate /rvlab_ddr3_tb/ddr3_ras_n
add wave -noupdate /rvlab_ddr3_tb/ddr3_odt
add wave -noupdate /rvlab_ddr3_tb/ddr3_dqs_p
add wave -noupdate /rvlab_ddr3_tb/ddr3_dqs_n
add wave -noupdate /rvlab_ddr3_tb/ddr3_dq
add wave -noupdate /rvlab_ddr3_tb/ddr3_dm
add wave -noupdate /rvlab_ddr3_tb/ddr3_cs_n
add wave -noupdate /rvlab_ddr3_tb/ddr3_cke
add wave -noupdate /rvlab_ddr3_tb/ddr3_ck_p
add wave -noupdate /rvlab_ddr3_tb/ddr3_ck_n
add wave -noupdate /rvlab_ddr3_tb/ddr3_cas_n
add wave -noupdate /rvlab_ddr3_tb/ddr3_ba
add wave -noupdate /rvlab_ddr3_tb/ddr3_addr
add wave -noupdate /rvlab_ddr3_tb/clk400_90
add wave -noupdate /rvlab_ddr3_tb/clk400
add wave -noupdate /rvlab_ddr3_tb/clk200
add wave -noupdate /rvlab_ddr3_tb/clk100
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/state_q
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/state_d
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/reqbuf_wptr_q
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/reqbuf_wptr
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/reqbuf_type_mem
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/reqbuf_state_mem
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/reqbuf_rptr
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/reqbuf_full
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/reqbuf_data_mem
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/blkdata_q
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/blkaddr_q
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/wb_aux_o
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/wb_aux_i
add wave -noupdate /rvlab_ddr3_tb/blkmgr_i/ack_reqbuf_adr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {74141117292 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 241
configure wave -valuecolwidth 100
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
WaveRestoreZoom {219089501246 fs} {222804499935 fs}
