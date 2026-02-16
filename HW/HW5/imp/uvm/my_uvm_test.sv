
`ifndef MY_UVM_TEST_SV
`define MY_UVM_TEST_SV

class my_uvm_test extends uvm_test;
    `uvm_component_utils(my_uvm_test)

    my_uvm_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = my_uvm_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        my_uvm_sequence seq;
        phase.raise_objection(this);
        seq = my_uvm_sequence::type_id::create("seq");
        seq.start(env.agent.sqr);
        #20000; // Wait for DUT to drain
        phase.drop_objection(this);
    endtask

endclass

`endif
