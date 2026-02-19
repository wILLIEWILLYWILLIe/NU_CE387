
# Makefile for HW6 CORDIC UVM Simulation

# Paths
SOURCE_DIR = ../source
SV_DIR     = ../sv
UVM_DIR    = ../uvm
SIM_DIR    = .

# Tools
CXX = g++
VSIM = vsim

# Targets
all: clean gen_vectors run_uvm

gen_vectors:
	$(CXX) -o $(SOURCE_DIR)/cordic_ref $(SOURCE_DIR)/cordic.cpp -lm
	cd $(SOURCE_DIR) && ./cordic_ref

run_uvm:
	vsim -c -do cordic_sim.do

clean:
	rm -rf work transcript $(SOURCE_DIR)/cordic_ref $(SOURCE_DIR)/rad.txt $(SOURCE_DIR)/sin.txt $(SOURCE_DIR)/cos.txt
