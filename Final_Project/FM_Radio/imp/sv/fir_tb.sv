// =============================================================
// fir_tb.sv — Testbench for fir.sv (Channel Filter, I path)
// -------------------------------------------------------------
// Reads: ../../test/in_I.txt   (input samples, decimal)
// Compares: ../../test/ch_I.txt (golden output, decimal)
// Checks bit-true match against C reference fir_cmplx_n()
// =============================================================

`timescale 1ns/1ps
import fir_pkg::*;

module fir_tb;

    // -------------------------------------------------------
    // Test txt
    // -------------------------------------------------------
    // localparam string IN_FILE   = "../../test/in_I.txt";
    // localparam string GOLDEN_FILE = "../../test/ch_I.txt";
    localparam string IN_FILE   = "../../test/in_Q.txt";
    localparam string GOLDEN_FILE = "../../test/ch_Q.txt";

    // -------------------------------------------------------
    // Parameters for Channel Filter (I path)
    // -------------------------------------------------------
    localparam int TAPS  = CHANNEL_TAPS;   // 20
    localparam int DECIM = 1;
    localparam int N_SAMPLES = 262144;
    localparam int CLK_PERIOD = 10;        // 100 MHz

    // -------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------
    logic                           clk, rst_n;
    logic                           valid_in;
    logic signed [WIDTH-1:0]        x_in;
    logic signed [CWIDTH-1:0]       dut_coeffs [0:TAPS-1];
    logic                           valid_out;
    logic signed [WIDTH-1:0]        y_out;
    

    // -------------------------------------------------------
    // DUT
    // -------------------------------------------------------
    fir #(
        .TAPS  (TAPS),
        .DECIM (DECIM),
        .WIDTH (WIDTH),
        .CWIDTH(CWIDTH),
        .BITS  (BITS)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .coeffs    (dut_coeffs),
        .valid_out (valid_out),
        .y_out     (y_out)
    );

    // -------------------------------------------------------
    // Clock
    // -------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------
    // Test vectors (loaded via $fscanf for decimal format)
    // -------------------------------------------------------
    logic signed [WIDTH-1:0] input_data  [0:N_SAMPLES-1];
    logic signed [WIDTH-1:0] golden_data [0:N_SAMPLES-1];

    integer errors;
    integer checked;
    integer out_idx;
    integer fd, code, idx;
    integer val;

    // -------------------------------------------------------
    // Main test
    // -------------------------------------------------------
    initial begin
        $display("=== FIR Channel Filter (I path) Testbench ===");

        // Load coefficients
        for (int i = 0; i < TAPS; i++)
            dut_coeffs[i] = CHANNEL_COEFFS[i];

        // Load input file
        fd = $fopen(IN_FILE, "r");
        if (fd == 0) begin $display("ERROR: cannot open in_I.txt"); $finish; end
        idx = 0;
        while (!$feof(fd) && idx < N_SAMPLES) begin
            code = $fscanf(fd, "%d\n", val);
            if (code == 1) begin input_data[idx] = val; idx = idx + 1; end
        end
        $fclose(fd);
        $display("  Loaded %0d input samples", idx);

        // Load golden file
        fd = $fopen(GOLDEN_FILE, "r");
        if (fd == 0) begin $display("ERROR: cannot open ch_I.txt"); $finish; end
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
        x_in     = 0;

        // Reset
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Feed inputs
        for (int i = 0; i < N_SAMPLES; i++) begin
            @(posedge clk);
            valid_in = 1;
            x_in     = input_data[i];
        end

        @(posedge clk);
        valid_in = 0;

        // Wait for last output
        repeat(TAPS + 5) @(posedge clk);

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

    // -------------------------------------------------------
    // Output checker (use always, NOT always_ff in testbench)
    // -------------------------------------------------------
    always @(posedge clk) begin
        if (valid_out) begin
            if (out_idx < N_SAMPLES) begin
                if (y_out !== golden_data[out_idx]) begin
                    if (errors < 20)
                        $display("MISMATCH @%0d: got %0d, expected %0d",
                                 out_idx, y_out, golden_data[out_idx]);
                    errors = errors + 1;
                end
                checked = checked + 1;
                out_idx = out_idx + 1;
            end
        end
    end

endmodule
