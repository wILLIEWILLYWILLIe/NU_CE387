
module complex_mult #(
    parameter int DATA_WIDTH = 20,
    parameter int TWIDDLE_WIDTH = 16,
    parameter int Q = 14
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   valid_in,
    input  logic signed [DATA_WIDTH-1:0] a_real,
    input  logic signed [DATA_WIDTH-1:0] a_imag,
    input  logic signed [TWIDDLE_WIDTH-1:0] w_real,
    input  logic signed [TWIDDLE_WIDTH-1:0] w_imag,
    
    output logic                   valid_out,
    output logic signed [DATA_WIDTH-1:0] out_real,
    output logic signed [DATA_WIDTH-1:0] out_imag
);

    // Stage 0 registers: Input registration
    logic signed [DATA_WIDTH-1:0] a_real_q, a_imag_q;
    logic signed [TWIDDLE_WIDTH-1:0] w_real_q, w_imag_q;
    logic val_q;

    // Stage 1 registers: raw products
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH-1:0] prod_rr, prod_ii, prod_ri, prod_ir;
    logic val_p1;

    // Stage 2 registers: dequantized products
    logic signed [DATA_WIDTH-1:0] deq_rr, deq_ii, deq_ri, deq_ir;
    logic val_p2;

    // Stage 3 registers: final add/sub
    logic signed [DATA_WIDTH-1:0] out_real_reg, out_imag_reg;
    logic val_p3;

    // Dequantize function matching C: (val + QUANT_VAL/2) / QUANT_VAL
    localparam logic signed [DATA_WIDTH+TWIDDLE_WIDTH-1:0] HALF = 1 <<< (Q-1);
    localparam logic signed [DATA_WIDTH+TWIDDLE_WIDTH-1:0] QUANT = 1 <<< Q;

    function automatic logic signed [DATA_WIDTH-1:0] dequant_trunc(
        input logic signed [DATA_WIDTH+TWIDDLE_WIDTH-1:0] val
    );
        logic signed [DATA_WIDTH+TWIDDLE_WIDTH-1:0] rounded;
        logic signed [DATA_WIDTH+TWIDDLE_WIDTH-1:0] adjusted;
        rounded = val + HALF;
        adjusted = (rounded < 0) ? (rounded + (QUANT - 1)) : rounded;
        return DATA_WIDTH'(adjusted >>> Q);
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_real_q <= '0; a_imag_q <= '0; w_real_q <= '0; w_imag_q <= '0; val_q <= 1'b0;
            prod_rr <= '0; prod_ii <= '0; prod_ri <= '0; prod_ir <= '0; val_p1 <= 1'b0;
            deq_rr <= '0; deq_ii <= '0; deq_ri <= '0; deq_ir <= '0; val_p2 <= 1'b0;
            out_real_reg <= '0; out_imag_reg <= '0; val_p3 <= 1'b0;
        end else begin
            // Stage 0: Input Registration
            val_q    <= valid_in;
            a_real_q <= a_real;
            a_imag_q <= a_imag;
            w_real_q <= w_real;
            w_imag_q <= w_imag;

            // Stage 1: Multiplication
            val_p1  <= val_q;
            prod_rr <= a_real_q * w_real_q;
            prod_ii <= a_imag_q * w_imag_q;
            prod_ri <= a_real_q * w_imag_q;
            prod_ir <= a_imag_q * w_real_q;

            // Stage 2: Individual dequantization
            val_p2 <= val_p1;
            deq_rr <= dequant_trunc(prod_rr);
            deq_ii <= dequant_trunc(prod_ii);
            deq_ri <= dequant_trunc(prod_ri);
            deq_ir <= dequant_trunc(prod_ir);

            // Stage 3: Add/Sub
            val_p3 <= val_p2;
            out_real_reg <= deq_rr - deq_ii;
            out_imag_reg <= deq_ri + deq_ir;
        end
    end

    assign valid_out = val_p3;
    assign out_real = out_real_reg;
    assign out_imag = out_imag_reg;

endmodule
