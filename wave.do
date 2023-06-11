onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 30 -expand -group {TB signals} /SDRAM_Controller_TB/i_rst
add wave -noupdate /SDRAM_Controller_TB/i_initial
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/state
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/next_state
add wave -noupdate -height 30 -expand -group {Controller signals} -radix unsigned /SDRAM_Controller_TB/m0/next_state_after_wait
add wave -noupdate -height 30 -expand -group {Controller signals} -radix decimal /SDRAM_Controller_TB/m0/counter_wait
add wave -noupdate -height 30 -expand -group {Controller signals} -radix unsigned /SDRAM_Controller_TB/m0/counter_rst
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/refresh_en
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/refresh_flag
add wave -noupdate /SDRAM_Controller_TB/o_busy
add wave -noupdate /SDRAM_Controller_TB/o_data
add wave -noupdate /SDRAM_Controller_TB/DQ
add wave -noupdate /SDRAM_Controller_TB/i_rw
add wave -noupdate -radix unsigned /SDRAM_Controller_TB/m0/counter_rd
add wave -noupdate /SDRAM_Controller_TB/m0/burst
add wave -noupdate /SDRAM_Controller_TB/m0/latency
add wave -noupdate /SDRAM_Controller_TB/m0/rd_duration
add wave -noupdate -radix binary /SDRAM_Controller_TB/m0/A
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CKE
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CLK
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CS_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/RAS_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CAS_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/WE_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/m0/DQML
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/m0/DQMH
add wave -noupdate -height 30 -expand -group {Controller outputs} -radix binary -childformat {{{/SDRAM_Controller_TB/A[12]} -radix binary} {{/SDRAM_Controller_TB/A[11]} -radix binary} {{/SDRAM_Controller_TB/A[10]} -radix binary} {{/SDRAM_Controller_TB/A[9]} -radix binary} {{/SDRAM_Controller_TB/A[8]} -radix binary} {{/SDRAM_Controller_TB/A[7]} -radix binary} {{/SDRAM_Controller_TB/A[6]} -radix binary} {{/SDRAM_Controller_TB/A[5]} -radix binary} {{/SDRAM_Controller_TB/A[4]} -radix binary} {{/SDRAM_Controller_TB/A[3]} -radix binary} {{/SDRAM_Controller_TB/A[2]} -radix binary} {{/SDRAM_Controller_TB/A[1]} -radix binary} {{/SDRAM_Controller_TB/A[0]} -radix binary}} -subitemconfig {{/SDRAM_Controller_TB/A[12]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[11]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[10]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[9]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[8]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[7]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[6]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[5]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[4]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[3]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[2]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[1]} {-height 15 -radix binary} {/SDRAM_Controller_TB/A[0]} {-height 15 -radix binary}} /SDRAM_Controller_TB/A
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/m0/o_data
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/m0/BA
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {101773688 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 281
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
configure wave -timelineunits ps
update
WaveRestoreZoom {101714446 ps} {101835554 ps}
