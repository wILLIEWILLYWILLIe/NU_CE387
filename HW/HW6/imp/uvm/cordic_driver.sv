
`ifndef CORDIC_DRIVER_SV
`define CORDIC_DRIVER_SV

class cordic_driver extends uvm_driver#(cordic_transaction);
    `uvm_component_utils(cordic_driver)

    virtual cordic_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual cordic_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Could not get vif");
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.cb.valid_in <= 0;
        vif.cb.rad_in   <= 0;
        
        wait(!vif.reset);
        @(vif.cb);

        forever begin
            seq_item_port.get_next_item(req);
            
            // Drive transaction
            vif.cb.rad_in   <= req.rad_in;
            vif.cb.valid_in <= 1;
            
            @(vif.cb);
            vif.cb.valid_in <= 0;
            
            // Wait for processing to complete effectively or just fire next? 
            // Design is iterative, not pipelined. Must wait for DONE (valid_out).
            wait(vif.cb.valid_out);
            @(vif.cb); // Hold one cycle if needed or just ready for next
            
            seq_item_port.item_done();
        end
    endtask

endclass

`endif
