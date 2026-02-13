
module highlight (
    input  logic        clock,
    input  logic        reset,
    
    // Input Image (Original RGB)
    output logic        img_rd_en,
    input  logic        img_empty,
    input  logic [23:0] img_dout,
    
    // Input Mask
    output logic        mask_rd_en,
    input  logic        mask_empty,
    input  logic [7:0]  mask_dout,
    
    // Output (Highlighted Image)
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [23:0] out_din
);

typedef enum logic [0:0] {s0, s1} state_types;
state_types state, state_c;

logic [23:0] pixel, pixel_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= s0;
        pixel <= 24'h0;
    end else begin
        state <= state_c;
        pixel <= pixel_c;
    end
end

always_comb begin
    img_rd_en  = 1'b0;
    mask_rd_en = 1'b0;
    out_wr_en  = 1'b0;
    out_din    = 24'b0;
    state_c    = state;
    pixel_c    = pixel;

    case (state)
        s0: begin
            // Wait for both image and mask to be available
            if (img_empty == 1'b0 && mask_empty == 1'b0) begin
                if (mask_dout == 8'hFF) begin
                    // Highlight with Red: R=FF, G=00, B=00
                    // BMP format is B, G, R. $fread reads bytes into [23:16], [15:8], [7:0].
                    // So in_din[23:16]=B, [15:8]=G, [7:0]=R.
                    // To get Red, we set [7:0]=FF, others 00 -> 0x0000FF.
                    pixel_c = 24'h0000FF; 
                end else begin
                    pixel_c = img_dout;
                end
                
                img_rd_en  = 1'b1;
                mask_rd_en = 1'b1;
                state_c    = s1;
            end
        end

        s1: begin
            if (out_full == 1'b0) begin
                out_din = pixel;
                out_wr_en = 1'b1;
                state_c = s0;
            end
        end

        default: begin
            state_c = s0;
        end

    endcase
end

endmodule
