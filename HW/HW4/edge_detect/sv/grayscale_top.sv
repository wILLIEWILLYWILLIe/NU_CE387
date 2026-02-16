
module grayscale_top #(
    parameter WIDTH = 720,
    parameter HEIGHT = 540
) (
    input  logic        clock,
    input  logic        reset,
    input  logic        in_wr_en,
    input  logic [23:0] in_din,
    output logic        in_full,
    
    // Read Interface
    input  logic        out_rd_en_in, 
    output logic [7:0]  out_dout,
    output logic        out_empty
);

    // Internal Signals
    logic        fifo1_rd_en, fifo1_empty;
    logic [23:0] fifo1_dout;
    
    logic        gs_wr_en, gs_full;
    logic [7:0]  gs_out;
    
    logic        fifo2_full;

    // FIFO 1: Input -> Grayscale
    fifo #(
        .FIFO_DATA_WIDTH(24),
        .FIFO_BUFFER_SIZE(1024)
    ) fifo_in (
        .reset(reset),
        .wr_clk(clock),
        .wr_en(in_wr_en),
        .din(in_din),
        .full(in_full),
        .rd_clk(clock),
        .rd_en(fifo1_rd_en),
        .dout(fifo1_dout),
        .empty(fifo1_empty)
    );

    // Grayscale Module
    grayscale gs_inst (
        .clock(clock),
        .reset(reset),
        .in_rd_en(fifo1_rd_en),
        .in_empty(fifo1_empty),
        .in_dout(fifo1_dout),
        .out_wr_en(gs_wr_en),
        .out_full(fifo2_full),
        .out_din(gs_out)
    );

    // FIFO 2: Grayscale -> Output
    fifo #(
        .FIFO_DATA_WIDTH(8),
        .FIFO_BUFFER_SIZE(1024)
    ) fifo_out (
        .reset(reset),
        .wr_clk(clock),
        .wr_en(gs_wr_en),
        .din(gs_out),
        .full(fifo2_full),
        .rd_clk(clock),
        .rd_en(out_rd_en_in),
        .dout(out_dout),
        .empty(out_empty)
    );

endmodule
