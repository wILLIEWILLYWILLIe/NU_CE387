BRAM Demo

### Simulate ###
source /vol/eecs392/env/modelsim.env
cd sim
vsim -do bram_block_sim.do

### Synthesis ###
source /vol/eecs392/env/synplify.env
cd syn
synplify_premier bram_block.prj
