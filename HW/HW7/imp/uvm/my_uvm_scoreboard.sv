
`ifndef MY_UVM_SCOREBOARD_SV
`define MY_UVM_SCOREBOARD_SV

class my_uvm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(my_uvm_scoreboard)

    uvm_analysis_imp #(my_uvm_transaction, my_uvm_scoreboard) sb_export;
    
    int fd_r, fd_i;
    int error_count = 0;
    int sample_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        fd_r = $fopen(REF_REAL_OUT, "r");
        fd_i = $fopen(REF_IMAG_OUT, "r");
        if (fd_r == 0 || fd_i == 0) begin
            `uvm_fatal("SCB", "Could not open output reference files")
        end
    endfunction

    virtual function void write(my_uvm_transaction tr);
        int len = tr.real_payload.size();
        int exp_r, exp_i;
        
        `uvm_info("SCB", $sformatf("Received block of %0d samples", len), UVM_LOW)
        for (int i = 0; i < len; i++) begin
            if ($fscanf(fd_r, "%h\n", exp_r) == 1 && $fscanf(fd_i, "%h\n", exp_i) == 1) begin
                sample_count++;
                
                // Allow some tolerance for quantization differences if scaling differs slightly
                // But generally should be bit-true if quantization matches C code exactly.
                if (tr.real_payload[i] !== exp_r[DATA_WIDTH-1:0] || tr.imag_payload[i] !== exp_i[DATA_WIDTH-1:0]) begin
                    `uvm_error("SCB", $sformatf("Mismatch at sample %0d: Exp %h+j%h, Got %h+j%h", 
                                                sample_count, exp_r[DATA_WIDTH-1:0], exp_i[DATA_WIDTH-1:0], 
                                                tr.real_payload[i], tr.imag_payload[i]))
                    error_count++;
                end else begin
                    `uvm_info("SCB", $sformatf("Sample %0d matched: %h+j%h", sample_count, tr.real_payload[i], tr.imag_payload[i]), UVM_HIGH)
                end
            end else begin
                `uvm_error("SCB", "More hardware outputs than reference values")
            end
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        if (error_count == 0 && sample_count > 0) begin
            `uvm_info("SCB", $sformatf("Test Passed! Checked %0d samples.", sample_count), UVM_LOW)
        end else begin
            `uvm_error("SCB", $sformatf("Test Failed with %0d errors out of %0d checked samples.", error_count, sample_count))
        end
        $fclose(fd_r);
        $fclose(fd_i);
    endfunction

endclass

`endif
