module fibonacci(
  input logic clk, 
  input logic reset,
  input logic [15:0] din,
  input logic start,
  output logic [15:0] dout,
  output logic done );

    // Local logic signals
    typedef enum logic [1:0] {IDLE, COMPUTE, DONE} state_t;
    state_t state, next_state;
    logic [15:0] count;
    logic [15:0] f1, f2;

    always_ff @(posedge clk, posedge reset)
    begin
        if ( reset == 1'b1 ) begin
            state <= IDLE;
            dout <= '0;
            done <= 1'b0;
            count <= '0;
            f1 <= '0;
            f2 <= '0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        count <= din;
                        f1 <= 0;
                        f2 <= 1;
                        // Pre-load logic for small numbers
                        if (din == 0) dout <= 0;
                        else if (din == 1) dout <= 1;
                    end
                end
                COMPUTE: begin
                    count <= count - 1;
                    f1 <= f2;
                    f2 <= f1 + f2;
                end
                DONE: begin
                    done <= 1'b1;
                    // For n >= 2, the result is in f2 after the loop finishes
                    if (din >= 2) dout <= f2;
                end
            endcase
        end
    end

    always_comb 
    begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    if (din < 2) 
                        next_state = DONE;
                    else 
                        next_state = COMPUTE;
                end
            end
            COMPUTE: begin
                if (count == 2) 
                    next_state = DONE;
            end
            DONE: begin
                if (!start) 
                    next_state = IDLE;
            end
        endcase
    end
endmodule
