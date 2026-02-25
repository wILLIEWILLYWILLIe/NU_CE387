
vlib work
vmap work work

# Compile source files
vlog -sv ../sv/my_fft_pkg.sv
vlog -sv ../sv/fifo_ctrl.sv
vlog -sv ../sv/fifo.sv
vlog -sv ../sv/fft_bit_reversal.sv
vlog -sv ../sv/fft_stage.sv
vlog -sv ../sv/complex_mult.sv
vlog -sv ../sv/fft_top.sv

# Compile UVM environment
vlog -sv +incdir+../uvm ../uvm/my_uvm_pkg.sv
vlog -sv +incdir+../uvm ../uvm/fft_if.sv
vlog -sv +incdir+../uvm ../uvm/my_uvm_tb.sv

# Elaborate and load simulation
vsim -voptargs="+acc" -coverage my_uvm_tb +UVM_TESTNAME=my_uvm_test

# Log all signals for waveform viewing
log -r /*

# Load waves
view wave
delete wave *
do fft_wave.do

# Run simulation
run -all

# Zoom full to see the whole simulation
wave zoom full
