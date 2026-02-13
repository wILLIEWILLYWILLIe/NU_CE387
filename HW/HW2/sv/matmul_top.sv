module matmul_top 
#(  parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter MATRIX_SIZE = 8)
(
    input  logic                  clock,
    input  logic                  reset,
    input  logic                  start,
    output logic                  done,
    
    // External Interface to Write A
    input  logic [DATA_WIDTH-1:0] a_wr_din,
    input  logic [ADDR_WIDTH-1:0] a_wr_addr,
    input  logic                  a_wr_en,
    
    // External Interface to Write B
    input  logic [DATA_WIDTH-1:0] b_wr_din,
    input  logic [ADDR_WIDTH-1:0] b_wr_addr,
    input  logic                  b_wr_en,
    
    // External Interface to Read C
    output logic [DATA_WIDTH-1:0] c_rd_dout,
    input  logic [ADDR_WIDTH-1:0] c_rd_addr
);

    // Internal signals connecting Matmul to BRAMs
    logic [DATA_WIDTH-1:0] a_dout;
    logic [ADDR_WIDTH-1:0] a_addr; // Address from Matmul
    
    logic [DATA_WIDTH-1:0] b_dout;
    logic [ADDR_WIDTH-1:0] b_addr; // Address from Matmul
    
    logic [DATA_WIDTH-1:0] c_din;
    logic [ADDR_WIDTH-1:0] c_addr; // Address from Matmul
    logic                  c_wr_en;
    
    // Muxing logic for BRAM addresses (TB access vs Matmul access)
    // Note: In this simple design, we assume TB accesses happen when Matmul is IDLE/DONE.
    // Ideally we might want a mux, but BRAM usually has one read/write port logic or dual port.
    // Our BRAM model is simple: 1 read port, 1 write port.
    
    // BRAM A: 
    // Matmul reads from it (rd_addr connected to Matmul)
    // TB writes to it (wr_addr connected to TB inputs)
    bram #(
        .BRAM_DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(ADDR_WIDTH)
    ) a_inst (
        .clock(clock),
        .rd_addr(a_addr),       // Matmul reads
        .wr_addr(a_wr_addr),    // TB writes
        .wr_en(a_wr_en),
        .dout(a_dout),
        .din(a_wr_din)
    );

    // BRAM B:
    // Matmul reads from it
    // TB writes to it
    bram #(
        .BRAM_DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(ADDR_WIDTH)
    ) b_inst (
        .clock(clock),
        .rd_addr(b_addr),       // Matmul reads
        .wr_addr(b_wr_addr),    // TB writes
        .wr_en(b_wr_en),
        .dout(b_dout),
        .din(b_wr_din)
    );

    // BRAM C:
    // Matmul writes to it (wr_addr, din, wr_en from Matmul)
    // TB reads from it (rd_addr from TB)
    bram #(
        .BRAM_DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(ADDR_WIDTH)
    ) c_inst (
        .clock(clock),
        .rd_addr(c_rd_addr),    // TB reads
        .wr_addr(c_addr),       // Matmul writes
        .wr_en(c_wr_en),
        .dout(c_rd_dout),
        .din(c_din)
    );

    matmul #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) matmul_inst (
        .clock(clock),
        .reset(reset),
        .start(start),
        .done(done),
        .a_dout(a_dout),
        .a_addr(a_addr),
        .b_dout(b_dout),
        .b_addr(b_addr),
        .c_din(c_din),
        .c_addr(c_addr),
        .c_wr_en(c_wr_en)
    );

endmodule
