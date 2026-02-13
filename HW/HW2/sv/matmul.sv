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

    typedef enum logic [1:0] {S_IDLE, S_PRELOAD, S_RUN, S_DONE} state_t;
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
                    // Initialize counters
                    i_c = 0;
                    j_c = 0;
                    k_c = 0;
                    acc_c = 0;
                    done_c = 1'b0;
                    state_c = S_PRELOAD;
                end
            end

            // Single cycle overhead to prime the pipeline
            S_PRELOAD: begin
                // Request A[0][0], B[0][0]
                a_addr = i * MATRIX_SIZE + k; 
                b_addr = k * MATRIX_SIZE + j;
                
                k_c = k + 1;
                state_c = S_RUN;
            end

            // Main Pipeline Loop
            S_RUN: begin
                // 1. Accumulate data valid from previous cycle
                // acc_new is the result of the accumulation for the current step
                logic [DATA_WIDTH-1:0] acc_new;
                acc_new = acc + (a_dout * b_dout);
                acc_c = acc_new;

                // 2. Address Generation Logic
                // We need to determine the (i, j, k) for the NEXT read request.
                // Note: 'k' here represents the index we are requesting NOW,
                // while the data we are processing (a_dout) corresponds to k-1.
                
                // --- Condition: End of a Row (k reaches MATRIX_SIZE) ---
                if (k == MATRIX_SIZE) begin
                    // This implies we just received data for k=N-1 (in the previous cycle),
                    // and we are currently computing the final accumulation for C[i][j].
                    // Thus, acc_new holds the complete result.
                    
                    // ==> WRITE BACK C[i][j]
                    c_addr  = i * MATRIX_SIZE + j;
                    c_din   = acc_new;
                    c_wr_en = 1'b1;
                    
                    // Reset Accumulator for next element
                    acc_c = 0; 
                    
                    // Loop Update Logic (Compute Next i, j)
                    if (j < MATRIX_SIZE - 1) begin
                        // Move to next column
                        j_c = j + 1;
                        k_c = 1; // Next cycle corresponds to processing k=0.
                                 // We set address for k=0 now.
                                 // And we update k_c to 1 for the following cycle.
                        
                        a_addr = i * MATRIX_SIZE + 0;
                        b_addr = 0 * MATRIX_SIZE + (j + 1);
                        state_c = S_RUN;
                        
                    end else begin
                        // End of row, move to next row
                        j_c = 0;
                        if (i < MATRIX_SIZE - 1) begin
                            i_c = i + 1;
                            k_c = 1; // Same logic as above
                            
                            a_addr = (i + 1) * MATRIX_SIZE + 0;
                            b_addr = 0 * MATRIX_SIZE + 0;
                            state_c = S_RUN;
                        end else begin
                            // End of Matrix
                            state_c = S_IDLE;
                            done_c = 1'b1;
                        end
                    end
                end 
                // --- Condition: Normal Inner Loop ---
                else begin
                    // Normal accumulation is happening
                    // Prefetch next k
                    a_addr = i * MATRIX_SIZE + k;
                    b_addr = k * MATRIX_SIZE + j;
                    
                    k_c = k + 1;
                    state_c = S_RUN;
                end
            end
            
            default: state_c = S_IDLE;
        endcase
    end

endmodule