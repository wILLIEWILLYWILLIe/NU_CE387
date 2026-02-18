
module cordic (
    input  logic        clock,
    input  logic        reset,
    
    input  logic        valid_in,
    input  logic signed [31:0] rad_in, // 32-bit input mostly matching C++ int
    
    output logic        valid_out,
    output logic signed [15:0] sin_out,
    output logic signed [15:0] cos_out,
    output logic        ready // Ready to accept new input
);

    // CORDIC Constants
    // 16-bit signed fixed point math
    // BITS 14
    // QUANT_VAL (1 << 14)

    typedef enum logic [2:0] {
        IDLE,
        PRE_CALC_1,
        PRE_CALC_2,
        CALC,
        DONE
    } state_t;

    state_t state, state_c;

    // Registers
    logic signed [15:0] x, x_c;
    logic signed [15:0] y, y_c;
    logic signed [31:0] z, z_c; 
    logic [4:0]  iter, iter_c;

    // Constants
    localparam signed [15:0] CORDIC_1K = 16'd9949; // 0x26DD
    
    // PI Constants in S14 format (scaled by 2^14)
    // Matches C++ truncation: (int)(VAL * 16384)
    localparam signed [31:0] PI      = 32'd51471; 
    localparam signed [31:0] TWO_PI  = 32'd102943;
    localparam signed [31:0] HALF_PI = 32'd25735;

    // Lookup Table
    logic signed [15:0] cordic_table [0:15];
    
    initial begin
        cordic_table[0] = 16'h3243;
        cordic_table[1] = 16'h1DAC;
        cordic_table[2] = 16'h0FAD;
        cordic_table[3] = 16'h07F5;
        cordic_table[4] = 16'h03FE;
        cordic_table[5] = 16'h01FF;
        cordic_table[6] = 16'h00FF;
        cordic_table[7] = 16'h007F;
        cordic_table[8] = 16'h003F;
        cordic_table[9] = 16'h001F;
        cordic_table[10] = 16'h000F;
        cordic_table[11] = 16'h0007;
        cordic_table[12] = 16'h0003;
        cordic_table[13] = 16'h0001;
        cordic_table[14] = 16'h0000;
        cordic_table[15] = 16'h0000;
    end

    // Sequential Process
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            x     <= '0;
            y     <= '0;
            z     <= '0;
            iter  <= '0;
            valid_out <= 1'b0;
            sin_out <= '0;
            cos_out <= '0;
        end else begin
            state <= state_c;
            x     <= x_c;
            y     <= y_c;
            z     <= z_c;
            iter  <= iter_c;
            
            // Output registration
            if (state == DONE) begin
                valid_out <= 1'b1;
                cos_out   <= x;
                sin_out   <= y;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

    // Combinational Process
    always_comb begin
        // Defaults
        state_c = state;
        x_c     = x;
        y_c     = y;
        z_c     = z;
        iter_c  = iter;

        case (state)
            IDLE: begin
                if (valid_in) begin
                    x_c = CORDIC_1K;
                    y_c = 16'd0;
                    z_c = rad_in;
                    state_c = PRE_CALC_1;
                end
            end

            PRE_CALC_1: begin
                // Range Reduction Step 1: +/- 2PI
                logic signed [31:0] z_temp;
                z_temp = z;

                 if (z_temp > PI)       z_temp = z_temp - TWO_PI;
                else if (z_temp < -PI) z_temp = z_temp + TWO_PI;
                
                z_c = z_temp;
                state_c = PRE_CALC_2;
            end

            PRE_CALC_2: begin
                // Range Reduction Step 2: +/- PI and Coordinate Rotation
                logic signed [31:0] z_temp;
                z_temp = z;

                if (z_temp > HALF_PI) begin
                    z_temp = z_temp - PI;
                    x_c = -x;
                    y_c = -y;
                end else if (z_temp < -HALF_PI) begin
                    z_temp = z_temp + PI;
                    x_c = -x;
                    y_c = -y;
                end
                
                z_c = z_temp;
                iter_c  = 5'd0;
                state_c = CALC;
            end

            CALC: begin
                logic signed [15:0] tx, ty;
                logic signed [31:0] tz;
                logic signed [15:0] y_shifted, x_shifted;
                
                y_shifted = y >>> iter;
                x_shifted = x >>> iter;

                if (z >= 0) begin
                    tx = x - y_shifted;
                    ty = y + x_shifted;
                    tz = z - cordic_table[iter];
                end else begin
                    tx = x + y_shifted;
                    ty = y - x_shifted;
                    tz = z + cordic_table[iter];
                end
                
                x_c = tx;
                y_c = ty;
                z_c = tz;
                
                if (iter == 5'd15) begin
                    state_c = DONE;
                end else begin
                    iter_c = iter + 1'b1;
                end
            end

            DONE: begin
                state_c = IDLE;
            end
            
            default: state_c = IDLE;
        endcase
    end

    assign ready = (state == IDLE);

endmodule
