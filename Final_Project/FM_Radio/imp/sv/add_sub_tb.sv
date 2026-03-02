// =============================================================
// add_sub_tb.sv — Testbench for add_sub.sv
// Tests ADD (left_raw = lpr + lmr) then SUB (right_raw = lpr - lmr)
// =============================================================

`timescale 1ns/1ps
import fir_pkg::*;

module add_sub_tb;

    localparam string IN_X_FILE  = "../../test/audio_lpr.txt";
    localparam string IN_Y_FILE  = "../../test/audio_lmr.txt";
    localparam string GOLD_ADD   = "../../test/left_raw.txt";
    localparam string GOLD_SUB   = "../../test/right_raw.txt";
    localparam int N_SAMPLES  = 32768;
    localparam int CLK_PERIOD = 10;

    logic                           clk, rst_n, valid_in, do_sub;
    logic signed [WIDTH-1:0]        x_in, y_in;
    logic                           valid_out;
    logic signed [WIDTH-1:0]        z_out;

    add_sub dut (.clk(clk),.rst_n(rst_n),.valid_in(valid_in),.do_sub(do_sub),
                 .x_in(x_in),.y_in(y_in),.valid_out(valid_out),.z_out(z_out));

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    logic signed [WIDTH-1:0] x_data    [0:N_SAMPLES-1];
    logic signed [WIDTH-1:0] y_data    [0:N_SAMPLES-1];
    logic signed [WIDTH-1:0] gold_add  [0:N_SAMPLES-1];
    logic signed [WIDTH-1:0] gold_sub  [0:N_SAMPLES-1];
    integer errors, checked, out_idx, fd, code, idx, val;

    // Track which test is running (0=ADD, 1=SUB)
    integer test_phase;

    initial begin
        // --- Load all files ---
        fd = $fopen(IN_X_FILE,"r"); if(fd==0) begin $display("ERROR: %s", IN_X_FILE); $finish; end
        idx=0; while(!$feof(fd)&&idx<N_SAMPLES) begin code=$fscanf(fd,"%d\n",val); if(code==1) begin x_data[idx]=val; idx=idx+1; end end
        $fclose(fd); $display("  Loaded %0d audio_lpr samples", idx);

        fd = $fopen(IN_Y_FILE,"r"); if(fd==0) begin $display("ERROR: %s", IN_Y_FILE); $finish; end
        idx=0; while(!$feof(fd)&&idx<N_SAMPLES) begin code=$fscanf(fd,"%d\n",val); if(code==1) begin y_data[idx]=val; idx=idx+1; end end
        $fclose(fd); $display("  Loaded %0d audio_lmr samples", idx);

        fd = $fopen(GOLD_ADD,"r"); if(fd==0) begin $display("ERROR: %s", GOLD_ADD); $finish; end
        idx=0; while(!$feof(fd)&&idx<N_SAMPLES) begin code=$fscanf(fd,"%d\n",val); if(code==1) begin gold_add[idx]=val; idx=idx+1; end end
        $fclose(fd);

        fd = $fopen(GOLD_SUB,"r"); if(fd==0) begin $display("ERROR: %s", GOLD_SUB); $finish; end
        idx=0; while(!$feof(fd)&&idx<N_SAMPLES) begin code=$fscanf(fd,"%d\n",val); if(code==1) begin gold_sub[idx]=val; idx=idx+1; end end
        $fclose(fd);

        // === Test 1: ADD (left_raw = lpr + lmr) ===
        $display("--- ADD (left_raw = audio_lpr + audio_lmr) ---");
        errors=0; checked=0; out_idx=0; test_phase=0;
        rst_n=0; valid_in=0; x_in=0; y_in=0; do_sub=0;
        @(posedge clk); @(posedge clk); rst_n=1; @(posedge clk);
        for (int i=0; i<N_SAMPLES; i++) begin
            @(posedge clk); valid_in=1; x_in=x_data[i]; y_in=y_data[i];
        end
        @(posedge clk); valid_in=0; repeat(5) @(posedge clk);
        $display("ADD: Checked=%0d Errors=%0d %s", checked, errors, (errors==0)?"PASS":"FAIL");

        // === Test 2: SUB (right_raw = lpr - lmr) ===
        $display("--- SUB (right_raw = audio_lpr - audio_lmr) ---");
        errors=0; checked=0; out_idx=0; test_phase=1;
        rst_n=0; valid_in=0; x_in=0; y_in=0; do_sub=1;
        @(posedge clk); @(posedge clk); rst_n=1; @(posedge clk);
        for (int i=0; i<N_SAMPLES; i++) begin
            @(posedge clk); valid_in=1; x_in=x_data[i]; y_in=y_data[i];
        end
        @(posedge clk); valid_in=0; repeat(5) @(posedge clk);
        $display("SUB: Checked=%0d Errors=%0d %s", checked, errors, (errors==0)?"PASS":"FAIL");

        $display("==========================================="); $finish;
    end

    always @(posedge clk) begin
        if (valid_out && out_idx < N_SAMPLES) begin
            if (test_phase == 0) begin
                if (z_out !== gold_add[out_idx]) begin
                    if (errors < 10) $display("ADD MISMATCH @%0d: got %0d, expected %0d", out_idx, z_out, gold_add[out_idx]);
                    errors = errors + 1;
                end
            end else begin
                if (z_out !== gold_sub[out_idx]) begin
                    if (errors < 10) $display("SUB MISMATCH @%0d: got %0d, expected %0d", out_idx, z_out, gold_sub[out_idx]);
                    errors = errors + 1;
                end
            end
            checked = checked + 1;
            out_idx  = out_idx + 1;
        end
    end

endmodule
