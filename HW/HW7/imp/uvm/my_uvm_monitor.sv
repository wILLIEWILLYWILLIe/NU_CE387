
`ifndef MY_UVM_MONITOR_SV
`define MY_UVM_MONITOR_SV

class my_uvm_monitor extends uvm_monitor;
    `uvm_component_utils(my_uvm_monitor)

    virtual fft_if vif;
    uvm_analysis_port#(my_uvm_transaction) mon_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual fft_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("virtual interface must be set for: %s.vif", get_full_name()))
        end
        mon_ap = new("mon_ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        my_uvm_transaction tr;
        vif.rd_en <= 0;

        forever begin
            tr = my_uvm_transaction::type_id::create("tr");
            
            // Collect a block of N samples
            for (int i = 0; i < N; i++) begin
                while (vif.out_empty) @(posedge vif.clock);
                
                @(negedge vif.clock);
                vif.rd_en <= 1;
                @(posedge vif.clock);
                
                // Sample data on posedge after rd_en
                tr.real_payload.push_back(vif.real_out);
                tr.imag_payload.push_back(vif.imag_out);
                
                #1; // Hold time
                vif.rd_en <= 0;
                `uvm_info("MON", $sformatf("Captured sample #%0d: %h + j%h", i, vif.real_out, vif.imag_out), UVM_HIGH)
            end
            
            `uvm_info("MON", "Sending block transaction to scoreboard", UVM_LOW)
            mon_ap.write(tr);
        end
    endtask

endclass

`endif
