
# Create library
vlib work

# Include UVM (usually predefined in Questa, but adding incdir just in case for source compilation if needed)
# Using default UVM in simulator

# Compile RTL
vlog ../sv/cordic_stage.sv
vlog ../sv/cordic.sv
vlog ../sv/fifo.sv
vlog ../sv/cordic_top.sv

# Compile Direct TB
vlog ../sv/cordic_tb.sv

# Compile UVM Package (Optional for direct TB, but kept for UVM run)
vlog +incdir+../uvm ../uvm/cordic_if.sv
vlog +incdir+../uvm ../uvm/cordic_pkg.sv

###################
# USING CORDIC_TB
###################
# Compile UVM Top
#vlog +incdir+../uvm ../uvm/cordic_tb_top.sv
# Run Simulation (Running Direct TB as per user request)
#vsim -c -voptargs="+acc" cordic_tb

###################
# USING UVM
###################
# Compile UVM Top
vlog +incdir+../uvm ../uvm/cordic_tb_top.sv
# Run Simulation (Running Direct TB as per user request)
vsim -c -voptargs="+acc" cordic_tb_top

# Add waves
do cordic_wave.do

# Run all
run -all