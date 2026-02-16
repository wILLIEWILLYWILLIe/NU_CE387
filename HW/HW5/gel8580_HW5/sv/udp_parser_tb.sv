`timescale 1ns/1ps

module udp_parser_tb;

    // Parameters
    parameter CLOCK_PERIOD = 10; // 100 MHz
    parameter INPUT_PCAP_FILE = "../ref/test.pcap";
    parameter GOLDEN_REF_FILE = "../ref/test_output.txt";
    parameter OUTPUT_FILE = "../out/test_sv_output.txt";

    // Signals
    logic clock;
    logic reset;
    
    // Input Interface
    logic        din_wr_en;
    logic [7:0]  din;
    logic        din_sof;
    logic        din_eof;
    logic        din_full;
    
    // Output Interface
    logic        dout_rd_en;
    logic [7:0]  dout;
    logic        dout_sof;
    logic        dout_eof;
    logic        dout_empty;

    // File Handles
    int pcap_fd;
    int ref_fd;
    int out_fd;
    int code;
    
    // Counters and Status
    int error_count = 0;
    int byte_count  = 0;
    int cycle_count = 0;
    logic simulation_done = 0;

    // DUT Instantiation
    udp_parser_top dut (
        .clock(clock),
        .reset(reset),
        
        .din_wr_en(din_wr_en),
        .din(din),
        .din_sof(din_sof),
        .din_eof(din_eof),
        .din_full(din_full),
        
        .dout_rd_en(dout_rd_en),
        .dout(dout),
        .dout_sof(dout_sof),
        .dout_eof(dout_eof),
        .dout_empty(dout_empty)
    );

    // Clock Generation
    initial begin
        clock = 0;
        forever #(CLOCK_PERIOD/2) clock = ~clock;
    end

    // Cycle Counter
    always @(posedge clock) begin
        if (!reset) cycle_count++;
    end

    // Driver Process (Read PCAP -> Drive DUT)
    initial begin
        logic [7:0] global_header [0:23];
        logic [7:0] pkt_header [0:15];
        logic [7:0] pkt_data [];
        logic [31:0] pkt_len;
        int i;

        // Initialize Inputs
        din_wr_en = 0;
        din       = 0;
        din_sof   = 0;
        din_eof   = 0;
        reset     = 1;

        // Open PCAP file
        pcap_fd = $fopen(INPUT_PCAP_FILE, "rb");
        if (pcap_fd == 0) begin
            $display("Error: Could not open %s", INPUT_PCAP_FILE);
            $finish;
        end

        // Reset Sequence
        repeat (10) @(posedge clock);
        reset = 0;
        repeat (10) @(posedge clock);

        // Read and Skip Global Header (24 bytes)
        code = $fread(global_header, pcap_fd);
        if (code != 24) begin
            $display("Error: Failed to read PCAP global header");
            $finish;
        end

        // Packet Loop
        while (!$feof(pcap_fd)) begin
            // Read Packet Header (16 bytes)
            code = $fread(pkt_header, pcap_fd);
            if (code == 0) break; // End of file
            if (code != 16) begin
                $display("Warning: Incomplete packet header at end of file");
                break;
            end

            // Extract Packet Length (incl_len at offset 8, 4 bytes, Little Endian)
            pkt_len = {pkt_header[11], pkt_header[10], pkt_header[9], pkt_header[8]};
            
            // Allocate dynamic array for packet data
            pkt_data = new[pkt_len];
            
            // Read Packet Data
            code = $fread(pkt_data, pcap_fd, 0, pkt_len);
            if (code != pkt_len) begin
                $display("Error: Failed to read full packet data. Expected %0d, got %0d", pkt_len, code);
                break;
            end

            // Drive Packet into DUT (drive on negedge, sample on posedge)
            for (i = 0; i < pkt_len; i++) begin
                while (din_full) @(posedge clock);

                @(negedge clock);
                din_wr_en = 1'b1;
                din       = pkt_data[i];
                din_sof   = (i == 0);
                din_eof   = (i == (pkt_len - 1));
            end

            @(negedge clock);
            din_wr_en = 1'b0;
            din_sof   = 1'b0;
            din_eof   = 1'b0;

            // Inter-packet gap
            repeat(5) @(posedge clock);
        end

        $fclose(pcap_fd);
        
        // Wait for DUT to drain
        repeat(1000) @(posedge clock);
        simulation_done = 1;
    end

    // Monitor/Checker Process (Read DUT Output -> Compare with Reference)
    initial begin
        int char_code;
        logic [7:0] expected_byte;

        // Open Reference Output File
        ref_fd = $fopen(GOLDEN_REF_FILE, "rb");
        if (ref_fd == 0) begin
            $display("Error: Could not open %s", GOLDEN_REF_FILE);
            $finish;
        end

        // Open Output File for Writing
        out_fd = $fopen(OUTPUT_FILE, "wb");
        if (out_fd == 0) begin
            $display("Error: Could not open %s for writing", OUTPUT_FILE);
            $finish;
        end

        dout_rd_en = 0;

        wait (reset == 0);

        forever begin
            // Decide rd_en BEFORE posedge so FIFO/ctrl can pop correctly at posedge
            @(negedge clock);
            if (!dout_empty) dout_rd_en = 1'b1;
            else             dout_rd_en = 1'b0;

            // Sample/compare at posedge
            @(posedge clock);

            if (dout_rd_en) begin
                // Write DUT output byte
                $fwrite(out_fd, "%c", dout);

                // Read expected byte
                char_code = $fgetc(ref_fd);
                if (char_code == -1) begin
                    $display("Error: DUT output more data than reference file!");
                    error_count++;
                end else begin
                    expected_byte = char_code[7:0];
                    byte_count++;

                    if (dout !== expected_byte) begin
                        // Optional: detailed print
                        // $display("Mismatch at byte %0d: expected=0x%02h got=0x%02h", byte_count, expected_byte, dout);
                        error_count++;
                    end
                end
            end

            if (simulation_done && dout_empty) begin
                // Check if reference has remaining bytes
                char_code = $fgetc(ref_fd);
                if (char_code != -1) begin
                    $display("Error: DUT output fewer bytes than reference file!");
                    error_count++;
                end

                if (error_count == 0) begin
                    $display("========================================");
                    $display("SIMULATION PASSED");
                    $display("Total Bytes Processed: %0d", byte_count);
                    $display("Total Cycles: %0d", cycle_count);
                    $display("========================================");
                end else begin
                    $display("========================================");
                    $display("SIMULATION FAILED");
                    $display("Total Errors: %0d", error_count);
                    $display("Total Cycles: %0d", cycle_count);
                    $display("========================================");
                end

                $fclose(ref_fd);
                $fclose(out_fd);
                $stop;
            end
        end
    end

endmodule