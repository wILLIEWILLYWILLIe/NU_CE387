module matmul_top 
#(  parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter MATRIX_SIZE = 8)
(
    input  logic                  clock,
    input  logic                  reset,
    input  logic                  start,
    output logic                  done,
    
    // Write A
    input  logic [DATA_WIDTH-1:0] a_wr_din,
    input  logic [ADDR_WIDTH-1:0] a_wr_addr,
    input  logic                  a_wr_en,
    
    // Write B
    input  logic [DATA_WIDTH-1:0] b_wr_din,
    input  logic [ADDR_WIDTH-1:0] b_wr_addr,
    input  logic                  b_wr_en,
    
    // Read C
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
    
    
    // BRAM A: 
    bram #(
        .BRAM_DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(ADDR_WIDTH)
    ) a_inst (
        .clock(clock),
        .rd_addr(a_addr),       
        .wr_addr(a_wr_addr),    
        .wr_en(a_wr_en),
        .dout(a_dout),
        .din(a_wr_din)
    );

    // BRAM B:
    bram #(
        .BRAM_DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(ADDR_WIDTH)
    ) b_inst (
        .clock(clock),
        .rd_addr(b_addr),       
        .wr_addr(b_wr_addr),    
        .wr_en(b_wr_en),
        .dout(b_dout),
        .din(b_wr_din)
    );

    // BRAM C:
    bram #(
        .BRAM_DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(ADDR_WIDTH)
    ) c_inst (
        .clock(clock),
        .rd_addr(c_rd_addr),    
        .wr_addr(c_addr),       
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
