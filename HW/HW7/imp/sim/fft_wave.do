
# Top-level signals
add wave -noupdate -group "TOP" -position insertpoint sim:/my_uvm_tb/clock
add wave -noupdate -group "TOP" -position insertpoint sim:/my_uvm_tb/reset

# Interface signals (UVM VIF)
add wave -noupdate -group "VIF" -position insertpoint sim:/my_uvm_tb/vif/wr_en
add wave -noupdate -group "VIF" -position insertpoint -radix decimal sim:/my_uvm_tb/vif/real_in
add wave -noupdate -group "VIF" -position insertpoint -radix decimal sim:/my_uvm_tb/vif/imag_in
add wave -noupdate -group "VIF" -position insertpoint sim:/my_uvm_tb/vif/in_full
add wave -noupdate -group "VIF" -position insertpoint sim:/my_uvm_tb/vif/rd_en
add wave -noupdate -group "VIF" -position insertpoint -radix decimal sim:/my_uvm_tb/vif/real_out
add wave -noupdate -group "VIF" -position insertpoint -radix decimal sim:/my_uvm_tb/vif/imag_out
add wave -noupdate -group "VIF" -position insertpoint sim:/my_uvm_tb/vif/out_empty

# Internal Bit-Reversal
add wave -noupdate -group "BIT_REV" -position insertpoint sim:/my_uvm_tb/dut/br_valid_out
add wave -noupdate -group "BIT_REV" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/br_real_out
add wave -noupdate -group "BIT_REV" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/br_imag_out

# FFT Stages Pipelines
add wave -noupdate -group "STAGES_PIPELINE" -position insertpoint sim:/my_uvm_tb/dut/stage_valid
add wave -noupdate -group "STAGES_PIPELINE" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/stage_real
add wave -noupdate -group "STAGES_PIPELINE" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/stage_imag

# Stage 3 Details (Last Stage)
add wave -noupdate -group "STAGE_3" -position insertpoint sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/valid_in
add wave -noupdate -group "STAGE_3" -position insertpoint sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/valid_out
add wave -noupdate -group "STAGE_3" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/real_in
add wave -noupdate -group "STAGE_3" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/real_out

# Multiplier inside Stage 3
add wave -noupdate -group "STAGE_3_MULT" -position insertpoint sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/mult_inst/valid_in
add wave -noupdate -group "STAGE_3_MULT" -position insertpoint sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/mult_inst/valid_out
add wave -noupdate -group "STAGE_3_MULT" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/mult_inst/out_real
add wave -noupdate -group "STAGE_3_MULT" -position insertpoint -radix decimal sim:/my_uvm_tb/dut/gen_stages[3]/stage_inst/mult_inst/out_imag

# Output FIFOs
add wave -noupdate -group "OUT_FIFO" -position insertpoint sim:/my_uvm_tb/dut/fifo_out_real/empty
add wave -noupdate -group "OUT_FIFO" -position insertpoint sim:/my_uvm_tb/dut/fifo_out_real/full

configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
# WaveRestoreZoom removed to allow automatic zoom full
