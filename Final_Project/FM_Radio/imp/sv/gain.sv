// =============================================================
// gain.sv — Volume control
// Matches C: output = DEQUANTIZE(input * gain) << (14 - BITS)
// Two-process: always_comb + always_ff
// =============================================================

module gain import fir_pkg::*; (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            valid_in,
    input  logic signed [WIDTH-1:0]         x_in,
    input  logic signed [WIDTH-1:0]         gain_val,
    output logic                            valid_out,
    output logic signed [WIDTH-1:0]         y_out
);

    // Combinational
    logic signed [WIDTH-1:0] next_y;

    always_comb begin
        // C: DEQUANTIZE(x * gain) << (14 - BITS) = (x*gain/1024) << 4
        next_y = WIDTH'(fir_pkg::div1024_f(int'(x_in) * int'(gain_val)) <<< (14 - BITS));
    end

    // Sequential
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out     <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                y_out     <= next_y;
                valid_out <= 1'b1;
            end
        end
    end

endmodule
