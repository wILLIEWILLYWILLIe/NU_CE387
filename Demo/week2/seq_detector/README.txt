Sequence Detector Demo

### Simulate ###
source /vol/eecs392/env/modelsim.env
cd sim
vsim -do sequence_detector_sim.do

### Synthesis ###
source /vol/eecs392/env/synplify.env
cd syn
synplify_premier sequence_detector.prj
