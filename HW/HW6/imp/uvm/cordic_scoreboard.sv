
`ifndef CORDIC_SCOREBOARD_SV
`define CORDIC_SCOREBOARD_SV

class cordic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cordic_scoreboard)

    uvm_analysis_imp #(cordic_transaction, cordic_scoreboard) sb_export;
    
    int sin_fd, cos_fd;
    int error_count = 0;
    int test_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sin_fd = $fopen(SIN_FILE_NAME, "r");
        cos_fd = $fopen(COS_FILE_NAME, "r");
        
        if (sin_fd == 0 || cos_fd == 0) begin
            `uvm_fatal("SCB", "Could not open reference files (sin.txt or cos.txt)")
        end
    endfunction

    virtual function void write(cordic_transaction tr);
        logic signed [15:0] exp_sin, exp_cos;
        int code1, code2;
        
        code1 = $fscanf(sin_fd, "%h\n", exp_sin);
        code2 = $fscanf(cos_fd, "%h\n", exp_cos);
        
        if (code1 != 1 || code2 != 1) begin
            `uvm_error("SCB", "More DUT outputs than reference vectors")
            return;
        end
        
        test_count++;
        
        if (tr.sin_out !== exp_sin || tr.cos_out !== exp_cos) begin
            `uvm_error("SCB", $sformatf("Mismatch #%0d: Exp sin=%h cos=%h | Got sin=%h cos=%h", 
                                        test_count, exp_sin, exp_cos, tr.sin_out, tr.cos_out))
            error_count++;
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        if (error_count == 0) begin
            `uvm_info("SCB", $sformatf("PASSED: Checked %0d vectors", test_count), UVM_LOW)
        end else begin
            `uvm_error("SCB", $sformatf("FAILED: %0d errors out of %0d tests", error_count, test_count))
        end
        $fclose(sin_fd);
        $fclose(cos_fd);
    endfunction

endclass

`endif
