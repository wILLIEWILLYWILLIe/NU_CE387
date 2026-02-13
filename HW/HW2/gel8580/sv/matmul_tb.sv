`timescale 1 ns / 1 ns

module matmul_tb ();

    localparam string A_NAME = "x.txt"; // Using x.txt from C code as Matrix A
    localparam string B_NAME = "y.txt"; // Using y.txt from C code as Matrix B
    localparam string C_NAME = "z.txt"; // Using z.txt from C code as Golden Matrix C
    
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 10;
    localparam MATRIX_SIZE = 8;
    localparam MEM_SIZE = MATRIX_SIZE * MATRIX_SIZE; // 64
    localparam CLOCK_PERIOD = 10;

    logic clock = 1'b0;
    logic reset = 1'b0;
    logic start = 1'b0;
    logic done;

    // Interface for TB to write A
    logic [DATA_WIDTH-1:0] a_wr_din;
    logic [ADDR_WIDTH-1:0] a_wr_addr;
    logic a_wr_en;

    // Interface for TB to write B
    logic [DATA_WIDTH-1:0] b_wr_din;
    logic [ADDR_WIDTH-1:0] b_wr_addr;
    logic b_wr_en;

    // Interface for TB to read C
    logic [DATA_WIDTH-1:0] c_rd_dout;
    logic [ADDR_WIDTH-1:0] c_rd_addr;

    logic   a_write_done = '0;
    logic   b_write_done = '0;
    logic   c_read_done  = '0;
    integer c_errors     = '0;

    matmul_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dut (
        .clock(clock),
        .reset(reset),
        .start(start),
        .done(done),
        .a_wr_din(a_wr_din),
        .a_wr_addr(a_wr_addr),
        .a_wr_en(a_wr_en),
        .b_wr_din(b_wr_din),
        .b_wr_addr(b_wr_addr),
        .b_wr_en(b_wr_en),
        .c_rd_dout(c_rd_dout),
        .c_rd_addr(c_rd_addr)
    );

    // Clock process
    always begin
        #(CLOCK_PERIOD/2) clock = 1'b1;
        #(CLOCK_PERIOD/2) clock = 1'b0;
    end

    // Reset process
    initial begin
        #(CLOCK_PERIOD) reset = 1'b1;
        #(CLOCK_PERIOD) reset = 1'b0;
    end

    // Main Test Process
    initial begin
        time start_time, end_time;

        @(negedge reset);
        wait(a_write_done && b_write_done);
        @(posedge clock);
        start_time = $time;
        $display("@ %0t: Beginning simulation...", start_time);

        @(posedge clock);
        start = 1'b1;
        @(posedge clock);
        start = 1'b0;
        
        wait(done);

        end_time = $time;
        $display("@ %0t: Simulation completed.", end_time);
        
        // Trigger verification
        wait(c_read_done);
        
        $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
        $display("Total error count: %0d", c_errors);
        
        if (c_errors == 0)
            $display("SUCCESS: Simulation passed!");
        else
            $display("FAILURE: Found %0d errors.", c_errors);

        $stop;
    end

    // Process to write Matrix A (x.txt)
    initial begin : a_write
        integer fd, i, count;
        logic [DATA_WIDTH-1:0] val;
        a_wr_addr = '0;
        a_wr_en = 1'b0;

        @(negedge reset);
        $display("@ %0t: Loading file %s into BRAM A...", $time, A_NAME);
        
        fd = $fopen(A_NAME, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", A_NAME);
            $stop;
        end

        for (i = 0; i < MEM_SIZE; i++) begin
            @(posedge clock);
            count = $fscanf(fd, "%h", val);
            a_wr_din = val;
            a_wr_addr = i;
            a_wr_en = 1'b1;
        end

        @(posedge clock);
        a_wr_en = 1'b0;
        $fclose(fd);
        a_write_done = 1'b1;
    end

    // Process to write Matrix B (y.txt)
    initial begin : b_write
        integer fd, i, count;
        logic [DATA_WIDTH-1:0] val;
        b_wr_addr = '0;
        b_wr_en = 1'b0;
        
        @(negedge reset);
        $display("@ %0t: Loading file %s into BRAM B...", $time, B_NAME);
        
        fd = $fopen(B_NAME, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", B_NAME);
            $stop;
        end

        for (i = 0; i < MEM_SIZE; i++) begin
            @(posedge clock);
            count = $fscanf(fd, "%h", val);
            b_wr_din = val;
            b_wr_addr = i;
            b_wr_en = 1'b1;
        end

        @(posedge clock);
        b_wr_en = 1'b0;
        $fclose(fd);
        b_write_done = 1'b1;
    end

    // Process to verify Matrix C (z.txt)
    initial begin : c_verify
        integer fd, i, count;
        logic [DATA_WIDTH-1:0] expected_val, read_val;
        c_rd_addr = '0;

        @(negedge reset);
        wait(done);
        @(negedge clock);

        $display("@ %0t: Verifying results against %s...", $time, C_NAME);
        
        fd = $fopen(C_NAME, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", C_NAME);
            $stop;
        end

        for (i = 0; i < MEM_SIZE; i++) begin
            // Setup read address
            @(negedge clock); 
            c_rd_addr = i;
            
            // Wait for read latency (1 cycle)
            @(negedge clock);
            
            // Read value and compare
            count = $fscanf(fd, "%h", expected_val);
            read_val = c_rd_dout;
            
            if (read_val !== expected_val) begin
                c_errors++;
                $display("ERROR at index %0d: Expected %h, Got %h", i, expected_val, read_val);
            end
            
            @(posedge clock);
        end
        $fclose(fd);
        c_read_done = 1'b1;
    end

endmodule
