
`ifndef MY_UVM_DRIVER_SV
`define MY_UVM_DRIVER_SV

class my_uvm_driver extends uvm_driver#(my_uvm_transaction);
    `uvm_component_utils(my_uvm_driver)

    virtual fft_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual fft_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("virtual interface must be set for: %s.vif", get_full_name()))
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.wr_en   <= 0;
        vif.real_in <= 0;
        vif.imag_in <= 0;

        `uvm_info("DRV", "Waiting for reset deassertion", UVM_LOW)
        // Wait for rst_n to go low first (reset asserted), then high (deasserted)
        wait(vif.reset === 0);
        wait(vif.reset === 1);
        `uvm_info("DRV", "Reset deasserted, starting drive loop", UVM_LOW)
        repeat(5) @(posedge vif.clock); // Extra settle time

        forever begin
            seq_item_port.get_next_item(req);
            drive_block(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_block(my_uvm_transaction tr);
        int len = tr.real_payload.size();
        `uvm_info("DRV", $sformatf("Driving block of %0d samples", len), UVM_LOW)
        for (int i = 0; i < len; i++) begin
            while (vif.in_full) @(posedge vif.clock);
            @(negedge vif.clock);
            vif.wr_en <= 1;
            vif.real_in <= tr.real_payload[i][DATA_WIDTH-1:0];
            vif.imag_in <= tr.imag_payload[i][DATA_WIDTH-1:0];
            @(posedge vif.clock);
            #1;
            vif.wr_en <= 0;
        end
    endtask

endclass

`endif
