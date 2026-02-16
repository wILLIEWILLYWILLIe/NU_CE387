
module udp_parser_top (
    input  logic        clock,
    input  logic        reset,
    
    // External Input Interface
    input  logic        din_wr_en,
    input  logic [7:0]  din,
    input  logic        din_sof,
    input  logic        din_eof,
    output logic        din_full,
    
    // External Output Interface
    input  logic        dout_rd_en,
    output logic [7:0]  dout,
    output logic        dout_sof,
    output logic        dout_eof,
    output logic        dout_empty
);

    // Interconnect Signals
    // Input FIFO -> Parser
    logic        p_in_rd_en;
    logic        p_in_empty;
    logic [7:0]  p_in_dout;
    logic        p_in_sof;
    logic        p_in_eof;
    
    // Parser -> Output FIFO
    logic        p_out_wr_en;
    logic        p_out_full;
    logic [7:0]  p_out_din;
    logic        p_out_sof;
    logic        p_out_eof;

    // Input FIFO
    fifo_ctrl #(
        .FIFO_DATA_WIDTH(8),
        .FIFO_BUFFER_SIZE(128)
    ) fifo_in (
        .reset(reset),
        
        .wr_clk(clock),
        .wr_en(din_wr_en),
        .din(din),
        .sof_in(din_sof),
        .eof_in(din_eof),
        .full(din_full),
        
        .rd_clk(clock),
        .rd_en(p_in_rd_en),
        .dout(p_in_dout),
        .sof_out(p_in_sof),
        .eof_out(p_in_eof),
        .empty(p_in_empty)
    );

    // UDP Parser Core
    udp_parser parser_inst (
        .clock(clock),
        .reset(reset),
        
        .in_rd_en(p_in_rd_en),
        .in_empty(p_in_empty),
        .in_dout(p_in_dout),
        .in_sof(p_in_sof),
        .in_eof(p_in_eof),
        
        .out_wr_en(p_out_wr_en),
        .out_full(p_out_full),
        .out_din(p_out_din),
        .out_sof(p_out_sof),
        .out_eof(p_out_eof)
    );

    // Output FIFO
    fifo_ctrl #(
        .FIFO_DATA_WIDTH(8),
        .FIFO_BUFFER_SIZE(128)
    ) fifo_out (
        .reset(reset),
        
        .wr_clk(clock),
        .wr_en(p_out_wr_en),
        .din(p_out_din),
        .sof_in(p_out_sof),
        .eof_in(p_out_eof),
        .full(p_out_full),
        
        .rd_clk(clock),
        .rd_en(dout_rd_en),
        .dout(dout),
        .sof_out(dout_sof),
        .eof_out(dout_eof),
        .empty(dout_empty)
    );

endmodule
