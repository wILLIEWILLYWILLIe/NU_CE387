
module fft_bit_reversal #(
    parameter int N = 16,
    parameter int DATA_WIDTH = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   valid_in,
    input  logic signed [DATA_WIDTH-1:0] real_in,
    input  logic signed [DATA_WIDTH-1:0] imag_in,
    
    output logic                   valid_out,
    output logic signed [DATA_WIDTH-1:0] real_out,
    output logic signed [DATA_WIDTH-1:0] imag_out,
    output logic                   ready_in
);

    localparam int ADDR_WIDTH = $clog2(N);

    // Memory registers (Ping-Pong)
    logic signed [DATA_WIDTH-1:0] mem_real_a [0:N-1];
    logic signed [DATA_WIDTH-1:0] mem_imag_a [0:N-1];
    logic signed [DATA_WIDTH-1:0] mem_real_b [0:N-1];
    logic signed [DATA_WIDTH-1:0] mem_imag_b [0:N-1];

    // State registers
    logic [ADDR_WIDTH-1:0] wr_ptr, wr_ptr_c;
    logic [ADDR_WIDTH-1:0] rd_ptr, rd_ptr_c;
    logic                  pp_state, pp_state_c; // 0: write A, read B | 1: write B, read A
    logic                  out_active, out_active_c;
    logic                  valid_out_reg, valid_out_c;
    logic signed [DATA_WIDTH-1:0] real_out_reg, real_out_c;
    logic signed [DATA_WIDTH-1:0] imag_out_reg, imag_out_c;

    logic [ADDR_WIDTH-1:0] bit_rev_rd_ptr;
    assign bit_rev_rd_ptr = {<<{rd_ptr}};

    assign ready_in = 1'b1;
    assign valid_out = valid_out_reg;
    assign real_out  = real_out_reg;
    assign imag_out  = imag_out_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            pp_state <= 1'b0;
            out_active <= 1'b0;
            valid_out_reg <= 1'b0;
            real_out_reg <= '0;
            imag_out_reg <= '0;
        end else begin
            wr_ptr <= wr_ptr_c;
            rd_ptr <= rd_ptr_c;
            pp_state <= pp_state_c;
            out_active <= out_active_c;
            valid_out_reg <= valid_out_c;
            real_out_reg <= real_out_c;
            imag_out_reg <= imag_out_c;
            
            if (valid_in) begin
                if (pp_state == 1'b0) begin
                    mem_real_a[wr_ptr] <= real_in;
                    mem_imag_a[wr_ptr] <= imag_in;
                end else begin
                    mem_real_b[wr_ptr] <= real_in;
                    mem_imag_b[wr_ptr] <= imag_in;
                end
            end
        end
    end

    always_comb begin
        wr_ptr_c = wr_ptr;
        rd_ptr_c = rd_ptr;
        pp_state_c = pp_state;
        out_active_c = out_active;
        valid_out_c = 1'b0;
        real_out_c = '0;
        imag_out_c = '0;

        // Write Logic
        if (valid_in) begin
            if (wr_ptr == N-1) begin
                wr_ptr_c = '0;
                pp_state_c = !pp_state;
                out_active_c = 1'b1; // Trigger output of the block just finished
            end else begin
                wr_ptr_c = wr_ptr + 1;
            end
        end

        // Read Logic
        if (out_active) begin
            valid_out_c = 1'b1;
            if (pp_state == 1'b1) begin // We just switched to writing B, so read A
                real_out_c = mem_real_a[bit_rev_rd_ptr];
                imag_out_c = mem_imag_a[bit_rev_rd_ptr];
            end else begin // We just switched to writing A, so read B
                real_out_c = mem_real_b[bit_rev_rd_ptr];
                imag_out_c = mem_imag_b[bit_rev_rd_ptr];
            end
            
            if (rd_ptr == N-1) begin
                rd_ptr_c = '0;
                out_active_c = 1'b0;
            end else begin
                rd_ptr_c = rd_ptr + 1;
            end
        end
    end

endmodule
