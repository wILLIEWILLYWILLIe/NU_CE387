add wave -noupdate -group matmul_tb
add wave -noupdate -group matmul_tb -radix hexadecimal /matmul_tb/*

add wave -noupdate -group dut
add wave -noupdate -group dut -radix hexadecimal /matmul_tb/dut/*

add wave -noupdate -group matmul_inst
add wave -noupdate -group matmul_inst -radix hexadecimal /matmul_tb/dut/matmul_inst/*

add wave -noupdate -group a_inst
add wave -noupdate -group a_inst -radix hexadecimal /matmul_tb/dut/a_inst/*

add wave -noupdate -group b_inst
add wave -noupdate -group b_inst -radix hexadecimal /matmul_tb/dut/b_inst/*

add wave -noupdate -group c_inst
add wave -noupdate -group c_inst -radix hexadecimal /matmul_tb/dut/c_inst/*
