# CE387 Homework Repository

This repository contains homework assignments and projects for the CE387 - REAL-TIME DIGITAL SYSTEMS DESIGN AND VERIFICATION WITH FPGAS course.

## Structure

The repository is organized by homework assignment:

- **HW/HW1/**: Homework 1
  - `sv/`: SystemVerilog source files
  - `sim/`: Simulation files
  - `syn/`: Synthesis scripts and output
  - `FPGA_HW1.pdf`: Assignment description

- **HW/HW2/**: Homework 2
  - `sv/`: SystemVerilog source files
  - `source/`: Additional source files
  - `sim/`: Simulation files
  - `syn/`: Synthesis scripts and output
  - `FPGA_HW2.pdf`: Assignment description

- **HW/HW3/**: Homework 3
  - `sv/`: SystemVerilog source files
  - `sim/`: Simulation files
  - `syn/`: Synthesis scripts and output
  - `hw3/`: Additional source files (motion detection, opencv demo)
  - `FPGA_HW3.pdf`: Assignment description

## Usage

### Simulation
To run simulations, navigate to the `sim` directory within each homework folder (e.g., `HW/HW3/sim`) and use ModelSim.

Example for HW3:
```bash
cd HW/HW3/sim
vsim -c -do motion_detect_sim.do
```
- `vsim`: Invokes the ModelSim simulator.
- `-c`: Runs in command-line mode (no GUI).
- `-do <script.do>`: Executes the specified Tcl script. The script typically compiles the SystemVerilog source files and runs the testbench.

### Synthesis
To run synthesis, navigate to the `syn` directory within each homework folder (e.g., `HW/HW3/syn`) and use Synplify Pro.

Example for HW3:
```bash
cd HW/HW3/syn
synplify_pro -batch motion_detect.prj
```
- `synplify_pro`: Invokes the Synplify Pro synthesis tool.
- `-batch`: Runs in batch mode (no GUI).
- `<project.prj>`: The project file containing settings to synthesize the design. This will generate the netlist (e.g., in `rev_1/`).
