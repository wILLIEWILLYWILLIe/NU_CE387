
set UVM_DPI_HOME /vol/eecs392/uvm-1.2/lib/uvm_dpi

vlib work
vmap work work

# Compile RTL
vlog -sv ../sv/fifo.sv
vlog -sv ../sv/fifo_ctrl.sv
vlog -sv ../sv/udp_parser.sv
vlog -sv ../sv/udp_parser_top.sv

# Compile UVM
vlog -sv +incdir+../uvm ../uvm/my_uvm_pkg.sv
vlog -sv +incdir+../uvm ../uvm/my_uvm_tb.sv

# Load Simulation (Use standard UVM DPI lib provided by Questa/UVM installation if needed for basic UVM features)
# Note: Since we are not using custom DPI, we might only need the standard UVM lib.
vsim -c -voptargs=+acc my_uvm_tb

# Waveform setup
do udp_parser_wave.do

run -all
