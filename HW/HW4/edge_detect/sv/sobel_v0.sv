
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
    // logic [7:0] in_data_reg; // REMOVED: Use in_dout directly
    logic        write_lb; // Signal to write to line buffers
    
    logic [9:0] col_cnt, col_cnt_c; // Column counter for buffer indexing
    logic [9:0] x_cnt, x_cnt_c; // Output X coordinate counter
    logic [9:0] y_cnt, y_cnt_c; // Output Y coordinate counter

    // Initialize arrays for simulation to avoid X propagation
    // REMOVED INITIAL BLOCK to avoid multiple driver error

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
            
            // Reset Line Buffers (For simulation X-propagation fix)
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
        logic signed [10:0] gx, gy;
        logic signed [10:0] abs_gx, abs_gy;
        logic [11:0] sum;
        logic [7:0] final_val;
        
        // Coordinates for output (Removed wire declarations)
        // logic [31:0] out_x, out_y;

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
        
        // REMOVED: Expensive division/modulo logic
        // out_x = out_cnt % WIDTH;
        // out_y = out_cnt / WIDTH;

        // Calculate center index of the window based on current input count
        // When we have read pix_cnt pixels (indices 0 to pix_cnt-1),
        // the last pixel read is at (pix_cnt-1). This is the bottom-right of window.
        // The center (output) pixel corresponds to index (pix_cnt-1) - WIDTH - 1.
        // We can produce output for out_cnt if center_idx >= out_cnt.
        center_idx = $signed(pix_cnt) - $signed(WIDTH) - 2;

        case (state)
            s0: begin
                // Check if we can write an output pixel
                // Condition 1: We have enough data (center_idx >= out_cnt)
                // Condition 2: We have read ALL inputs (Draining phase), so we must flush remainder
                if (($signed(out_cnt) <= center_idx) || (pix_cnt >= WIDTH*HEIGHT)) begin
                    // We have enough data to compute out_cnt
                    
                    // Border handling using counters
                    if (x_cnt == 0 || x_cnt == WIDTH-1 || y_cnt == 0 || y_cnt == HEIGHT-1) begin
                        sob_res_c = 8'h00;
                    end else begin
                        // Compute Sobel
                        // Horizontal Mask:
                        // -1  0  1
                        // -2  0  2
                        // -1  0  1
                        gx = -1 * $signed({3'b0, w[0][0]}) + 1 * $signed({3'b0, w[0][2]}) +
                             -2 * $signed({3'b0, w[1][0]}) + 2 * $signed({3'b0, w[1][2]}) +
                             -1 * $signed({3'b0, w[2][0]}) + 1 * $signed({3'b0, w[2][2]});

                        // Vertical Mask:
                        // -1 -2 -1
                        //  0  0  0
                        //  1  2  1
                        gy = -1 * $signed({3'b0, w[0][0]}) - 2 * $signed({3'b0, w[0][1]}) - 1 * $signed({3'b0, w[0][2]}) +
                              1 * $signed({3'b0, w[2][0]}) + 2 * $signed({3'b0, w[2][1]}) + 1 * $signed({3'b0, w[2][2]});
                        
                        abs_gx = (gx < 0) ? -gx : gx;
                        abs_gy = (gy < 0) ? -gy : gy;
                        
                        // Average
                        sum = (abs_gx + abs_gy) / 2;
                        
                        if (sum > 255) sob_res_c = 8'hff;
                        else sob_res_c = sum[7:0];

                        // DEBUG: Check if we produce non-zero output
                        // if (sob_res_c != 0 && out_cnt < 10000) begin // Limit spam
                        //      $display("SOBEL NON-ZERO OUT at out_cnt=%0d (%0d,%0d) | val=%d", out_cnt, x_cnt, y_cnt, sob_res_c);
                        // end

                        // DEBUG PRINT for Mismatch at 721 (out_x=1, out_y=1)
                        // if (out_cnt == 721) begin
                        //     $display("DEBUG 721: w[0]=%h %h %h, w[1]=%h %h %h, w[2]=%h %h %h | Gx=%d Gy=%d Res=%d",
                        //         w[0][0], w[0][1], w[0][2],
                        //         w[1][0], w[1][1], w[1][2],
                        //         w[2][0], w[2][1], w[2][2],
                        //         gx, gy, sob_res_c);
                        // end
                    end
                    
                    state_c = s1; // Go to write
                end else begin
                    // Need more input data
                    if (in_empty == 1'b0) begin
                        state_c = s2; // Go to read
                    end
                    // Else wait
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
                
                // DEBUG: Check if we are receiving data
                // if (in_dout != 0 && pix_cnt > 720 && pix_cnt < 740) begin
                //      $display("SOBEL INPUT DATA DETECTED at pix_cnt=%0d: val=%h", pix_cnt, in_dout);
                // end

                // Update Window
                // Shift columns left
                w_c[0][0] = w[0][1]; w_c[0][1] = w[0][2];
                w_c[1][0] = w[1][1]; w_c[1][1] = w[1][2];
                w_c[2][0] = w[2][1]; w_c[2][1] = w[2][2];
                
                // New column
                // lb0[ptr] is the oldest pixel (Top Row of window)
                // lb1[ptr] is middle pixel (Mid Row of window)
                // in_dout is newest pixel (Bot Row of window)
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
