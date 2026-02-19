
`ifndef CORDIC_AGENT_SV
`define CORDIC_AGENT_SV

class cordic_agent extends uvm_agent;
    `uvm_component_utils(cordic_agent)

    uvm_sequencer#(cordic_transaction) sqr;
    cordic_driver drv;
    cordic_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(cordic_transaction)::type_id::create("sqr", this);
        drv = cordic_driver::type_id::create("drv", this);
        mon = cordic_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass

`endif
