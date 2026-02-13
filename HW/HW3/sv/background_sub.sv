
module background_sub (
    input  logic        clock,
    input  logic        reset,
    
    // Input A (Base Grayscale)
    output logic        a_rd_en,
    input  logic        a_empty,
    input  logic [7:0]  a_dout,
    
    // Input B (Image Grayscale)
    output logic        b_rd_en,
    input  logic        b_empty,
    input  logic [7:0]  b_dout,
    
    // Output (Mask)
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [7:0]  out_din
);

typedef enum logic [0:0] {s0, s1} state_types;
state_types state, state_c;

logic [7:0] mask, mask_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= s0;
        mask <= 8'h0;
    end else begin
        state <= state_c;
        mask <= mask_c;
    end
end

always_comb begin
    a_rd_en   = 1'b0;
    b_rd_en   = 1'b0;
    out_wr_en = 1'b0;
    out_din   = 8'b0;
    state_c   = state;
    mask_c    = mask;

    case (state)
        s0: begin
            // Wait for both inputs to be available
            if (a_empty == 1'b0 && b_empty == 1'b0) begin
                // Calculate absolute difference
                logic [7:0] diff;
                if (a_dout > b_dout)
                    diff = a_dout - b_dout;
                else
                    diff = b_dout - a_dout;
                
                // Thresholding
                if (diff > 8'd50)
                    mask_c = 8'hFF;
                else
                    mask_c = 8'h00;
                
                a_rd_en = 1'b1;
                b_rd_en = 1'b1;
                state_c = s1;
            end
        end

        s1: begin
            if (out_full == 1'b0) begin
                out_din = mask;
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
