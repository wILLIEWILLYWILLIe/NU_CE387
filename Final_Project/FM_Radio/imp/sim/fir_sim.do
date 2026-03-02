
vlib work
vmap work work

# Compile package first
vlog -sv ../sv/fir_pkg.sv

# Compile DUT and testbench
vlog -sv ../sv/fir.sv
vlog -sv ../sv/fir_tb.sv

# Elaborate and run
vsim -voptargs="+acc" fir_tb

# Log all signals
log -r /*

# Run simulation
run -all

quit -f
