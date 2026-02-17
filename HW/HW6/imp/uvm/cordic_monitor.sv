
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
                // We capture inputs and outputs. Ideally monitor sees inputs when valid_in is high
                // and outputs when valid_out is high.
                // However, for simplicity and since it's a block level test, 
                // we might need to correlate input to output or just grab output.
                // But Scoreboard needs input to calculate reference.
                // Simple approach: Drive sends input. Monitor observes OUTPUT.
                // But Monitor needs to know what INPUT caused this output for checking?
                // Or Scoreboard gets the transaction from Driver (if we had a Predictor)?
                // HW5 Scoreboard reads a file. So it expects the SEQUENCE of outputs to match the file.
                // So Monitor just captures outputs.
                
                tr.sin_out = vif.cb.sin_out;
                tr.cos_out = vif.cb.cos_out;
                // rad_in might not be valid on valid_out cycle, ignore it or need more complex monitor.
                // For file-based checking like HW5, we just check data stream.
                
                mon_ap.write(tr);
            end
        end
    endtask

endclass

`endif
