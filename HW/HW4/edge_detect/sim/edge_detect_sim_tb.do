
# Set up environment
vlib work
vmap work work

# Compile RTL
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/grayscale.sv"
vlog -work work "../sv/sobel.sv"
vlog -work work "../sv/edge_detect_top.sv"

# Compile Testbench
vlog -work work "../sv/edge_detect_tb.sv"

# Simulate
vsim -voptargs=+acc work.edge_detect_tb

# Waveform setup (Optional)
add wave -noupdate -group TB /edge_detect_tb/*
add wave -noupdate -group TOP /edge_detect_tb/dut/*
add wave -noupdate -group SOBEL /edge_detect_tb/dut/sob_inst/*

# Run
run -all
