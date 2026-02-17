
`ifndef CORDIC_ENV_SV
`define CORDIC_ENV_SV

class cordic_env extends uvm_env;
    `uvm_component_utils(cordic_env)

    cordic_agent agent;
    cordic_scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = cordic_agent::type_id::create("agent", this);
        sb = cordic_scoreboard::type_id::create("sb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.mon.mon_ap.connect(sb.sb_export);
    endfunction

endclass

`endif
