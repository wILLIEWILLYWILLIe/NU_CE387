
vlib work
vmap work work

vlog -sv ../sv/my_fft_pkg.sv
vlog -sv ../sv/fifo_ctrl.sv
vlog -sv ../sv/fifo.sv
vlog -sv ../sv/fft_bit_reversal.sv
vlog -sv ../sv/fft_stage.sv
vlog -sv ../sv/complex_mult.sv
vlog -sv ../sv/fft_top.sv

vlog -sv +incdir+../uvm ../uvm/my_uvm_pkg.sv
vlog -sv +incdir+../uvm ../uvm/fft_if.sv
vlog -sv +incdir+../uvm ../uvm/my_uvm_tb.sv

vsim -c -coverage -do "coverage save -onexit fft_coverage.ucdb; run -all; quit" my_uvm_tb +UVM_TESTNAME=my_uvm_test

vcover report fft_coverage.ucdb -details -output fft_coverage_report.txt
