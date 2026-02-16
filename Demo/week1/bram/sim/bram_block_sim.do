
setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../sv/bram.sv"
vlog -work work "../sv/bram_block.sv"
vlog -work work "../sv/bram_block_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.bram_block_tb -wlf bram_block.wlf

add wave -noupdate -group bram_block_tb
add wave -noupdate -group bram_block_tb -radix hexadecimal /bram_block_tb/*
add wave -noupdate -group bram_block_tb/bb
add wave -noupdate -group bram_block_tb/bb -radix hexadecimal /bram_block_tb/bb/*

run -all

