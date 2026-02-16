
module fifo_ctrl #(
    parameter FIFO_DATA_WIDTH = 8,
    parameter FIFO_BUFFER_SIZE = 1024
) (
    input  logic reset,
    input  logic wr_clk,
    input  logic wr_en,
    input  logic [FIFO_DATA_WIDTH-1:0] din,
    input  logic sof_in,
    input  logic eof_in,
    output logic full,
    
    input  logic rd_clk,
    input  logic rd_en,
    output logic [FIFO_DATA_WIDTH-1:0] dout,
    output logic sof_out,
    output logic eof_out,
    output logic empty
);

    logic full_data, full_ctrl;
    logic empty_data, empty_ctrl;
    
    // Data FIFO
    fifo #(
        .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
        .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) fifo_data (
        .reset(reset),
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .din(din),
        .full(full_data),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .dout(dout),
        .empty(empty_data)
    );

    // Control FIFO (Stores {sof, eof})
    fifo #(
        .FIFO_DATA_WIDTH(2), // 1 bit for SOF, 1 bit for EOF
        .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) fifo_control (
        .reset(reset),
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .din({sof_in, eof_in}),
        .full(full_ctrl),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .dout({sof_out, eof_out}),
        .empty(empty_ctrl)
    );

    // Aggregate full/empty signals
    // It's full if either is full, empty if either is empty (though they should track)
    assign full = full_data | full_ctrl;
    assign empty = empty_data | empty_ctrl;

endmodule
