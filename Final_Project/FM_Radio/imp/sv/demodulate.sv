// =============================================================
// demodulate.sv — FM Demodulator
// Matches C reference: demodulate() in fm_radio.cpp
// Uses qarctan_f() function for inline evaluation
// =============================================================

module demodulate import fir_pkg::*, qarctan_pkg::*; (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            valid_in,
    input  logic signed [WIDTH-1:0]         real_in,
    input  logic signed [WIDTH-1:0]         imag_in,
    output logic                            valid_out,
    output logic signed [WIDTH-1:0]         demod_out
);

    // Previous I/Q sample
    logic signed [WIDTH-1:0] real_prev, imag_prev;

    // ----------------------------------------------------
    // PIPELINE STAGE 1: I/Q Cross-Multiply -> sum/diff
    // ----------------------------------------------------
    int prod_rr, prod_ii, prod_ri, prod_ir;
    int r_val, i_val;
    
    // Stage 1 Registers
    int stg1_r_val, stg1_i_val;
    logic stg1_valid;

    always_comb begin
        prod_rr = int'(real_prev) * int'(real_in);
        prod_ii = (-int'(imag_prev)) * int'(imag_in);
        prod_ri = int'(real_prev) * int'(imag_in);
        prod_ir = (-int'(imag_prev)) * int'(real_in);

        r_val = fir_pkg::div1024_f(prod_rr) - fir_pkg::div1024_f(prod_ii);
        i_val = fir_pkg::div1024_f(prod_ri) + fir_pkg::div1024_f(prod_ir);
    end

    // ----------------------------------------------------
    // PIPELINE STAGE 2: Start qarctan (abs_y, r division)
    // ----------------------------------------------------
    int stg2_y, stg2_x, stg2_abs_y;
    int stg2_r_calc;
    
    // Stage 2 Registers
    int stg2_y_reg, stg2_x_reg, stg2_r;
    logic stg2_valid;

    // Evaluate intermediate division
    always_comb begin
        stg2_y = stg1_i_val;
        stg2_x = stg1_r_val;
        
        // abs(y) + 1
        stg2_abs_y = (stg2_y < 0) ? -stg2_y : stg2_y;
        stg2_abs_y = stg2_abs_y + 1;
        
        // Division Block
        if (stg2_x >= 0) begin
            stg2_r_calc = ((stg2_x - stg2_abs_y) * QUANT_VAL) / (stg2_x + stg2_abs_y);
        end else begin
            stg2_r_calc = ((stg2_x + stg2_abs_y) * QUANT_VAL) / (stg2_abs_y - stg2_x);
        end
    end

    // ----------------------------------------------------
    // PIPELINE STAGE 3: Finish qarctan & Output Gain
    // ----------------------------------------------------
    int stg3_prod, stg3_angle;
    int demod_val;

    always_comb begin
        if (stg2_x_reg >= 0) begin
            stg3_prod = qarctan_pkg::QUAD1 * stg2_r;
            stg3_angle = qarctan_pkg::QUAD1 - fir_pkg::div1024_f(stg3_prod);
        end else begin
            stg3_prod = qarctan_pkg::QUAD1 * stg2_r;
            stg3_angle = qarctan_pkg::QUAD3 - fir_pkg::div1024_f(stg3_prod);
        end
        
        // negate if in quad III or IV
        stg3_angle = (stg2_y_reg < 0) ? -stg3_angle : stg3_angle;
        
        // out = DEQUANTIZE(gain * qarctan(i, r))
        demod_val = fir_pkg::div1024_f(FM_DEMOD_GAIN * stg3_angle);
    end

    // ----------------------------------------------------
    // Pipeline Sequential Control
    // ----------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            real_prev <= '0;
            imag_prev <= '0;
            
            stg1_r_val <= '0;
            stg1_i_val <= '0;
            stg1_valid <= 1'b0;
            
            stg2_y_reg <= '0;
            stg2_x_reg <= '0;
            stg2_r <= '0;
            stg2_valid <= 1'b0;
            
            demod_out <= '0;
            valid_out <= 1'b0;
        end else begin
            // Stage 1
            stg1_valid <= valid_in;
            if (valid_in) begin
                stg1_r_val <= r_val;
                stg1_i_val <= i_val;
                real_prev <= real_in;
                imag_prev <= imag_in;
            end
            
            // Stage 2
            stg2_valid <= stg1_valid;
            if (stg1_valid) begin
                stg2_y_reg <= stg2_y;
                stg2_x_reg <= stg2_x;
                stg2_r     <= stg2_r_calc;
            end
            
            // Stage 3 (Output)
            valid_out <= stg2_valid;
            if (stg2_valid) begin
                demod_out <= demod_val;
            end
        end
    end

endmodule
