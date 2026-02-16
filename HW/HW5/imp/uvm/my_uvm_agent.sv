
`ifndef MY_UVM_AGENT_SV
`define MY_UVM_AGENT_SV

class my_uvm_agent extends uvm_agent;
    `uvm_component_utils(my_uvm_agent)

    uvm_sequencer#(my_uvm_transaction) sqr;
    my_uvm_driver drv;
    my_uvm_monitor mon;
    my_uvm_coverage cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(my_uvm_transaction)::type_id::create("sqr", this);
        drv = my_uvm_driver::type_id::create("drv", this);
        mon = my_uvm_monitor::type_id::create("mon", this);
        cov = my_uvm_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
        mon.mon_ap.connect(cov.analysis_export);
    endfunction

endclass

`endif
