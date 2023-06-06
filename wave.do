onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 30 -expand -group {TB signals} /SDRAM_Controller_TB/i_rst
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/state
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/next_state
add wave -noupdate -height 30 -expand -group {Controller signals} -radix decimal /SDRAM_Controller_TB/m0/next_state_after_wait
add wave -noupdate -height 30 -expand -group {Controller signals} -radix decimal /SDRAM_Controller_TB/m0/counter_wait
add wave -noupdate -height 30 -expand -group {Controller signals} -radix unsigned /SDRAM_Controller_TB/m0/counter_rst
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/refresh_en
add wave -noupdate -height 30 -expand -group {Controller signals} /SDRAM_Controller_TB/m0/refresh_flag
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CKE
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CLK
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CS_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/RAS_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/CAS_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/WE_N
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/m0/DQML
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/m0/DQMH
add wave -noupdate -height 30 -expand -group {Controller outputs} -radix binary /SDRAM_Controller_TB/A
add wave -noupdate -height 30 -expand -group {Controller outputs} /SDRAM_Controller_TB/m0/BA
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {135918308 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 338
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
WaveRestoreZoom {59317658 ps} {417930650 ps}
