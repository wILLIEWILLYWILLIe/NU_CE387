
module cordic_stage #(
    parameter int SHIFT = 0,
    parameter int WIDTH = 16
)(
    input  logic        clock,
    input  logic        reset,
    input  logic        valid_in,
    input  logic signed [WIDTH-1:0] x_in,
    input  logic signed [WIDTH-1:0] y_in,
    input  logic signed [31:0]      z_in,
    // Removed atan_val input, handled internally
    
    output logic        valid_out,
    output logic signed [WIDTH-1:0] x_out,
    output logic signed [WIDTH-1:0] y_out,
    output logic signed [31:0]      z_out
);

    // Combinational Signals
    logic signed [WIDTH-1:0] x_next, y_next;
    logic signed [31:0]      z_next;
    logic signed [WIDTH-1:0] x_shifted, y_shifted;
    logic signed [31:0]      atan_val;

    // Local Lookup Table
    always_comb begin
        case (SHIFT)
            0: atan_val = 32'h3243;
            1: atan_val = 32'h1DAC;
            2: atan_val = 32'h0FAD;
            3: atan_val = 32'h07F5;
            4: atan_val = 32'h03FE;
            5: atan_val = 32'h01FF;
            6: atan_val = 32'h00FF;
            7: atan_val = 32'h007F;
            8: atan_val = 32'h003F;
            9: atan_val = 32'h001F;
            10: atan_val = 32'h000F;
            11: atan_val = 32'h0007;
            12: atan_val = 32'h0003;
            13: atan_val = 32'h0001;
            default: atan_val = 32'h0000;
        endcase
    end

    // -------------------------------------------------------------------------
    // Combinational Process (Calculation)
    // -------------------------------------------------------------------------
    always_comb begin
        // Barrel Shifter
        x_shifted = x_in >>> SHIFT;
        y_shifted = y_in >>> SHIFT;
        
        // CORDIC Rotation
        if (z_in >= 0) begin
            x_next = x_in - y_shifted;
            y_next = y_in + x_shifted;
            z_next = z_in - atan_val;
        end else begin
            x_next = x_in + y_shifted;
            y_next = y_in - x_shifted;
            z_next = z_in + atan_val;
        end
    end

    // -------------------------------------------------------------------------
    // Sequential Process (Pipeline Register)
    // -------------------------------------------------------------------------
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            valid_out <= 1'b0;
            x_out     <= '0;
            y_out     <= '0;
            z_out     <= '0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                x_out <= x_next;
                y_out <= y_next;
                z_out <= z_next;
            end
        end
    end

endmodule
