
setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/grayscale.sv"
vlog -work work "../sv/background_sub.sv"
vlog -work work "../sv/highlight.sv"
vlog -work work "../sv/motion_detect_top.sv"
vlog -work work "../sv/motion_detect_tb.sv"

vsim -voptargs=+acc work.motion_detect_tb

add wave -noupdate -group {Top Level} /motion_detect_tb/*
add wave -noupdate -group {DUT} /motion_detect_tb/dut/*
add wave -noupdate -group {Grayscale Base} /motion_detect_tb/dut/gs_base_inst/*
add wave -noupdate -group {Grayscale Img} /motion_detect_tb/dut/gs_img_inst/*
add wave -noupdate -group {Background Sub} /motion_detect_tb/dut/bg_sub_inst/*
add wave -noupdate -group {Highlight} /motion_detect_tb/dut/highlight_inst/*
add wave -noupdate -group {FIFO Mask} /motion_detect_tb/dut/fifo_mask/*

run -all
