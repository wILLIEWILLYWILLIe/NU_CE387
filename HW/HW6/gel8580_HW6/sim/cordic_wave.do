
add wave -position insertpoint sim:/cordic_tb_top/clock
add wave -position insertpoint sim:/cordic_tb_top/reset
add wave -position insertpoint sim:/cordic_tb_top/vif/valid_in
add wave -position insertpoint -radix decimal sim:/cordic_tb_top/vif/rad_in
add wave -position insertpoint sim:/cordic_tb_top/vif/valid_out
add wave -position insertpoint -radix decimal sim:/cordic_tb_top/vif/sin_out
add wave -position insertpoint -radix decimal sim:/cordic_tb_top/vif/cos_out

# Internal DUT signals (Pipeline)
add wave -position insertpoint sim:/cordic_tb_top/dut/cordic_inst/valid_pipe
add wave -position insertpoint -radix decimal sim:/cordic_tb_top/dut/cordic_inst/z_pipe
add wave -position insertpoint -radix decimal sim:/cordic_tb_top/dut/cordic_inst/x_pipe
add wave -position insertpoint -radix decimal sim:/cordic_tb_top/dut/cordic_inst/y_pipe

# FIFO signals
add wave -position insertpoint -radix hex sim:/cordic_tb_top/dut/input_fifo/full
add wave -position insertpoint -radix hex sim:/cordic_tb_top/dut/input_fifo/empty
