
# Create library
vlib work

# Compile RTL and Testbench from ../sv
vlog ../sv/cordic.sv ../sv/cordic_tb.sv

# Run Simulation
vsim -c -voptargs="+acc" cordic_tb

# Run all
run -all

# Quit
quit
