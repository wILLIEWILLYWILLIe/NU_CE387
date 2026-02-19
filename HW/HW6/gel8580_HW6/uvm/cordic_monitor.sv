
`ifndef CORDIC_MONITOR_SV
`define CORDIC_MONITOR_SV

class cordic_monitor extends uvm_monitor;
    `uvm_component_utils(cordic_monitor)

    virtual cordic_if vif;
    uvm_analysis_port#(cordic_transaction) mon_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if(!uvm_config_db#(virtual cordic_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get vif");
    endfunction

    virtual task run_phase(uvm_phase phase);
        cordic_transaction tr;
        
        forever begin
            @(vif.cb);
            if (vif.cb.valid_out) begin
                tr = cordic_transaction::type_id::create("tr");
                tr.sin_out = vif.cb.sin_out;
                tr.cos_out = vif.cb.cos_out;
                mon_ap.write(tr);
            end
        end
    endtask

endclass

`endif
