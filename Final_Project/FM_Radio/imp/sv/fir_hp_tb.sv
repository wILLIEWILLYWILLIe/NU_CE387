// =============================================================
// fir_hp_tb.sv — FIR HP (32-tap, decim=1)
// pilot_sq.txt → pilot_38k.txt
// =============================================================

`timescale 1ns/1ps
import fir_pkg::*;

module fir_hp_tb;

    localparam string IN_FILE     = "../../test/pilot_sq.txt";
    localparam string GOLDEN_FILE = "../../test/pilot_38k.txt";

    localparam int TAPS  = HP_TAPS;
    localparam int DECIM = 1;
    localparam int N_IN  = 262144;
    localparam int N_OUT = N_IN / DECIM;
    localparam int CLK_PERIOD = 10;

    logic                           clk, rst_n, valid_in;
    logic signed [WIDTH-1:0]        x_in;
    logic signed [CWIDTH-1:0]       coeffs [0:TAPS-1];
    logic                           valid_out;
    logic signed [WIDTH-1:0]        y_out;

    fir #(.TAPS(TAPS),.DECIM(DECIM),.WIDTH(WIDTH),.CWIDTH(CWIDTH),.BITS(BITS)) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    logic signed [WIDTH-1:0] input_data  [0:N_IN-1];
    logic signed [WIDTH-1:0] golden_data [0:N_OUT-1];
    integer errors, checked, out_idx, fd, code, idx, val;

    initial begin
        $display("=== FIR HP (32-tap, decim=1) Testbench ===");
        for (int i = 0; i < TAPS; i++) coeffs[i] = HP_COEFFS[i];

        fd = $fopen(IN_FILE, "r"); if (fd==0) begin $display("ERROR: %s", IN_FILE); $finish; end
        idx = 0; while (!$feof(fd) && idx < N_IN) begin code = $fscanf(fd, "%d\n", val); if (code==1) begin input_data[idx]=val; idx=idx+1; end end
        $fclose(fd); $display("  Loaded %0d input samples", idx);

        fd = $fopen(GOLDEN_FILE, "r"); if (fd==0) begin $display("ERROR: %s", GOLDEN_FILE); $finish; end
        idx = 0; while (!$feof(fd) && idx < N_OUT) begin code = $fscanf(fd, "%d\n", val); if (code==1) begin golden_data[idx]=val; idx=idx+1; end end
        $fclose(fd); $display("  Loaded %0d golden samples", idx);

        errors=0; checked=0; out_idx=0; rst_n=0; valid_in=0; x_in=0;
        @(posedge clk); @(posedge clk); rst_n=1; @(posedge clk);
        for (int i=0; i<N_IN; i++) begin @(posedge clk); valid_in=1; x_in=input_data[i]; end
        @(posedge clk); valid_in=0; repeat(TAPS+5) @(posedge clk);

        $display("-------------------------------------------");
        $display("Checked : %0d / %0d", checked, N_OUT);
        $display("Errors  : %0d", errors);
        if (errors==0) $display("RESULT  : PASS"); else $display("RESULT  : FAIL (%0d)", errors);
        $display("==========================================="); $finish;
    end

    always @(posedge clk) begin
        if (valid_out && out_idx < N_OUT) begin
            if (y_out !== golden_data[out_idx]) begin
                if (errors < 10) $display("MISMATCH @%0d: got %0d, expected %0d", out_idx, y_out, golden_data[out_idx]);
                errors = errors + 1;
            end
            checked = checked + 1; out_idx = out_idx + 1;
        end
    end

endmodule
