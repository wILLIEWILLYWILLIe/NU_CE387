
# Create library
vlib work
vmap work work

# Compile RTL
vlog -sv ../sv/fifo.sv
vlog -sv ../sv/fifo_ctrl.sv
vlog -sv ../sv/udp_parser.sv
vlog -sv ../sv/udp_parser_top.sv

# Compile Testbench
vlog -sv ../sv/udp_parser_tb.sv

# Load Simulation
vsim -voptargs=+acc udp_parser_tb

# Waveform Setup
add wave -noupdate -divider {System}
add wave -noupdate -format Logic /udp_parser_tb/clock
add wave -noupdate -format Logic /udp_parser_tb/reset

add wave -noupdate -divider {Input Interface}
add wave -noupdate -format Logic /udp_parser_tb/din_wr_en
add wave -noupdate -format Literal -radix hex /udp_parser_tb/din
add wave -noupdate -format Logic /udp_parser_tb/din_sof
add wave -noupdate -format Logic /udp_parser_tb/din_eof
add wave -noupdate -format Logic /udp_parser_tb/din_full

add wave -noupdate -divider {Internal Parser State}
add wave -noupdate -format Literal /udp_parser_tb/dut/parser_inst/state
add wave -noupdate -format Literal -radix unsigned /udp_parser_tb/dut/parser_inst/byte_cnt
add wave -noupdate -format Literal -radix unsigned /udp_parser_tb/dut/parser_inst/udp_len
add wave -noupdate -format Logic /udp_parser_tb/dut/parser_inst/in_rd_en
add wave -noupdate -format Logic /udp_parser_tb/dut/parser_inst/out_wr_en

add wave -noupdate -divider {Output Interface}
add wave -noupdate -format Logic /udp_parser_tb/dout_rd_en
add wave -noupdate -format Literal -radix hex /udp_parser_tb/dout
add wave -noupdate -format Logic /udp_parser_tb/dout_sof
add wave -noupdate -format Logic /udp_parser_tb/dout_eof
add wave -noupdate -format Logic /udp_parser_tb/dout_empty

# Run Simulation
run -all
