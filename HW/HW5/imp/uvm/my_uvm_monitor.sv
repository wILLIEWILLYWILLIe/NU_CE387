
`ifndef MY_UVM_MONITOR_SV
`define MY_UVM_MONITOR_SV

class my_uvm_monitor extends uvm_monitor;
    `uvm_component_utils(my_uvm_monitor)

    virtual udp_parser_if vif;
    uvm_analysis_port #(my_uvm_transaction) mon_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual udp_parser_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("virtual interface must be set for: %s.vif", get_full_name()))
        end
        mon_ap = new("mon_ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        my_uvm_transaction tr;
        logic [7:0] data_q[$];
        logic in_packet = 0;

        // Always enable read to drain output FIFO
        vif.dout_rd_en <= 1; 

        forever begin
            @(posedge vif.clock);
            
            if (vif.dout_empty == 0) begin // Valid data available
                `uvm_info("MON", $sformatf("Not Empty. SOF:%0b", vif.dout_sof), UVM_HIGH)
                // Check for SOF
                if (vif.dout_sof) begin
                    data_q.delete();
                    data_q.delete();
                    in_packet = 1;
                    `uvm_info("MON", "Detected SOF", UVM_LOW)
                end
                
                if (in_packet) begin
                    `uvm_info("MON", $sformatf("Data: 0x%02x SOF:%0b EOF:%0b", vif.dout, vif.dout_sof, vif.dout_eof), UVM_HIGH)
                    data_q.push_back(vif.dout);
                end
                
                // Check for EOF
                if (vif.dout_eof && in_packet) begin
                    tr = my_uvm_transaction::type_id::create("tr");
                    tr.payload = new[data_q.size()];
                    foreach(data_q[i]) tr.payload[i] = data_q[i];
                    
                    mon_ap.write(tr);
                    
                    in_packet = 0;
                    data_q.delete();
                end
            end
        end
    endtask

endclass

`endif
