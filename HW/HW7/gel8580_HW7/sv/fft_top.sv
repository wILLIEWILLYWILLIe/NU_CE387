

module fft_top import my_fft_pkg::*; (
    input  logic                   clk,
    input  logic                   rst_n,
    
    // Input FIFO Interface
    input  logic                   wr_en,
    input  logic signed [DATA_WIDTH-1:0] real_in,
    input  logic signed [DATA_WIDTH-1:0] imag_in,
    output logic                   in_full,
    
    // Output FIFO Interface
    input  logic                   rd_en,
    output logic signed [DATA_WIDTH-1:0] real_out,
    output logic signed [DATA_WIDTH-1:0] imag_out,
    output logic                   out_empty
);

    // Internal FIFO signals
    logic signed [DATA_WIDTH-1:0] in_real_dout, in_imag_dout;
    logic in_fifo_empty;
    logic in_fifo_rd_en;

    // Input FIFOs
    fifo #(.FIFO_DATA_WIDTH(DATA_WIDTH), .FIFO_BUFFER_SIZE(32)) fifo_in_real (
        .reset(!rst_n), .wr_clk(clk), .wr_en(wr_en), .din(real_in), .full(in_full),
        .rd_clk(clk), .rd_en(in_fifo_rd_en), .dout(in_real_dout), .empty(in_fifo_empty)
    );
    fifo #(.FIFO_DATA_WIDTH(DATA_WIDTH), .FIFO_BUFFER_SIZE(32)) fifo_in_imag (
        .reset(!rst_n), .wr_clk(clk), .wr_en(wr_en), .din(imag_in), .full(),
        .rd_clk(clk), .rd_en(in_fifo_rd_en), .dout(in_imag_dout), .empty()
    );

    assign in_fifo_rd_en = !in_fifo_empty;

    // ---- Bit-Reversal at INPUT (DIT: reorder before FFT stages) ----
    logic br_valid_out;
    logic signed [DATA_WIDTH-1:0] br_real_out, br_imag_out;
    logic br_ready_in;

    fft_bit_reversal #(
        .N(N), .DATA_WIDTH(DATA_WIDTH)
    ) bit_rev_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(in_fifo_rd_en),
        .real_in(in_real_dout),
        .imag_in(in_imag_dout),
        .valid_out(br_valid_out),
        .real_out(br_real_out),
        .imag_out(br_imag_out),
        .ready_in(br_ready_in)
    );

    always @(posedge clk) if (DEBUG && br_valid_out) $display("[TOP] BitRev Input to Stage 0: %h + j%h", br_real_out, br_imag_out);

    // ---- FFT Stages (DIT: stage 0 has D=1, stage 3 has D=8) ----
    logic stage_valid [0:NUM_STAGES];
    logic signed [INT_WIDTH-1:0] stage_real [0:NUM_STAGES];
    logic signed [INT_WIDTH-1:0] stage_imag [0:NUM_STAGES];

    // Stage 0 input: sign-extend bit-reversed 16-bit data to INT_WIDTH
    assign stage_valid[0] = br_valid_out;
    assign stage_real[0]  = INT_WIDTH'(br_real_out);
    assign stage_imag[0]  = INT_WIDTH'(br_imag_out);

    generate
        for (genvar s = 0; s < NUM_STAGES; s++) begin : gen_stages
            logic signed [TWIDDLE_WIDTH-1:0] tw_real, tw_imag;
            logic [$clog2(N)-1:0] stage_cnt;
            
            // Counter for twiddle indexing
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) stage_cnt <= '0;
                else if (stage_valid[s]) stage_cnt <= stage_cnt + 1;
            end

            // DIT twiddle factor selection
            // Stage s: D = 2^s, step = 2^(s+1)
            // Twiddle index = (j within group) * (N / step) = (cnt mod D) * (N / 2^(s+1))
            localparam int D_val = 1 << s;
            localparam int P_BIT = (D_val == 1) ? 0 : $clog2(D_val);
            localparam int TW_STRIDE = N / (1 << (s + 1)); // N/step
            logic stage_phase;
            assign stage_phase = stage_cnt[P_BIT];

            always_comb begin
                int idx;
                if (stage_phase == 1'b1) begin
                    idx = (stage_cnt & (D_val - 1)) * TW_STRIDE;
                    tw_real = TWIDDLES[idx].real_val;
                    tw_imag = TWIDDLES[idx].imag_val;
                end else begin
                    tw_real = 16'sh4000; // W^0 = 1.0
                    tw_imag = 16'sh0000;
                end
            end

            fft_stage #(
                .STAGE_ID(s),
                .MULT_LATENCY(4)
            ) stage_inst (
                .clk(clk), .rst_n(rst_n),
                .valid_in(stage_valid[s]),
                .real_in(stage_real[s]),
                .imag_in(stage_imag[s]),
                .twiddle_real(tw_real),
                .twiddle_imag(tw_imag),
                .valid_out(stage_valid[s+1]),
                .real_out(stage_real[s+1]),
                .imag_out(stage_imag[s+1])
            );
        end
    endgenerate

    always @(posedge clk) if (DEBUG && stage_valid[NUM_STAGES]) $display("[TOP] Stage %0d Output: %h + j%h", NUM_STAGES, stage_real[NUM_STAGES], stage_imag[NUM_STAGES]);

    // ---- Output: truncate INT_WIDTH back to DATA_WIDTH ----
    logic signed [DATA_WIDTH-1:0] final_real, final_imag;
    assign final_real = stage_real[NUM_STAGES][DATA_WIDTH-1:0];
    assign final_imag = stage_imag[NUM_STAGES][DATA_WIDTH-1:0];

    // Output FIFOs
    fifo #(.FIFO_DATA_WIDTH(DATA_WIDTH), .FIFO_BUFFER_SIZE(32)) fifo_out_real (
        .reset(!rst_n), .wr_clk(clk), .wr_en(stage_valid[NUM_STAGES]), .din(final_real), .full(),
        .rd_clk(clk), .rd_en(rd_en), .dout(real_out), .empty(out_empty)
    );
    fifo #(.FIFO_DATA_WIDTH(DATA_WIDTH), .FIFO_BUFFER_SIZE(32)) fifo_out_imag (
        .reset(!rst_n), .wr_clk(clk), .wr_en(stage_valid[NUM_STAGES]), .din(final_imag), .full(),
        .rd_clk(clk), .rd_en(rd_en), .dout(imag_out), .empty()
    );

endmodule
