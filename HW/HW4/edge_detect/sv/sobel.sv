
module sobel #(
    parameter WIDTH = 720,
    parameter HEIGHT = 540
) (
    input  logic        clock,
    input  logic        reset,
    output logic        in_rd_en,
    input  logic        in_empty,
    input  logic [7:0]  in_dout,
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [7:0]  out_din
);

    typedef enum logic [1:0] {s0, s1, s2} state_types;
    state_types state, state_c;

    // Line Buffers
    // lb0: stores row y-2 (relative to current input y)
    // lb1: stores row y-1
    logic [7:0] lb0 [0:WIDTH-1] /* synthesis syn_ramstyle="block_ram" */;
    logic [7:0] lb1 [0:WIDTH-1] /* synthesis syn_ramstyle="block_ram" */;
    
    // Window Buffer (3x3)
    // w[row][col]
    // w[0] is top row, w[2] is bottom row
    logic [7:0] w [0:2][0:2];
    logic [7:0] w_c [0:2][0:2];

    // Counters
    logic [31:0] pix_cnt, pix_cnt_c; // Input pixels read
    logic [31:0] out_cnt, out_cnt_c; // Output pixels written

    // Result register
    logic [7:0] sob_res, sob_res_c;
    logic        write_lb; // Signal to write to line buffers
    
    logic [9:0] col_cnt, col_cnt_c; // Column counter for buffer indexing
    logic [9:0] x_cnt, x_cnt_c; // Output X coordinate counter
    logic [9:0] y_cnt, y_cnt_c; // Output Y coordinate counter

    always_ff @(posedge clock or posedge reset) begin
        if (reset == 1'b1) begin
            state <= s0;
            pix_cnt <= 0;
            out_cnt <= 0;
            sob_res <= 0;
            col_cnt <= 0;
            x_cnt <= 0;
            y_cnt <= 0;
            
            // Reset window
            for (int i=0; i<3; i++) begin
                for (int j=0; j<3; j++) begin
                    w[i][j] <= 0;
                end
            end
            
            // Reset Line Buffers
            for (int i = 0; i < WIDTH; i++) begin
                lb0[i] <= 8'h00;
                lb1[i] <= 8'h00;
            end
        end else begin
            state <= state_c;
            pix_cnt <= pix_cnt_c;
            out_cnt <= out_cnt_c;
            sob_res <= sob_res_c;
            col_cnt <= col_cnt_c;
            x_cnt <= x_cnt_c;
            y_cnt <= y_cnt_c;
            
            // Update Window
            w <= w_c;
            
            // Update Line Buffers
            if (write_lb) begin
                // Use col_cnt as index (avoid modulo operator)
                lb0[col_cnt] <= lb1[col_cnt];
                lb1[col_cnt] <= in_dout;
            end
        end
    end

    always_comb begin
        // Sobel calc variables
        logic signed [31:0] center_idx;
        logic [10:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
        logic [11:0] gx_pos, gx_neg, gy_pos, gy_neg;
        logic [11:0] abs_gx, abs_gy;
        logic [11:0] sum;
        
        // Defaults
        in_rd_en  = 1'b0;
        out_wr_en = 1'b0;
        out_din   = 8'b0;
        state_c   = state;
        pix_cnt_c = pix_cnt;
        out_cnt_c = out_cnt;
        sob_res_c = sob_res;
        col_cnt_c = col_cnt;
        x_cnt_c = x_cnt;
        y_cnt_c = y_cnt;
        
        w_c = w;
        write_lb = 1'b0;
        
        // Cast window pixels to larger type for calculation
        p00 = {3'b0, w[0][0]}; p01 = {3'b0, w[0][1]}; p02 = {3'b0, w[0][2]};
        p10 = {3'b0, w[1][0]}; p11 = {3'b0, w[1][1]}; p12 = {3'b0, w[1][2]};
        p20 = {3'b0, w[2][0]}; p21 = {3'b0, w[2][1]}; p22 = {3'b0, w[2][2]};

        // Initialize intermediate variables to avoid latches
        gx_pos = 0; gx_neg = 0;
        gy_pos = 0; gy_neg = 0;
        abs_gx = 0; abs_gy = 0;
        sum = 0;

        // Calculate center index of the window based on current input count
        center_idx = $signed(pix_cnt) - $signed(WIDTH) - 2;

        case (state)
            s0: begin
                // Check if we can write an output pixel
                if (($signed(out_cnt) <= center_idx) || (pix_cnt >= WIDTH*HEIGHT)) begin
                    
                    // Border handling using counters
                    if (x_cnt == 0 || x_cnt == WIDTH-1 || y_cnt == 0 || y_cnt == HEIGHT-1) begin
                        sob_res_c = 8'h00;
                    end else begin
                        // Compute Sobel Optimized
                        
                        // Horizontal Mask:
                        // -1  0  1
                        // -2  0  2
                        // -1  0  1
                        // gx = (Right Col) - (Left Col)
                        gx_pos = p02 + p22 + {p12[9:0], 1'b0}; // * 2 is shift left
                        gx_neg = p00 + p20 + {p10[9:0], 1'b0};
                        
                        if (gx_pos > gx_neg) abs_gx = gx_pos - gx_neg;
                        else                 abs_gx = gx_neg - gx_pos;

                        // Vertical Mask:
                        // -1 -2 -1
                        //  0  0  0
                        //  1  2  1
                        // gy = (Bottom Row) - (Top Row)
                        gy_pos = p20 + p22 + {p21[9:0], 1'b0};
                        gy_neg = p00 + p02 + {p01[9:0], 1'b0};
                        
                        if (gy_pos > gy_neg) abs_gy = gy_pos - gy_neg;
                        else                 abs_gy = gy_neg - gy_pos;
                        
                        // Average
                        sum = (abs_gx + abs_gy) >> 1;
                        
                        if (sum > 255) sob_res_c = 8'hff;
                        else sob_res_c = sum[7:0];
                    end
                    
                    state_c = s1; // Go to write
                end else begin
                    // Need more input data
                    if (in_empty == 1'b0) begin
                        state_c = s2; // Go to read
                    end
                end
            end

            s1: begin // Write Output
                if (out_full == 1'b0) begin
                    out_din = sob_res;
                    out_wr_en = 1'b1;
                    out_cnt_c = out_cnt + 1;
                    
                    // Update Output Coordinates
                    if (x_cnt == WIDTH-1) begin
                        x_cnt_c = 0;
                        if (y_cnt == HEIGHT-1) y_cnt_c = 0;
                        else y_cnt_c = y_cnt + 1;
                    end else begin
                        x_cnt_c = x_cnt + 1;
                    end
                    
                    state_c = s0;
                end
            end

            s2: begin // Read Input / Shift Buffer
                // Consume input
                in_rd_en = 1'b1;
                
                // Update Window
                // Shift columns left
                w_c[0][0] = w[0][1]; w_c[0][1] = w[0][2];
                w_c[1][0] = w[1][1]; w_c[1][1] = w[1][2];
                w_c[2][0] = w[2][1]; w_c[2][1] = w[2][2];
                
                // New column
                w_c[0][2] = lb0[col_cnt];
                w_c[1][2] = lb1[col_cnt];
                w_c[2][2] = in_dout;
                
                // Write to Line Buffers logic (happens in FF block)
                write_lb = 1'b1;
                
                // Update column counter
                if (col_cnt == WIDTH-1) col_cnt_c = 0;
                else col_cnt_c = col_cnt + 1;
                
                pix_cnt_c = pix_cnt + 1;
                state_c = s0;
            end
            
            default: state_c = s0;
        endcase
    end

endmodule
