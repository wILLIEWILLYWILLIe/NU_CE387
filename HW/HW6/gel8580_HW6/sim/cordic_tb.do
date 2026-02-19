
# Create library
vlib work

# Compile RTL and Testbench from ../sv
vlog ../sv/cordic_stage.sv ../sv/cordic.sv ../sv/fifo.sv ../sv/cordic_top.sv ../sv/cordic_tb_pipe.sv

# Run Simulation
vsim -c -voptargs="+acc" cordic_tb_pipe -do "run -all; quit"
