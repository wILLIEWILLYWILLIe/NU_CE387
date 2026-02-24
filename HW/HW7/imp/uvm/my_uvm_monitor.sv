
`ifndef MY_UVM_MONITOR_SV
`define MY_UVM_MONITOR_SV

class my_uvm_monitor extends uvm_monitor;
    `uvm_component_utils(my_uvm_monitor)

    virtual fft_if vif;
    uvm_analysis_port#(my_uvm_transaction) mon_ap;

    // Throughput/Latency measurement
    int first_in_cycle = -1;
    int first_out_cycle = -1;
    int last_out_cycle = -1;
    int cycle_count = 0;

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
        int idx;

        // Track cycles
        fork
            forever begin
                @(posedge vif.clock);
                if (vif.reset) cycle_count++;
                // Detect first input
                if (vif.wr_en && !vif.in_full && first_in_cycle == -1)
                    first_in_cycle = cycle_count;
            end
        join_none

        forever begin
            tr = my_uvm_transaction::type_id::create("tr");
            tr.real_payload = new[FFT_N];
            tr.imag_payload = new[FFT_N];
            idx = 0;
            
            while (idx < FFT_N) begin
                @(posedge vif.clock);
                #1;
                
                if (!vif.out_empty) begin
                    tr.real_payload[idx] = vif.real_out;
                    tr.imag_payload[idx] = vif.imag_out;
                    
                    // Track first/last output cycle
                    if (first_out_cycle == -1) first_out_cycle = cycle_count;
                    last_out_cycle = cycle_count;
                    
                    `uvm_info("MON", $sformatf("Captured sample #%0d: %04h + j%04h", idx,
                              vif.real_out[DATA_WIDTH-1:0], vif.imag_out[DATA_WIDTH-1:0]), UVM_LOW)
                    idx++;
                    vif.rd_en <= 1;
                end else begin
                    vif.rd_en <= 0;
                end
            end
            vif.rd_en <= 0;
            
            `uvm_info("MON", "Sending block transaction to scoreboard", UVM_LOW)
            mon_ap.write(tr);
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        int latency, proc_time;
        real throughput_interval, effective_throughput;
        
        if (first_in_cycle >= 0 && first_out_cycle >= 0) begin
            latency = first_out_cycle - first_in_cycle;
            proc_time = last_out_cycle - first_in_cycle;
            throughput_interval = real'(last_out_cycle - first_out_cycle) / (FFT_N - 1);
            effective_throughput = 100.0 / throughput_interval;
            
            `uvm_info("MON", "--- PERFORMANCE SUMMARY ---", UVM_LOW)
            `uvm_info("MON", $sformatf("FFT Points (N): %0d", FFT_N), UVM_LOW)
            `uvm_info("MON", $sformatf("Latency (First In to First Out): %0d cycles", latency), UVM_LOW)
            `uvm_info("MON", $sformatf("Processing Time (First In to Last Out): %0d cycles", proc_time), UVM_LOW)
            `uvm_info("MON", $sformatf("Throughput Interval: %.2f cycles/sample", throughput_interval), UVM_LOW)
            `uvm_info("MON", $sformatf("Effective Throughput at 100MHz: %.2f Msamples/sec", effective_throughput), UVM_LOW)
            `uvm_info("MON", "---------------------------", UVM_LOW)
        end
    endfunction

endclass

`endif
