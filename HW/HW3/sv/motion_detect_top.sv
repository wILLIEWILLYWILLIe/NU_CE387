
module motion_detect_top #(
    parameter WIDTH = 720,
    parameter HEIGHT = 540,
    parameter FIFO_DEPTH = 32
) (
    input  logic        clock,
    input  logic        reset,
    
    // Base Image Input
    output logic        base_full,
    input  logic        base_wr_en,
    input  logic [23:0] base_din,
    
    // Pedestrian Image Input
    output logic        img_full,
    input  logic        img_wr_en,
    input  logic [23:0] img_din,
    
    // Output Image
    output logic        out_empty,
    input  logic        out_rd_en,
    output logic [23:0] out_dout
);

    // Signals for Base Path
    logic [23:0] base_fifo_dout;
    logic        base_fifo_empty, base_fifo_rd_en;
    
    logic [7:0]  base_gs_din, base_gs_dout;
    logic        base_gs_wr_en, base_gs_full;
    logic        base_gs_empty, base_gs_rd_en;

    // Signals for Image Path (Split into two)
    // 1. To Grayscale
    logic [23:0] img_gs_fifo_dout;
    logic        img_gs_fifo_empty, img_gs_fifo_rd_en;
    logic        img_gs_fifo_full;
    
    // 2. To Highlight (Original)
    logic [23:0] img_hl_fifo_dout;
    logic        img_hl_fifo_empty, img_hl_fifo_rd_en;
    logic        img_hl_fifo_full;

    // Output of Grayscale(Image)
    logic [7:0]  img_gs_din, img_gs_dout;
    logic        img_gs_wr_en, img_gs_full;
    logic        img_gs_empty, img_gs_rd_en;

    // Mask Path
    logic [7:0]  mask_din, mask_dout;
    logic        mask_wr_en, mask_full;
    logic        mask_empty, mask_rd_en;
    
    // Final Output Path
    logic [23:0] final_din;
    logic        final_wr_en, final_full;

    // -----------------------------------------------------------
    // Input FIFOs
    // -----------------------------------------------------------
    
    // Base FIFO
    fifo #(.FIFO_BUFFER_SIZE(FIFO_DEPTH), .FIFO_DATA_WIDTH(24)) fifo_base_in (
        .reset(reset), .wr_clk(clock), .rd_clk(clock),
        .wr_en(base_wr_en), .din(base_din), .full(base_full),
        .rd_en(base_fifo_rd_en), .dout(base_fifo_dout), .empty(base_fifo_empty)
    );

    // Image Input Split Logic
    // We write to both FIFOs when img_wr_en is asserted.
    // We only report FULL if EITHER is full (conservative).
    assign img_full = img_gs_fifo_full | img_hl_fifo_full;
    
    // Image FIFO for Grayscale path
    fifo #(.FIFO_BUFFER_SIZE(FIFO_DEPTH), .FIFO_DATA_WIDTH(24)) fifo_img_to_gs (
        .reset(reset), .wr_clk(clock), .rd_clk(clock),
        .wr_en(img_wr_en & !img_full), .din(img_din), .full(img_gs_fifo_full), // Guarded write? usually top handles it
        .rd_en(img_gs_fifo_rd_en), .dout(img_gs_fifo_dout), .empty(img_gs_fifo_empty)
    );

    // Image FIFO for Highlight path
    // Increase depth to account for latency of grayscale + subtract path
    // Latency est: Grayscale (2) + FIFO + Sub (2) + FIFO ~ 6-10 cycles. 32 is plenty.
    fifo #(.FIFO_BUFFER_SIZE(FIFO_DEPTH), .FIFO_DATA_WIDTH(24)) fifo_img_to_hl (
        .reset(reset), .wr_clk(clock), .rd_clk(clock),
        .wr_en(img_wr_en & !img_full), .din(img_din), .full(img_hl_fifo_full),
        .rd_en(img_hl_fifo_rd_en), .dout(img_hl_fifo_dout), .empty(img_hl_fifo_empty)
    );

    // -----------------------------------------------------------
    // Grayscale Modules
    // -----------------------------------------------------------

    // Base Grayscale
    grayscale gs_base_inst (
        .clock(clock), .reset(reset),
        .in_rd_en(base_fifo_rd_en), .in_empty(base_fifo_empty), .in_dout(base_fifo_dout),
        .out_wr_en(base_gs_wr_en), .out_full(base_gs_full), .out_din(base_gs_din)
    );

    fifo #(.FIFO_BUFFER_SIZE(FIFO_DEPTH), .FIFO_DATA_WIDTH(8)) fifo_base_gs (
        .reset(reset), .wr_clk(clock), .rd_clk(clock),
        .wr_en(base_gs_wr_en), .din(base_gs_din), .full(base_gs_full),
        .rd_en(base_gs_rd_en), .dout(base_gs_dout), .empty(base_gs_empty)
    );

    // Image Grayscale
    grayscale gs_img_inst (
        .clock(clock), .reset(reset),
        .in_rd_en(img_gs_fifo_rd_en), .in_empty(img_gs_fifo_empty), .in_dout(img_gs_fifo_dout),
        .out_wr_en(img_gs_wr_en), .out_full(img_gs_full), .out_din(img_gs_din)
    );

    fifo #(.FIFO_BUFFER_SIZE(FIFO_DEPTH), .FIFO_DATA_WIDTH(8)) fifo_img_gs (
        .reset(reset), .wr_clk(clock), .rd_clk(clock),
        .wr_en(img_gs_wr_en), .din(img_gs_din), .full(img_gs_full),
        .rd_en(img_gs_rd_en), .dout(img_gs_dout), .empty(img_gs_empty)
    );

    // -----------------------------------------------------------
    // Background Subtraction
    // -----------------------------------------------------------

    background_sub bg_sub_inst (
        .clock(clock), .reset(reset),
        .a_rd_en(base_gs_rd_en), .a_empty(base_gs_empty), .a_dout(base_gs_dout),
        .b_rd_en(img_gs_rd_en), .b_empty(img_gs_empty), .b_dout(img_gs_dout),
        .out_wr_en(mask_wr_en), .out_full(mask_full), .out_din(mask_din)
    );

    fifo #(.FIFO_BUFFER_SIZE(FIFO_DEPTH), .FIFO_DATA_WIDTH(8)) fifo_mask (
        .reset(reset), .wr_clk(clock), .rd_clk(clock),
        .wr_en(mask_wr_en), .din(mask_din), .full(mask_full),
        .rd_en(mask_rd_en), .dout(mask_dout), .empty(mask_empty)
    );

    // -----------------------------------------------------------
    // Highlight
    // -----------------------------------------------------------

    highlight highlight_inst (
        .clock(clock), .reset(reset),
        .img_rd_en(img_hl_fifo_rd_en), .img_empty(img_hl_fifo_empty), .img_dout(img_hl_fifo_dout),
        .mask_rd_en(mask_rd_en), .mask_empty(mask_empty), .mask_dout(mask_dout),
        .out_wr_en(final_wr_en), .out_full(final_full), .out_din(final_din)
    );

    fifo #(.FIFO_BUFFER_SIZE(FIFO_DEPTH), .FIFO_DATA_WIDTH(24)) fifo_out (
        .reset(reset), .wr_clk(clock), .rd_clk(clock),
        .wr_en(final_wr_en), .din(final_din), .full(final_full),
        .rd_en(out_rd_en), .dout(out_dout), .empty(out_empty)
    );

endmodule
