
`ifndef MY_UVM_SCOREBOARD_SV
`define MY_UVM_SCOREBOARD_SV

class my_uvm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(my_uvm_scoreboard)

    uvm_analysis_imp #(my_uvm_transaction, my_uvm_scoreboard) sb_export;
    
    int fd;
    int error_count = 0;
    int byte_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Open the reference file
        // Note: Run from 'sim' directory
        fd = $fopen(REF_OUTPUT_NAME, "rb"); 
        if (fd == 0) begin
            `uvm_fatal("SCB", $sformatf("Could not open %s", REF_OUTPUT_NAME))
        end
    endfunction

    virtual function void write(my_uvm_transaction tr);
        int len = tr.payload.size();
        int expected_char;
        
        for (int i = 0; i < len; i++) begin
            expected_char = $fgetc(fd);
            
            if (expected_char == -1) begin
                `uvm_error("SCB", "Simulation output longer than reference file")
                return;
            end
            
            byte_count++;
            
            if (tr.payload[i] !== expected_char) begin
                `uvm_error("SCB", $sformatf("Mismatch at byte %0d: Expected '%c' (0x%02x), Got '%c' (0x%02x)", 
                                            byte_count, expected_char, expected_char, tr.payload[i], tr.payload[i]))
                error_count++;
            end
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        if (error_count == 0) begin
            `uvm_info("SCB", $sformatf("Test Passed! Checked %0d bytes.", byte_count), UVM_LOW)
        end else begin
            `uvm_error("SCB", $sformatf("Test Failed with %0d errors.", error_count))
        end
        $fclose(fd);
    endfunction

endclass

`endif
