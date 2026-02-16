 
module seq_detector (
    input logic clock, 
    input logic reset,
    input logic sequence_in,
    output logic detector_out );

    // local signals
    enum logic [3:0] {S0, S1, S2, S3} state, next_state;
    logic detector_c;

    always_ff @(posedge clock, posedge reset) begin
        if( reset == 1'b1 ) begin
            state <= S0;
            detector_out <= 1'b0;
        end else begin
            state <= next_state; 
            detector_out <= detector_c;
        end 
    end
        
    always_comb begin
        next_state = state;
        detector_c = 1'b0;

        case ( state ) 
            S0: begin // 0000
                if( sequence_in == 1'b1 )
                    next_state = S1;
            end
            S1: begin // 0001
                if ( sequence_in == 1'b0 )
                    next_state = S2;
            end
            S2: begin // 0010
                if ( sequence_in == 1'b1 )
                    next_state = S3;
                else 
                    next_state = S0;
            end 
            S3: begin // 0101
                if ( sequence_in == 1'b1 ) begin
                    detector_c = 1'b1;
                    next_state = S0;
                end else begin
                    next_state = S2;
                end
            end
            default:
                next_state = S0;
        endcase
    end
endmodule