// =============================================================
// fir.sv — Parameterized Real FIR Filter with Decimation
// Matches C reference: fir() / fir_n() in fm_radio.cpp
// =============================================================

module fir #(
    parameter int TAPS      = 32,
    parameter int DECIM     = 1,
    parameter int WIDTH     = 32,
    parameter int CWIDTH    = 32,
    parameter int BITS      = 10
)(
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            valid_in,
    input  logic signed  [WIDTH-1:0]        x_in,
    input  logic signed  [CWIDTH-1:0]       coeffs [0:TAPS-1],
    output logic                            valid_out,
    output logic signed  [WIDTH-1:0]        y_out
);

    // Shift register: x[0] = newest, x[TAPS-1] = oldest
    logic signed [WIDTH-1:0] x_reg [0:TAPS-1];

    // Decimation counter (0 .. DECIM-1)
    logic [$clog2(TAPS > DECIM ? TAPS : DECIM)-1:0] cnt;

    // MAC accumulator
    logic signed [WIDTH+CWIDTH-1:0] acc;

    // Output
    logic signed [WIDTH-1:0] y_reg;
    logic                    v_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < TAPS; k++) x_reg[k] <= '0;
            cnt   <= '0;
            y_reg <= '0;
            v_reg <= 1'b0;
        end else begin
            v_reg <= 1'b0;

            if (valid_in) begin
                // Always shift by 1 and insert new sample
                for (int k = TAPS-1; k >= 1; k--)
                    x_reg[k] <= x_reg[k-1];
                x_reg[0] <= x_in;

                // Decimation counter
                if (cnt == DECIM - 1) begin
                    cnt <= '0;

                    // MAC: use the UPDATED register values
                    // x_new[0] = x_in, x_new[k] = x_reg[k-1] for k>=1
                    acc = '0;
                    for (int k = 0; k < TAPS; k++) begin
                        logic signed [WIDTH-1:0] x_val;
                        logic signed [WIDTH-1:0] prod;
                        x_val = (k == 0) ? x_in : x_reg[k-1];
                        prod  = coeffs[TAPS-1-k] * x_val;
                        acc   = acc + fir_pkg::div1024_f(prod);
                    end

                    y_reg <= WIDTH'(acc);
                    v_reg <= 1'b1;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end

    assign valid_out = v_reg;
    assign y_out     = y_reg;

endmodule
