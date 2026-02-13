module matmul
#(  parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter MATRIX_SIZE = 8) // N=8
(
    input  logic                  clock,
    input  logic                  reset,
    input  logic                  start,
    output logic                  done,
    
    // Interface to BRAM A (Read only)
    input  logic [DATA_WIDTH-1:0] a_dout,
    output logic [ADDR_WIDTH-1:0] a_addr,
    
    // Interface to BRAM B (Read only)
    input  logic [DATA_WIDTH-1:0] b_dout,
    output logic [ADDR_WIDTH-1:0] b_addr,
    
    // Interface to BRAM C (Write only)
    output logic [DATA_WIDTH-1:0] c_din,
    output logic [ADDR_WIDTH-1:0] c_addr,
    output logic                  c_wr_en
);

    typedef enum logic [1:0] {S_IDLE, S_PRELOAD, S_CALC, S_WRITE} state_t;
    state_t state, state_c;
    
    // Counters
    logic [31:0] i, i_c;
    logic [31:0] j, j_c;
    logic [31:0] k, k_c;
    
    // Accumulator
    logic [DATA_WIDTH-1:0] acc, acc_c;
    
    logic done_o, done_c;
    
    assign done = done_o;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state   <= S_IDLE;
            i       <= '0;
            j       <= '0;
            k       <= '0;
            acc     <= '0;
            done_o  <= 1'b0;
        end else begin
            state   <= state_c;
            i       <= i_c;
            j       <= j_c;
            k       <= k_c;
            acc     <= acc_c;
            done_o  <= done_c;
        end
    end

    always_comb begin
        // Defaults
        state_c   = state;
        i_c       = i;
        j_c       = j;
        k_c       = k;
        acc_c     = acc;
        done_c    = done_o;
        
        a_addr    = '0;
        b_addr    = '0;
        c_addr    = '0;
        c_din     = '0;
        c_wr_en   = 1'b0;

        case (state)
            S_IDLE: begin
                if (start) begin
                    state_c = S_PRELOAD;
                    i_c = 0;
                    j_c = 0;
                    k_c = 0;
                    acc_c = 0;
                    done_c = 1'b0;
                end
            end

            S_PRELOAD: begin
                // Pre-fetch the first data A[i][0], B[0][j]
                // Address calculation: row-major order
                // A[i][k] -> i*N + k
                // B[k][j] -> k*N + j
                a_addr = i * MATRIX_SIZE + k; // k is 0 here
                b_addr = k * MATRIX_SIZE + j;
                
                k_c = k + 1; // Move to next k for S_CALC
                state_c = S_CALC;
            end

            S_CALC: begin
                // In this state:
                // 1. Data requested in prev cycle (k-1) is now available at a_dout/b_dout.
                // 2. We accumulate that data.
                // 3. We request data for current k (which will be used in next cycle).
                
                // Accumulate data from (k-1)
                acc_c = acc + (a_dout * b_dout);
                
                // Check if we have processed all k (0 to N-1)
                if (k < MATRIX_SIZE) begin
                    // Request next data
                    a_addr = i * MATRIX_SIZE + k;
                    b_addr = k * MATRIX_SIZE + j;
                    k_c = k + 1;
                    state_c = S_CALC; // Stay
                end else begin
                    // We just processed the data for k-1 (which was N-1, the last one)
                    state_c = S_WRITE;
                end
            end

            S_WRITE: begin
                c_addr  = i * MATRIX_SIZE + j;
                c_din   = acc;
                c_wr_en = 1'b1;
                
                // Update loops
                if (j < MATRIX_SIZE - 1) begin
                    j_c = j + 1;
                    k_c = 0;
                    acc_c = 0;
                    state_c = S_PRELOAD;
                end else begin
                    j_c = 0;
                    if (i < MATRIX_SIZE - 1) begin
                        i_c = i + 1;
                        k_c = 0;
                        acc_c = 0;
                        state_c = S_PRELOAD;
                    end else begin
                        done_c = 1'b1;
                        state_c = S_IDLE;
                    end
                end
            end
        endcase
    end

endmodule

