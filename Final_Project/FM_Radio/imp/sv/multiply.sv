// =============================================================
// multiply.sv — Fixed-point multiplier
// Matches C: output = DEQUANTIZE(x * y)
// Two-process: always_comb + always_ff
// =============================================================

module multiply import fir_pkg::*; (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            valid_in,
    input  logic signed [WIDTH-1:0]         x_in,
    input  logic signed [WIDTH-1:0]         y_in,
    output logic                            valid_out,
    output logic signed [WIDTH-1:0]         out
);

    // Combinational
    logic signed [WIDTH-1:0] next_out;

    always_comb begin
        // 32-bit overflow matches C int arithmetic
        next_out = WIDTH'(fir_pkg::div1024_f(int'(x_in) * int'(y_in)));
    end

    // Sequential
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out       <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                out       <= next_out;
                valid_out <= 1'b1;
            end
        end
    end

endmodule
