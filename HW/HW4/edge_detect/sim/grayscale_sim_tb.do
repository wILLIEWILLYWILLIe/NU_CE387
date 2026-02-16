
# Set up environment
vlib work
vmap work work

# Compile RTL
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/grayscale.sv"
vlog -work work "../sv/grayscale_top.sv"

# Compile Testbench
vlog -work work "../sv/grayscale_tb.sv"

# Simulate
vsim -voptargs=+acc work.grayscale_tb

# Waveform setup (Optional)
add wave -noupdate -group TB /grayscale_tb/*
add wave -noupdate -group DUT /grayscale_tb/dut/*
add wave -noupdate -group GS /grayscale_tb/dut/gs_inst/*

# Run
run -all
