
`include "my_fft_pkg.sv"

module fft_stage import my_fft_pkg::*; #(
    parameter int STAGE_ID = 0,
    parameter int MULT_LATENCY = 3
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   valid_in,
    input  logic signed [INT_WIDTH-1:0] real_in,
    input  logic signed [INT_WIDTH-1:0] imag_in,
    input  logic signed [TWIDDLE_WIDTH-1:0] twiddle_real,
    input  logic signed [TWIDDLE_WIDTH-1:0] twiddle_imag,
    
    output logic                   valid_out,
    output logic signed [INT_WIDTH-1:0] real_out,
    output logic signed [INT_WIDTH-1:0] imag_out
);

    // DIT: delay = 2^STAGE_ID
    localparam int D = 1 << STAGE_ID;

    // Input delay line (shift register)
    logic signed [INT_WIDTH-1:0] shift_real [0:D-1];
    logic signed [INT_WIDTH-1:0] shift_imag [0:D-1];
    
    // Subtraction results FIFO
    logic signed [INT_WIDTH-1:0] sub_fifo_real [0:D-1];
    logic signed [INT_WIDTH-1:0] sub_fifo_imag [0:D-1];

    // Counters
    logic [$clog2(N)-1:0] cnt_in, cnt_in_c;
    logic [$clog2(N)-1:0] cnt_out, cnt_out_c;
    
    // Phase detection
    localparam int PHASE_BIT = (D == 1) ? 0 : $clog2(D);
    logic phase_in, phase_out;
    assign phase_in = cnt_in[PHASE_BIT];
    assign phase_out = cnt_out[PHASE_BIT];

    // Multiplier interface
    logic mult_v_in;
    logic signed [INT_WIDTH-1:0] mult_in_r, mult_in_i;
    logic mult_v_out;
    logic signed [INT_WIDTH-1:0] mult_out_r, mult_out_i;

    // Delay pipeline for shift_reg values (latency-match the multiplier)
    logic signed [INT_WIDTH-1:0] delay_pipe_r [0:MULT_LATENCY-1];
    logic signed [INT_WIDTH-1:0] delay_pipe_i [0:MULT_LATENCY-1];
    logic [MULT_LATENCY-1:0] delay_pipe_v;

    // Valid pipeline (total latency = D + MULT_LATENCY)
    logic [D + MULT_LATENCY - 1 : 0] valid_pipe;

    // Butterfly results (no /2 scaling!)
    logic signed [INT_WIDTH-1:0] bf_add_r, bf_add_i;
    logic signed [INT_WIDTH-1:0] bf_sub_r, bf_sub_i;

    complex_mult #(
        .DATA_WIDTH(INT_WIDTH),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
        .Q(Q)
    ) mult_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(mult_v_in),
        .a_real(mult_in_r), .a_imag(mult_in_i),
        .w_real(twiddle_real), .w_imag(twiddle_imag),
        .valid_out(mult_v_out),
        .out_real(mult_out_r), .out_imag(mult_out_i)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_in <= '0;
            cnt_out <= '0;
            valid_pipe <= '0;
            for (int i=0; i<D; i++) begin
                shift_real[i] <= '0; shift_imag[i] <= '0;
                sub_fifo_real[i] <= '0; sub_fifo_imag[i] <= '0;
            end
            for (int i=0; i<MULT_LATENCY; i++) begin
                delay_pipe_r[i] <= '0; delay_pipe_i[i] <= '0;
                delay_pipe_v[i] <= 1'b0;
            end
        end else begin
            cnt_in <= cnt_in_c;
            cnt_out <= cnt_out_c;
            valid_pipe <= {valid_pipe[D+MULT_LATENCY-2:0], valid_in};

            // Shift register: always push input
            if (valid_in) begin
                for (int i=D-1; i>0; i--) begin
                    shift_real[i] <= shift_real[i-1];
                    shift_imag[i] <= shift_imag[i-1];
                end
                shift_real[0] <= real_in;
                shift_imag[0] <= imag_in;
            end

            // Delay pipeline for the "top" operand (shift_reg output)
            for (int i=MULT_LATENCY-1; i>0; i--) begin
                delay_pipe_r[i] <= delay_pipe_r[i-1];
                delay_pipe_i[i] <= delay_pipe_i[i-1];
                delay_pipe_v[i] <= delay_pipe_v[i-1];
            end
            if (valid_in && phase_in == 1'b1) begin
                delay_pipe_r[0] <= shift_real[D-1];
                delay_pipe_i[0] <= shift_imag[D-1];
                delay_pipe_v[0] <= 1'b1;
            end else begin
                delay_pipe_v[0] <= 1'b0;
            end

            // Sub FIFO: store subtraction results when butterfly computes
            if (mult_v_out || (valid_out && phase_out == 1'b1)) begin
                for (int i=D-1; i>0; i--) begin
                    sub_fifo_real[i] <= sub_fifo_real[i-1];
                    sub_fifo_imag[i] <= sub_fifo_imag[i-1];
                end
                if (mult_v_out) begin
                    sub_fifo_real[0] <= bf_sub_r;
                    sub_fifo_imag[0] <= bf_sub_i;
                end
            end
        end
    end

    always_comb begin
        cnt_in_c = cnt_in;
        if (valid_in) cnt_in_c = cnt_in + 1;

        // DIT: multiply the CURRENT INPUT by twiddle during phase 1
        mult_v_in = 1'b0;
        mult_in_r = '0;
        mult_in_i = '0;
        if (valid_in && phase_in == 1'b1) begin
            mult_v_in = 1'b1;
            mult_in_r = real_in;
            mult_in_i = imag_in;
        end

        // Butterfly: delayed_value +/- twiddle*current (NO /2 scaling!)
        bf_add_r = delay_pipe_r[MULT_LATENCY-1] + mult_out_r;
        bf_add_i = delay_pipe_i[MULT_LATENCY-1] + mult_out_i;
        bf_sub_r = delay_pipe_r[MULT_LATENCY-1] - mult_out_r;
        bf_sub_i = delay_pipe_i[MULT_LATENCY-1] - mult_out_i;

        // Output control
        valid_out = valid_pipe[D + MULT_LATENCY - 1];
        cnt_out_c = cnt_out;
        if (valid_out) cnt_out_c = cnt_out + 1;

        if (valid_out) begin
            if (phase_out == 1'b0) begin
                // Phase 0: output addition results
                real_out = bf_add_r;
                imag_out = bf_add_i;
            end else begin
                // Phase 1: output subtraction results from FIFO
                real_out = sub_fifo_real[D-1];
                imag_out = sub_fifo_imag[D-1];
            end
        end else begin
            real_out = '0;
            imag_out = '0;
        end
    end

endmodule
