
`timescale 1ns/1ps

module edge_detect_tb;

    // Parameters
    localparam string IMG_IN_NAME  = "../images/copper_720_540.bmp";
    localparam string IMG_OUT_NAME = "../out/output_tb.bmp";
    localparam string IMG_CMP_NAME = "../ref_images/copper_stage2_sobel.bmp";
    localparam int IMG_WIDTH = 720;
    localparam int IMG_HEIGHT = 540;
    localparam int BMP_HEADER_SIZE = 54;
    localparam int BYTES_PER_PIXEL = 3;
    localparam int CLOCK_PERIOD = 10;

    // Signals
    logic clock = 0;
    logic reset;
    logic in_wr_en;
    logic [23:0] in_din;
    logic in_full;
    logic out_rd_en;
    logic [7:0] out_dout;
    logic out_empty;

    // File Handles
    int in_file, out_file, cmp_file;
    int i, n_bytes;
    logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];
    logic [23:0] pixel_data;
    logic [7:0] out_pixel;
    logic [7:0] cmp_pixel;
    logic [7:0] dummy_byte;
    int error_count = 0;
    int cycle_count = 0;
    logic simulation_done = 0;

    // DUT Instantiation
    edge_detect_top #(
        .WIDTH(IMG_WIDTH),
        .HEIGHT(IMG_HEIGHT)
    ) dut (
        .clock(clock),
        .reset(reset),
        .in_wr_en(in_wr_en),
        .in_din(in_din),
        .in_full(in_full),
        .out_rd_en_in(out_rd_en),
        .out_dout(out_dout),
        .out_empty(out_empty),
        .out_rd_en() // Unconnected monitor port
    );

    // Clock Generation
    always #(CLOCK_PERIOD/2) clock = ~clock;

    // Cycle Counter
    always @(posedge clock) begin
        if (reset) begin
            cycle_count <= 0;
        end else if (!simulation_done) begin
            cycle_count <= cycle_count + 1;
        end
    end

    // Main Test Process
    initial begin
        // Initialize
        reset = 1;
        in_wr_en = 0;
        in_din = 0;
        out_rd_en = 0;

        // Open Files
        in_file = $fopen(IMG_IN_NAME, "rb");
        if (!in_file) begin
            $display("Error: Could not open input file %s", IMG_IN_NAME);
            $finish;
        end

        out_file = $fopen(IMG_OUT_NAME, "wb");
        if (!out_file) begin
            $display("Error: Could not open output file %s", IMG_OUT_NAME);
            $finish;
        end

        cmp_file = $fopen(IMG_CMP_NAME, "rb");
        if (!cmp_file) begin
            $display("Warning: Could not open compare file %s", IMG_CMP_NAME);
        end

        // Read and Write Header
        n_bytes = $fread(bmp_header, in_file, 0, BMP_HEADER_SIZE);
        for (i = 0; i < BMP_HEADER_SIZE; i++) begin
            $fwrite(out_file, "%c", bmp_header[i]);
        end
        // If compare file exists, skip its header
        if (cmp_file) begin
            void'($fseek(cmp_file, BMP_HEADER_SIZE, 0));
        end

        // Reset Sequence
        #(CLOCK_PERIOD * 10);
        reset = 0;
        #(CLOCK_PERIOD * 10);

        $display("Simulation Started...");

        // Fork processes
        fork
            // Process 1: Feed Input
            begin
                while (!$feof(in_file)) begin
                    @(negedge clock);
                    if (!in_full) begin
                        // HW3 Style Read
                        n_bytes = $fread(pixel_data, in_file);
                        if (n_bytes == BYTES_PER_PIXEL) begin
                            in_wr_en = 1;
                            in_din = pixel_data;
                        end else begin
                            in_wr_en = 0;
                        end
                    end else begin
                        in_wr_en = 0;
                    end
                end
                in_wr_en = 0;
                $display("Finished writing input data.");
            end

            // Process 2: Read Output
            begin
                int out_cnt = 0;
                while (out_cnt < IMG_WIDTH * IMG_HEIGHT) begin
                    @(negedge clock);
                    if (!out_empty) begin
                        // FWFT FIFO Read Logic
                        out_pixel = out_dout;
                        out_rd_en = 1;
                        
                        // Write to file
                        $fwrite(out_file, "%c%c%c", out_pixel, out_pixel, out_pixel);

                        // Compare
                        if (cmp_file) begin
                            n_bytes = $fread(cmp_pixel, cmp_file); // Read Blue
                            // Skip G, R
                            void'($fread(dummy_byte, cmp_file));
                            void'($fread(dummy_byte, cmp_file));
                            
                            if (out_pixel !== cmp_pixel) begin
                                if (error_count < 10) begin
                                    $display("Mismatch at pixel %0d: Expected %h, Got %h", out_cnt, cmp_pixel, out_pixel);
                                end
                                error_count++;
                            end
                        end
                        out_cnt++;
                    end else begin
                        out_rd_en = 0;
                    end
                end
                simulation_done = 1;
                $display("Finished reading output data. Total Errors: %0d", error_count);
                $display("Total Clock Cycles: %0d", cycle_count);
            end
        join

        $fclose(in_file);
        $fclose(out_file);
        if (cmp_file) $fclose(cmp_file);
        
        $display("Simulation Finished.");
        $finish;
    end

endmodule
