
`ifndef MY_UVM_SCOREBOARD_SV
`define MY_UVM_SCOREBOARD_SV

class my_uvm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(my_uvm_scoreboard)

    uvm_analysis_imp #(my_uvm_transaction, my_uvm_scoreboard) sb_export;
    
    int fd_r, fd_i;
    int error_count = 0;
    int sample_count = 0;

    // ---- Functional Coverage ----
    logic signed [DATA_WIDTH-1:0] cov_in_real, cov_in_imag;
    logic signed [DATA_WIDTH-1:0] cov_out_real, cov_out_imag;
    int cov_sample_idx;

    // Input coverage: real and imaginary value ranges
    covergroup cg_input_data;
        option.per_instance = 1;

        real_sign: coverpoint cov_in_real[DATA_WIDTH-1] {
            bins positive = {0};
            bins negative = {1};
        }
        imag_sign: coverpoint cov_in_imag[DATA_WIDTH-1] {
            bins positive = {0};
            bins negative = {1};
        }
        real_range: coverpoint cov_in_real {
            bins large_neg  = {[16'sh8000 : 16'shC000]};
            bins small_neg  = {[16'shC001 : 16'shFFFF]};
            bins zero       = {0};
            bins small_pos  = {[16'sh0001 : 16'sh3FFF]};
            bins large_pos  = {[16'sh4000 : 16'sh7FFF]};
        }
        imag_range: coverpoint cov_in_imag {
            bins large_neg  = {[16'sh8000 : 16'shC000]};
            bins small_neg  = {[16'shC001 : 16'shFFFF]};
            bins zero       = {0};
            bins small_pos  = {[16'sh0001 : 16'sh3FFF]};
            bins large_pos  = {[16'sh4000 : 16'sh7FFF]};
        }
        real_x_imag_sign: cross real_sign, imag_sign;
    endgroup

    // Output coverage: real and imaginary value ranges
    covergroup cg_output_data;
        option.per_instance = 1;

        real_sign: coverpoint cov_out_real[DATA_WIDTH-1] {
            bins positive = {0};
            bins negative = {1};
        }
        imag_sign: coverpoint cov_out_imag[DATA_WIDTH-1] {
            bins positive = {0};
            bins negative = {1};
        }
        real_range: coverpoint cov_out_real {
            bins large_neg  = {[16'sh8000 : 16'shC000]};
            bins small_neg  = {[16'shC001 : 16'shFFFF]};
            bins zero       = {0};
            bins small_pos  = {[16'sh0001 : 16'sh3FFF]};
            bins large_pos  = {[16'sh4000 : 16'sh7FFF]};
        }
        imag_range: coverpoint cov_out_imag {
            bins large_neg  = {[16'sh8000 : 16'shC000]};
            bins small_neg  = {[16'shC001 : 16'shFFFF]};
            bins zero       = {0};
            bins small_pos  = {[16'sh0001 : 16'sh3FFF]};
            bins large_pos  = {[16'sh4000 : 16'sh7FFF]};
        }
        real_x_imag_sign: cross real_sign, imag_sign;
    endgroup

    // Sample index coverage (all FFT bins exercised)
    covergroup cg_sample_index;
        option.per_instance = 1;
        sample_idx: coverpoint cov_sample_idx {
            bins indices[] = {[0:FFT_N-1]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_input_data   = new();
        cg_output_data  = new();
        cg_sample_index = new();
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
        logic signed [DATA_WIDTH-1:0] got_r, got_i, ref_r, ref_i;
        
        `uvm_info("SCB", $sformatf("Received block of %0d samples", len), UVM_LOW)
        for (int i = 0; i < len; i++) begin
            if ($fscanf(fd_r, "%h\n", exp_r) == 1 && $fscanf(fd_i, "%h\n", exp_i) == 1) begin
                sample_count++;
                
                got_r = tr.real_payload[i][DATA_WIDTH-1:0];
                got_i = tr.imag_payload[i][DATA_WIDTH-1:0];
                ref_r = exp_r[DATA_WIDTH-1:0];
                ref_i = exp_i[DATA_WIDTH-1:0];
                
                // Sample coverage
                cov_out_real = got_r;
                cov_out_imag = got_i;
                cov_in_real  = ref_r;  // Use reference as a proxy for input coverage
                cov_in_imag  = ref_i;
                cov_sample_idx = i;
                cg_output_data.sample();
                cg_input_data.sample();
                cg_sample_index.sample();
                
                if (got_r !== ref_r || got_i !== ref_i) begin
                    `uvm_error("SCB", $sformatf("Mismatch at sample %0d: Exp %h+j%h, Got %h+j%h", 
                                                sample_count, ref_r, ref_i, got_r, got_i))
                    error_count++;
                end else begin
                    `uvm_info("SCB", $sformatf("Sample %0d matched: %h+j%h", sample_count, got_r, got_i), UVM_LOW)
                end
            end else begin
                `uvm_error("SCB", "More hardware outputs than reference values")
            end
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        if (error_count == 0 && sample_count > 0) begin
            `uvm_info("SCB", $sformatf("TEST PASSED! All %0d samples are bit-accurate.", sample_count), UVM_LOW)
        end else begin
            `uvm_error("SCB", $sformatf("TEST FAILED with %0d errors out of %0d checked samples.", error_count, sample_count))
        end

        // Coverage report
        `uvm_info("SCB", $sformatf("Input Data Coverage:  %.1f%%", cg_input_data.get_coverage()), UVM_LOW)
        `uvm_info("SCB", $sformatf("Output Data Coverage: %.1f%%", cg_output_data.get_coverage()), UVM_LOW)
        `uvm_info("SCB", $sformatf("Sample Index Coverage: %.1f%%", cg_sample_index.get_coverage()), UVM_LOW)

        $fclose(fd_r);
        $fclose(fd_i);
    endfunction

endclass

`endif
