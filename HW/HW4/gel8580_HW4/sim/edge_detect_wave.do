

#add wave -noupdate -group my_uvm_tb
#add wave -noupdate -group my_uvm_tb -radix hexadecimal /my_uvm_tb/*

add wave -noupdate -group my_uvm_tb/edge_detect_inst
add wave -noupdate -group my_uvm_tb/edge_detect_inst -radix hexadecimal /my_uvm_tb/edge_detect_inst/*

add wave -noupdate -group my_uvm_tb/edge_detect_inst/gs_inst
add wave -noupdate -group my_uvm_tb/edge_detect_inst/gs_inst -radix hexadecimal /my_uvm_tb/edge_detect_inst/gs_inst/*

add wave -noupdate -group my_uvm_tb/edge_detect_inst/sob_inst
add wave -noupdate -group my_uvm_tb/edge_detect_inst/sob_inst -radix hexadecimal /my_uvm_tb/edge_detect_inst/sob_inst/*

add wave -noupdate -group my_uvm_tb/edge_detect_inst/fifo_in
add wave -noupdate -group my_uvm_tb/edge_detect_inst/fifo_in -radix hexadecimal /my_uvm_tb/edge_detect_inst/fifo_in/*

add wave -noupdate -group my_uvm_tb/edge_detect_inst/fifo_gs_sob
add wave -noupdate -group my_uvm_tb/edge_detect_inst/fifo_gs_sob -radix hexadecimal /my_uvm_tb/edge_detect_inst/fifo_gs_sob/*

add wave -noupdate -group my_uvm_tb/edge_detect_inst/fifo_out
add wave -noupdate -group my_uvm_tb/edge_detect_inst/fifo_out -radix hexadecimal /my_uvm_tb/edge_detect_inst/fifo_out/*

