
module cordic (
    input  logic        clock,
    input  logic        reset,
    
    input  logic        valid_in,
    input  logic signed [31:0] rad_in, 
    
    output logic        valid_out,
    output logic signed [15:0] sin_out,
    output logic signed [15:0] cos_out,
    output logic        ready 
);

    // CORDIC Constants


    // Constants
    localparam signed [15:0] CORDIC_1K = 16'd9949; // 0x26DD
    
    // PI Constants in S14 format 
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

    // Pipeline Registers
    // Stage 0: Input Latch (Pure Register to break timing from FIFO)
    // Stage 1: Pre-calc 1 (+/- 2PI)
    // Stage 2: Pre-calc 2 (+/- PI)
    // Stage 3-18: 16 iterations
    // Stage 19: Output
    
    logic signed [31:0] z_pipe [0:18];
    logic signed [15:0] x_pipe [0:18];
    logic signed [15:0] y_pipe [0:18];
    logic valid_pipe [0:18];
    
    // -------------------------------------------------------------------------
    // Stage 0: Input Latch (Pure Register)
    // -------------------------------------------------------------------------
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            valid_pipe[0] <= 1'b0;
            z_pipe[0]     <= '0;
            x_pipe[0]     <= '0; 
            y_pipe[0]     <= '0; 
        end else begin
            if (valid_in) begin
                valid_pipe[0] <= 1'b1;
                z_pipe[0]     <= rad_in; // Direct latch, no logic
            end else begin
                valid_pipe[0] <= 1'b0;
            end
        end
    end
    
    // -------------------------------------------------------------------------
    // Stage 1: Pre-calc 1 (+/- 2PI)
    // -------------------------------------------------------------------------
    logic signed [31:0] z_mid_0;
    
    always_comb begin
        z_mid_0 = z_pipe[0];
        if (z_mid_0 > PI)       z_mid_0 = z_mid_0 - TWO_PI;
        else if (z_mid_0 < -PI) z_mid_0 = z_mid_0 + TWO_PI;
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            valid_pipe[1] <= 1'b0;
            z_pipe[1]     <= '0;
            x_pipe[1]     <= '0; 
            y_pipe[1]     <= '0; 
        end else begin
            valid_pipe[1] <= valid_pipe[0];
            if (valid_pipe[0]) begin
                z_pipe[1]     <= z_mid_0;
                x_pipe[1]     <= x_pipe[0]; // pass through
                y_pipe[1]     <= y_pipe[0]; // pass through
            end
        end
    end

    // -------------------------------------------------------------------------
    // Stage 2: Range Reduction 2 (+/- PI) & Coordinate Initialization
    // -------------------------------------------------------------------------
    logic signed [31:0] z_temp_1;
    logic signed [15:0] x_init_1, y_init_1;
    logic signed [31:0] z_next_1;

    always_comb begin
        z_temp_1 = z_pipe[1];
        if (z_temp_1 > HALF_PI) begin
            z_next_1 = z_temp_1 - PI;
            x_init_1 = -CORDIC_1K;
            y_init_1 = 0; 
        end else if (z_temp_1 < -HALF_PI) begin
            z_next_1 = z_temp_1 + PI;
            x_init_1 = -CORDIC_1K;
            y_init_1 = 0;
        end else begin
            z_next_1 = z_temp_1;
            x_init_1 = CORDIC_1K;
            y_init_1 = 0;
        end
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            valid_pipe[2] <= 1'b0;
            z_pipe[2]     <= '0;
            x_pipe[2]     <= '0;
            y_pipe[2]     <= '0;
        end else begin
            valid_pipe[2] <= valid_pipe[1];
            if (valid_pipe[1]) begin
                x_pipe[2] <= x_init_1;
                y_pipe[2] <= y_init_1;
                z_pipe[2] <= z_next_1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Stages 3 to 18: 16 CORDIC Iterations
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : loop_stages
            // Instantiate CORDIC Stage
            cordic_stage #(
                .SHIFT(i),
                .WIDTH(16)
            ) inst (
                .clock    (clock),
                .reset    (reset),
                .valid_in (valid_pipe[i+2]),
                .x_in     (x_pipe[i+2]),
                .y_in     (y_pipe[i+2]),
                .z_in     (z_pipe[i+2]),
                
                .valid_out(valid_pipe[i+3]),
                .x_out    (x_pipe[i+3]),
                .y_out    (y_pipe[i+3]),
                .z_out    (z_pipe[i+3])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Output Logic
    // -------------------------------------------------------------------------
    // The result is available at stage 18 (index 18 in pipe)
    // Iteration 15 writes to pipe[18]
    
    assign valid_out = valid_pipe[18];
    assign cos_out   = x_pipe[18];
    assign sin_out   = y_pipe[18];
    
    // In a pipelined design, we are always ready to accept new input 
    assign ready = 1'b1; 

endmodule
