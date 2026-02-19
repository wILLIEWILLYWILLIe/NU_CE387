
module cordic_tb_pipe;

    logic        clock;
    logic        reset;
    logic        valid_in;
    logic signed [31:0] rad_in;
    logic        valid_out;
    logic signed [15:0] sin_out;
    logic signed [15:0] cos_out;
    logic        full_out; // Connected to top-level full signal

    // FIFO / Memory for verification
    logic signed [31:0] rad_queue [$];
    logic signed [15:0] sin_ref_queue [$];
    logic signed [15:0] cos_ref_queue [$];

    // File handles
    integer rad_file, sin_file, cos_file;
    integer r_scan;
    logic signed [31:0] rad_val;
    logic signed [15:0] sin_val;
    logic signed [15:0] cos_val;
    
    integer errors = 0;
    integer tests_sent = 0;
    integer tests_received = 0;
    
    // Performance metrics
    integer start_time;
    integer end_time;

    // DUT Instance
    cordic_top dut (
        .clock(clock),
        .reset(reset),
        .valid_in(valid_in),
        .rad_in(rad_in),
        .full_out(full_out), 
        .valid_out(valid_out),
        .sin_out(sin_out),
        .cos_out(cos_out)
    );

    // Clock
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Input Driver Process
    initial begin
        // Open files
        rad_file = $fopen("../source/rad.txt", "r");
        sin_file = $fopen("../source/sin.txt", "r");
        cos_file = $fopen("../source/cos.txt", "r");

        if (rad_file == 0) begin
            $display("Error: Could not open rad.txt");
            $finish;
        end

        // Reset
        reset = 1;
        valid_in = 0;
        rad_in = 0;
        repeat (10) @(posedge clock);
        reset = 0;
        repeat (5) @(posedge clock);

        $display("Starting Burst Input...");
        start_time = $time;

        while (!$feof(rad_file)) begin
            r_scan = $fscanf(rad_file, "%h\n", rad_val);
            if (r_scan != 1) break;
            
            // Read refs to push to queue
            r_scan = $fscanf(sin_file, "%h\n", sin_val);
            r_scan = $fscanf(cos_file, "%h\n", cos_val);
            
            // Wait if FIFO full (backpressure)
            while (full_out) @(posedge clock);

            // Drive Input
            valid_in <= 1;
            rad_in   <= rad_val;
            
            // Store expected results in queue for checker
            sin_ref_queue.push_back(sin_val);
            cos_ref_queue.push_back(cos_val);
            
            tests_sent++;
            @(posedge clock);
        end
        
        valid_in <= 0;
        $fclose(rad_file);
        $fclose(sin_file);
        $fclose(cos_file);
        $display("Done driving inputs. Sent %0d vectors.", tests_sent);
    end

    // Output Monitor/Checker Process
    initial begin
        wait (reset == 0);
        
        forever begin
            @(posedge clock);
            if (valid_out) begin
                logic signed [15:0] exp_sin, exp_cos;
                
                if (sin_ref_queue.size() == 0) begin
                    $display("Error: Unexpected output received!");
                    errors++;
                end else begin
                    exp_sin = sin_ref_queue.pop_front();
                    exp_cos = cos_ref_queue.pop_front();
                    
                    if (sin_out !== exp_sin || cos_out !== exp_cos) begin
                        $display("Mismatch! Cycle %0d | Got Sin/Cos: %h/%h | Exp: %h/%h", 
                                 $time/10, sin_out, cos_out, exp_sin, exp_cos);
                        errors++;
                    end
                    tests_received++;
                end
            end
            
            // Termination condition
            if (tests_received > 0 && tests_received == tests_sent && sin_ref_queue.size() == 0) begin
                end_time = $time;
                $display("-------------------------------------------");
                $display("Simulation Complete.");
                $display("Total Vectors Processed: %0d", tests_received);
                $display("Total Errors: %0d", errors);
                $display("Total Time: %0d ns", end_time - start_time);
                $display("Throughput: %0f samples/cycle", 
                         1.0 * tests_received / ((end_time - start_time)/10));
                
                if (errors == 0) $display("SUCCESS: Functionality Verified.");
                else $display("FAILURE: Errors found.");
                
                $finish;
            end
        end
    end
    
    // Timeout
    initial begin
        #1000000;
        $display("Timeout!");
        $finish;
    end

endmodule
