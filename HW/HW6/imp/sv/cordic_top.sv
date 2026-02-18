
module cordic_top (
    input  logic        clock,
    input  logic        reset,
    
    input  logic        valid_in,
    input  logic signed [31:0] rad_in,
    output logic        full_out, // FIFO Full

    output logic        valid_out,
    output logic signed [15:0] sin_out,
    output logic signed [15:0] cos_out
);

    logic fifo_empty;
    logic fifo_full;
    logic [31:0] fifo_dout;
    logic fifo_rd_en;
    logic cordic_ready;

    // 16-element FIFO (Depth=16, Width=32)
    fifo #(
        .FIFO_DATA_WIDTH(32),
        .FIFO_BUFFER_SIZE(16)
    ) input_fifo (
        .reset(reset),
        .wr_clk(clock),
        .wr_en(valid_in && !fifo_full),
        .din(rad_in),
        .full(fifo_full),
        .rd_clk(clock),
        .rd_en(fifo_rd_en),
        .dout(fifo_dout),
        .empty(fifo_empty)
    );

    // Read from FIFO when CORDIC is ready and FIFO is not empty
    assign fifo_rd_en = cordic_ready && !fifo_empty;
    assign full_out = fifo_full;

    // CORDIC Instance
    cordic cordic_inst (
        .clock(clock),
        .reset(reset),
        .valid_in(fifo_rd_en),
        .rad_in(fifo_dout),
        .valid_out(valid_out),
        .sin_out(sin_out),
        .cos_out(cos_out),
        .ready(cordic_ready)
    );

endmodule
