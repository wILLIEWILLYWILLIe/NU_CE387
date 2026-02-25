
vlib work
vmap work work

vlog -sv ../sv/my_fft_pkg.sv
vlog -sv ../sv/fifo_ctrl.sv
vlog -sv ../sv/fifo.sv
vlog -sv ../sv/fft_bit_reversal.sv
vlog -sv ../sv/fft_stage.sv
vlog -sv ../sv/complex_mult.sv
vlog -sv ../sv/fft_top.sv
vlog -sv ../sv/fft_tb.sv

vsim -c -do "run -all; quit" fft_tb
