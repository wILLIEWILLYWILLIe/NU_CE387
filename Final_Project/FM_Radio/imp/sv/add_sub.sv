// =============================================================
// add_sub.sv — Fixed-point adder/subtractor
// Matches C: add_n() and sub_n()
// left_raw  = audio_lpr + audio_lmr
// right_raw = audio_lpr - audio_lmr
// =============================================================

module add_sub import fir_pkg::*; (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            valid_in,
    input  logic                            do_sub,      // 0=add, 1=subtract
    input  logic signed [WIDTH-1:0]         x_in,
    input  logic signed [WIDTH-1:0]         y_in,
    output logic                            valid_out,
    output logic signed [WIDTH-1:0]         z_out
);

    // Combinational
    logic signed [WIDTH-1:0] result;

    always_comb begin
        result = do_sub ? (x_in - y_in) : (x_in + y_in);
    end

    // Sequential
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z_out     <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                z_out     <= result;
                valid_out <= 1'b1;
            end
        end
    end

endmodule
