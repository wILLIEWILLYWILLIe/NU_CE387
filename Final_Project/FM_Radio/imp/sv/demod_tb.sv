// =============================================================
// demod_tb.sv — Testbench for demodulate.sv
// Reads: ch_I.txt, ch_Q.txt (channel filter output)
// Compares: demod.txt (golden FM demodulator output)
// =============================================================

`timescale 1ns/1ps
import fir_pkg::*;

module demod_tb;

    // -------------------------------------------------------
    // Test txt
    // -------------------------------------------------------
    localparam string REAL_IN_FILE   = "../../test/ch_I.txt";
    localparam string IMAG_IN_FILE   = "../../test/ch_Q.txt";
    localparam string GOLDEN_FILE    = "../../test/demod.txt";

    localparam int N_SAMPLES  = 262144;
    localparam int CLK_PERIOD = 10;

    // DUT signals
    logic                           clk, rst_n;
    logic                           valid_in;
    logic signed [WIDTH-1:0]        real_in, imag_in;
    logic                           valid_out;
    logic signed [WIDTH-1:0]        demod_out;

    // DUT
    demodulate dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .real_in   (real_in),
        .imag_in   (imag_in),
        .valid_out (valid_out),
        .demod_out (demod_out)
    );

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test vectors
    logic signed [WIDTH-1:0] in_real_data  [0:N_SAMPLES-1];
    logic signed [WIDTH-1:0] in_imag_data  [0:N_SAMPLES-1];
    logic signed [WIDTH-1:0] golden_data   [0:N_SAMPLES-1];

    integer errors, checked, out_idx;
    integer fd, code, idx, val;

    // Main test
    initial begin
        $display("=== FM Demodulator Testbench ===");

        // Load ch_I.txt
        fd = $fopen(REAL_IN_FILE, "r");
        if (fd == 0) begin $display("ERROR: cannot open ch_I.txt"); $finish; end
        idx = 0;
        while (!$feof(fd) && idx < N_SAMPLES) begin
            code = $fscanf(fd, "%d\n", val);
            if (code == 1) begin in_real_data[idx] = val; idx = idx + 1; end
        end
        $fclose(fd);
        $display("  Loaded %0d real samples", idx);

        // Load ch_Q.txt
        fd = $fopen(IMAG_IN_FILE, "r");
        if (fd == 0) begin $display("ERROR: cannot open ch_Q.txt"); $finish; end
        idx = 0;
        while (!$feof(fd) && idx < N_SAMPLES) begin
            code = $fscanf(fd, "%d\n", val);
            if (code == 1) begin in_imag_data[idx] = val; idx = idx + 1; end
        end
        $fclose(fd);
        $display("  Loaded %0d imag samples", idx);

        // Load demod.txt (golden)
        fd = $fopen(GOLDEN_FILE, "r");
        if (fd == 0) begin $display("ERROR: cannot open demod.txt"); $finish; end
        idx = 0;
        while (!$feof(fd) && idx < N_SAMPLES) begin
            code = $fscanf(fd, "%d\n", val);
            if (code == 1) begin golden_data[idx] = val; idx = idx + 1; end
        end
        $fclose(fd);
        $display("  Loaded %0d golden samples", idx);

        // Init
        errors   = 0;
        checked  = 0;
        out_idx  = 0;
        rst_n    = 0;
        valid_in = 0;
        real_in  = 0;
        imag_in  = 0;

        @(posedge clk);
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Feed inputs
        for (int i = 0; i < N_SAMPLES; i++) begin
            @(posedge clk);
            valid_in = 1;
            real_in  = in_real_data[i];
            imag_in  = in_imag_data[i];
        end

        @(posedge clk);
        valid_in = 0;
        repeat(10) @(posedge clk);

        // Summary
        $display("-------------------------------------------");
        $display("Checked : %0d samples", checked);
        $display("Errors  : %0d", errors);
        if (errors == 0)
            $display("RESULT  : PASS");
        else
            $display("RESULT  : FAIL (%0d mismatches)", errors);
        $display("===========================================");
        $finish;
    end

    // Output checker
    always @(posedge clk) begin
        if (valid_out) begin
            if (out_idx < N_SAMPLES) begin
                if (demod_out !== golden_data[out_idx]) begin
                    if (errors < 20)
                        $display("MISMATCH @%0d: got %0d, expected %0d",
                                 out_idx, demod_out, golden_data[out_idx]);
                    errors = errors + 1;
                end
                checked = checked + 1;
                out_idx = out_idx + 1;
            end
        end
    end

endmodule
