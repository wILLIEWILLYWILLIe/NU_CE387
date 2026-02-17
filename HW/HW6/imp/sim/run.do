
# Create library
vlib work

# Include UVM (usually predefined in Questa, but adding incdir just in case for source compilation if needed)
# Using default UVM in simulator

# Compile RTL
vlog ../sv/cordic.sv

# Compile UVM Package
vlog +incdir+../uvm ../uvm/cordic_if.sv
vlog +incdir+../uvm ../uvm/cordic_pkg.sv

# Compile Top
vlog +incdir+../uvm ../uvm/cordic_tb_top.sv

# Run Simulation
vsim -c -voptargs="+acc" cordic_tb_top

# Add waves
do cordic_wave.do

# Run all
run -all

# Quit
quit
