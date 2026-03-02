// =============================================================
// multiply_tb.sv — Testbench for multiply.sv (Pilot squaring)
// Reads: bp_pilot.txt × bp_pilot.txt → Compares: pilot_sq.txt
// =============================================================

`timescale 1ns/1ps
import fir_pkg::*;

module multiply_tb;

    // -------------------------------------------------------
    // Test txt
    // -------------------------------------------------------
    localparam string IN_FILE   = "../../test/bp_pilot.txt";
    localparam string GOLDEN_FILE = "../../test/pilot_sq.txt";

    localparam int N_SAMPLES  = 262144;
    localparam int CLK_PERIOD = 10;

    logic                           clk, rst_n;
    logic                           valid_in;
    logic signed [WIDTH-1:0]        x_in, y_in;
    logic                           valid_out;
    logic signed [WIDTH-1:0]        out;

    multiply dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .x_in(x_in), .y_in(y_in), .valid_out(valid_out), .out(out)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    logic signed [WIDTH-1:0] input_data  [0:N_SAMPLES-1];
    logic signed [WIDTH-1:0] golden_data [0:N_SAMPLES-1];

    integer errors, checked, out_idx;
    integer fd, code, idx, val;

    initial begin
        $display("=== Multiply (Pilot Squaring) Testbench ===");

        // Load bp_pilot.txt (self-multiply)
        fd = $fopen(IN_FILE, "r");
        if (fd == 0) begin $display("ERROR: cannot open bp_pilot.txt"); $finish; end
        idx = 0;
        while (!$feof(fd) && idx < N_SAMPLES) begin
            code = $fscanf(fd, "%d\n", val);
            if (code == 1) begin input_data[idx] = val; idx = idx + 1; end
        end
        $fclose(fd);
        $display("  Loaded %0d input samples", idx);

        // Load pilot_sq.txt (golden)
        fd = $fopen(GOLDEN_FILE, "r");
        if (fd == 0) begin $display("ERROR: cannot open pilot_sq.txt"); $finish; end
        idx = 0;
        while (!$feof(fd) && idx < N_SAMPLES) begin
            code = $fscanf(fd, "%d\n", val);
            if (code == 1) begin golden_data[idx] = val; idx = idx + 1; end
        end
        $fclose(fd);
        $display("  Loaded %0d golden samples", idx);

        errors = 0; checked = 0; out_idx = 0;
        rst_n = 0; valid_in = 0; x_in = 0; y_in = 0;
        @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);

        for (int i = 0; i < N_SAMPLES; i++) begin
            @(posedge clk);
            valid_in = 1;
            x_in = input_data[i];
            y_in = input_data[i];  // self-multiply (squaring)
        end
        @(posedge clk); valid_in = 0;
        repeat(5) @(posedge clk);

        $display("-------------------------------------------");
        $display("Checked : %0d samples", checked);
        $display("Errors  : %0d", errors);
        if (errors == 0) $display("RESULT  : PASS");
        else             $display("RESULT  : FAIL (%0d mismatches)", errors);
        $display("===========================================");
        $finish;
    end

    always @(posedge clk) begin
        if (valid_out && out_idx < N_SAMPLES) begin
            if (out !== golden_data[out_idx]) begin
                if (errors < 20)
                    $display("MISMATCH @%0d: got %0d, expected %0d", out_idx, out, golden_data[out_idx]);
                errors = errors + 1;
            end
            checked = checked + 1;
            out_idx = out_idx + 1;
        end
    end

endmodule
