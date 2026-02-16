
`ifndef MY_UVM_DRIVER_SV
`define MY_UVM_DRIVER_SV

class my_uvm_driver extends uvm_driver#(my_uvm_transaction);
    `uvm_component_utils(my_uvm_driver)

    virtual udp_parser_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual udp_parser_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("virtual interface must be set for: %s.vif", get_full_name()))
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.din_wr_en <= 0;
        vif.din_sof   <= 0;
        vif.din_eof   <= 0;
        
        // Wait for reset to deassert
        wait(vif.reset === 0);
        @(posedge vif.clock);

        fork
            handle_output();
        join_none

        forever begin
            seq_item_port.get_next_item(req);
            drive_packet(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_packet(my_uvm_transaction tr);
        int len = tr.payload.size();
        `uvm_info("DRV", $sformatf("Driving packet size=%0d", len), UVM_HIGH)
        
        for (int i = 0; i < len; i++) begin
            // Wait if full
            while (vif.din_full) @(posedge vif.clock);

            @(negedge vif.clock);
            vif.din_wr_en <= 1;
            vif.din       <= tr.payload[i];
            
            // Set SOF on first byte
            if (i == 0) vif.din_sof <= 1;
            else        vif.din_sof <= 0;
            
            // Set EOF on last byte
            if (i == len - 1) vif.din_eof <= 1;
            else              vif.din_eof <= 0;
        end
        
        @(negedge vif.clock);
        while (vif.din_full) @(posedge vif.clock); // Ensure last write is accepted
        vif.din_wr_en <= 0;
        vif.din_sof   <= 0;
        vif.din_eof   <= 0;
        
        // Add some IDLE cycles between packets if needed
        repeat(5) @(posedge vif.clock);
    endtask

    task handle_output();
        vif.dout_rd_en <= 0;
        forever begin
            // Decide rd_en BEFORE posedge to match TB logic
            @(negedge vif.clock);
            if (vif.dout_empty == 0) begin
                vif.dout_rd_en <= 1;
                // `uvm_info("DRV", $sformatf("Reading output byte: 0x%02x", vif.dout), UVM_HIGH)
            end else begin
                vif.dout_rd_en <= 0;
            end
        end
    endtask

endclass

`endif
