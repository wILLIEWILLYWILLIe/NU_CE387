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

- **HW/HW4/**: Homework 4
  - `edge_detect/`: Contains source, simulation, and synthesis files for edge detection
    - `sv/`: SystemVerilog source files
    - `sim/`: Simulation files
    - `syn/`: Synthesis scripts and output
    - `uvm/`: UVM verification environment
  - `FPGA_HW4.pdf`: Assignment description

- **HW/HW5/**: Homework 5
  - `imp/`: Implementation directory
    - `sv/`: SystemVerilog source files
    - `sim/`: Simulation files
    - `syn/`: Synthesis scripts and output
    - `uvm/`: UVM verification environment
  - `udp/`: UDP implementation files
  - `FPGA_HW5.pdf`: Assignment description
  - `HW.tex`: Homework report (LaTeX)

- **Demo/**: Demonstration files
  - `week1/`: Week 1 demos
  - `week2/`: Week 2 demos

- **Lecture/**: Lecture slides (PDFs)

## Usage

### Simulation
To run simulations, navigate to the `sim` directory within each homework folder and use ModelSim. Note that for HW4 and HW5, the `sim` directory is located inside a subdirectory.

- **HW1-HW3**: `HW/HW<#>/sim`
- **HW4**: `HW/HW4/edge_detect/sim`
- **HW5**: `HW/HW5/imp/sim`

Example for HW4:
```bash
cd HW/HW4/edge_detect/sim
vsim -c -do <script.do>
```
- `vsim`: Invokes the ModelSim simulator.
- `-c`: Runs in command-line mode (no GUI).
- `-do <script.do>`: Executes the specified Tcl script.

### Synthesis
To run synthesis, navigate to the `syn` directory within each homework folder and use Synplify Pro. Similar to simulation, for HW4 and HW5, this is inside a subdirectory.

- **HW1-HW3**: `HW/HW<#>/syn`
- **HW4**: `HW/HW4/edge_detect/syn`
- **HW5**: `HW/HW5/imp/syn`

Example for HW5:
```bash
cd HW/HW5/imp/syn
synplify_pro -batch <project.prj>
```
- `synplify_pro`: Invokes the Synplify Pro synthesis tool.
- `-batch`: Runs in batch mode (no GUI).
- `<project.prj>`: The project file containing settings to synthesize the design.
