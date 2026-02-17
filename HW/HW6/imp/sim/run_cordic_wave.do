
add wave -position insertpoint sim:/cordic_tb_top/clock
add wave -position insertpoint sim:/cordic_tb_top/reset
add wave -position insertpoint sim:/cordic_tb_top/vif/valid_in
add wave -position insertpoint -radix hex sim:/cordic_tb_top/vif/rad_in
add wave -position insertpoint sim:/cordic_tb_top/vif/valid_out
add wave -position insertpoint -radix hex sim:/cordic_tb_top/vif/sin_out
add wave -position insertpoint -radix hex sim:/cordic_tb_top/vif/cos_out

# Internal DUT signals
add wave -position insertpoint sim:/cordic_tb_top/dut/state
add wave -position insertpoint -radix unsigned sim:/cordic_tb_top/dut/iter
add wave -position insertpoint -radix hex sim:/cordic_tb_top/dut/x
add wave -position insertpoint -radix hex sim:/cordic_tb_top/dut/y
add wave -position insertpoint -radix hex sim:/cordic_tb_top/dut/z
