
`ifndef CORDIC_TEST_SV
`define CORDIC_TEST_SV

class cordic_test extends uvm_test;
    `uvm_component_utils(cordic_test)

    cordic_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = cordic_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        cordic_sequence seq;
        phase.raise_objection(this);
        seq = cordic_sequence::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask

endclass

`endif
