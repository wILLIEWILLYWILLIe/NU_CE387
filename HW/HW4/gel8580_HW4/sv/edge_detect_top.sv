
module edge_detect_top #(
    parameter WIDTH = 720,
    parameter HEIGHT = 540
) (
    input  logic        clock,
    input  logic        reset,
    input  logic        in_wr_en,
    input  logic [23:0] in_din,
    output logic        in_full,
    output logic        out_rd_en, // Assuming top provides read interface for output? 
    // Usually top writes to output FIFO, and TB reads from it.
    // Let's expose the output FIFO read side.
    input  logic        out_rd_en_in, // Input from TB to read output
    output logic [7:0]  out_dout,
    output logic        out_empty
);

    // Internal Signals
    logic        fifo1_rd_en, fifo1_empty, fifo1_full;
    logic [23:0] fifo1_dout;
    
    logic        gs_rd_en, gs_wr_en; // Logic names might overlap
    logic [7:0]  gs_out;
    
    logic        fifo2_rd_en, fifo2_empty, fifo2_full, fifo2_wr_en;
    logic [7:0]  fifo2_dout, fifo2_din;
    
    logic        sob_wr_en;
    logic [7:0]  sob_out;
    
    logic        fifo3_full;

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
        .out_wr_en(fifo2_wr_en),
        .out_full(fifo2_full),
        .out_din(fifo2_din)
    );

    // FIFO 2: Grayscale -> Sobel
    fifo #(
        .FIFO_DATA_WIDTH(8),
        .FIFO_BUFFER_SIZE(1024)
    ) fifo_gs_sob (
        .reset(reset),
        .wr_clk(clock),
        .wr_en(fifo2_wr_en),
        .din(fifo2_din),
        .full(fifo2_full),
        .rd_clk(clock),
        .rd_en(fifo2_rd_en),
        .dout(fifo2_dout),
        .empty(fifo2_empty)
    );

    // Sobel Module
    sobel #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT)
    ) sob_inst (
        .clock(clock),
        .reset(reset),
        .in_rd_en(fifo2_rd_en),
        .in_empty(fifo2_empty),
        .in_dout(fifo2_dout),
        .out_wr_en(sob_wr_en),
        .out_full(fifo3_full),
        .out_din(sob_out)
    );

    // FIFO 3: Sobel -> Output
    fifo #(
        .FIFO_DATA_WIDTH(8),
        .FIFO_BUFFER_SIZE(1024)
    ) fifo_out (
        .reset(reset),
        .wr_clk(clock),
        .wr_en(sob_wr_en),
        .din(sob_out),
        .full(fifo3_full),
        .rd_clk(clock),
        .rd_en(out_rd_en_in),
        .dout(out_dout),
        .empty(out_empty)
    );

endmodule
