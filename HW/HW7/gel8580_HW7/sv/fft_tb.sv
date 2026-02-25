
`timescale 1ns/10ps

module fft_tb import my_fft_pkg::*;;
    parameter real CLK_PERIOD = 10.0; // 100 MHz

    logic clk;
    logic rst_n;
    
    // Input FIFO Interface
    logic wr_en;
    logic signed [DATA_WIDTH-1:0] real_in_val, imag_in_val;
    logic in_full;
    
    // Output FIFO Interface
    logic rd_en;
    logic signed [DATA_WIDTH-1:0] real_out_val, imag_out_val;
    logic out_empty;

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // DUT
    fft_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .real_in(real_in_val),
        .imag_in(imag_in_val),
        .in_full(in_full),
        .rd_en(rd_en),
        .real_out(real_out_val),
        .imag_out(imag_out_val),
        .out_empty(out_empty)
    );

    // File I/O
    int fd_in_r, fd_in_i;
    logic signed [31:0] val_r, val_i;
    int out_cnt = 0;
    
    // Capture/Comparison variables
    int fd_out_r, fd_out_i;
    logic signed [31:0] golden_r, golden_i;
    int error_cnt = 0;
    int checked_samples = 0;

    // Performance Measurement
    int cycles = 0;
    int start_cycle = 0;
    int first_out_cycle = 0;
    int last_out_cycle = 0;
    bit first_in_done = 0;
    bit first_out_done = 0;

    always @(posedge clk) begin
        if (rst_n) begin
            cycles <= cycles + 1;
            if (wr_en && !first_in_done) begin
                start_cycle <= cycles;
                first_in_done <= 1;
            end
            if (rd_en && !out_empty) begin
                if (!first_out_done) begin
                    first_out_cycle <= cycles;
                    first_out_done <= 1;
                end
                last_out_cycle <= cycles;
            end
        end
    end

    initial begin
        // Reset
        rst_n = 0;
        wr_en = 0;
        real_in_val = 0;
        imag_in_val = 0;
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // Open Files
        fd_in_r = $fopen("../source/fft_in_real.txt", "r");
        fd_in_i = $fopen("../source/fft_in_imag.txt", "r");
        
        if (fd_in_r == 0 || fd_in_i == 0) begin
            $display("Error: Could not open input files.");
            $finish;
        end

        // Drive 16 samples + 48 flushing samples (to ensure all stages flush)
        if (DEBUG) $display("Starting Input Drive...");
        for (int k = 0; k < N + 48; k++) begin
            while (in_full) @(posedge clk);
            @(negedge clk);
            if (k < N) begin
                if ($fscanf(fd_in_r, "%h\n", val_r) == 1 && $fscanf(fd_in_i, "%h\n", val_i) == 1) begin
                    wr_en <= 1'b1;
                    real_in_val <= val_r[DATA_WIDTH-1:0];
                    imag_in_val <= val_i[DATA_WIDTH-1:0];
                end
            end else begin
                // Flush with 0s
                wr_en <= 1'b1;
                real_in_val <= '0;
                imag_in_val <= '0;
            end
            @(posedge clk);
            #1;
            wr_en <= 1'b0;
        end
        
        // Wait for all samples to emerge
        if (DEBUG) $display("Waiting for outputs...");
        while (checked_samples < N) begin
            @(posedge clk);
            if (cycles > 2000) break;
        end
        
        #(CLK_PERIOD * 10);
        $display("\n--- PERFORMANCE SUMMARY ---");
        $display("FFT Points (N): %d", N);
        $display("Latency (First In to First Out): %d cycles", first_out_cycle - start_cycle);
        $display("Processing Time (First In to Last Out): %d cycles", last_out_cycle - start_cycle);
        $display("Throughput Interval (Cycles between outputs): %.2f cycles/sample", 
                 real'(last_out_cycle - first_out_cycle) / (N - 1));
        $display("Effective Throughput at 100MHz: %.2f Msamples/sec", 
                 100.0 / (real'(last_out_cycle - first_out_cycle) / (N - 1)));
        $display("---------------------------\n");
        
        $display("All %d samples checked. Simulation Finished.", checked_samples);
        $finish;
    end

    initial begin
        fd_out_r = $fopen("../source/fft_out_real.txt", "r");
        fd_out_i = $fopen("../source/fft_out_imag.txt", "r");
        if (fd_out_r == 0 || fd_out_i == 0) begin
            $display("Error: Could not open golden output files.");
        end
    end

    assign rd_en = !out_empty;

    always @(posedge clk) begin
        if (rst_n) begin
            if (!out_empty) begin
                if (checked_samples < N) begin
                    if ($fscanf(fd_out_r, "%h\n", golden_r) == 1 && $fscanf(fd_out_i, "%h\n", golden_i) == 1) begin
                        if (real_out_val === golden_r[DATA_WIDTH-1:0] && imag_out_val === golden_i[DATA_WIDTH-1:0]) begin
                            if (DEBUG) $display("[%0t ns] Output Sample #%0d: %h + j%h | PASS (Bit-Accurate)", $time, checked_samples, real_out_val, imag_out_val);
                        end else begin
                            $display("[%0t ns] Output Sample #%0d: %h + j%h | FAIL! (Expected: %h + j%h)", 
                                     $time, checked_samples, real_out_val, imag_out_val, golden_r[DATA_WIDTH-1:0], golden_i[DATA_WIDTH-1:0]);
                            error_cnt++;
                        end
                        checked_samples++;
                    end
                end
                out_cnt <= out_cnt + 1;
            end
        end
    end

    final begin
        if (error_cnt == 0 && checked_samples == N) begin
            $display("\n*********************************");
            $display("*      TEST PASSED (100%%)       *");
            $display("*  All %0d samples are bit-accurate *", N);
            $display("*********************************\n");
        end else begin
            $display("\n*********************************");
            $display("*      TEST FAILED              *");
            $display("*  Mismatches: %0d / %0d samples  *", error_cnt, checked_samples);
            $display("*********************************\n");
        end
    end

endmodule
