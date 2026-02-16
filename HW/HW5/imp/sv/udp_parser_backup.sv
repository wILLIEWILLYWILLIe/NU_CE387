
module udp_parser (
    input  logic        clock,
    input  logic        reset,
    
    // Input Interface (from fifo_ctrl)
    output logic        in_rd_en,
    input  logic        in_empty,
    input  logic [7:0]  in_dout,
    input  logic        in_sof,
    input  logic        in_eof,
    
    // Output Interface (to fifo_ctrl)
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [7:0]  out_din,
    output logic        out_sof,
    output logic        out_eof
);

    typedef enum logic [3:0] {
        IDLE,
        ETH_HDR,
        ETH_CHK,
        IP_HDR,
        IP_CHK,
        UDP_HDR,
        PAYLOAD,
        DRAIN
    } state_t;

    state_t state, state_c;
    
    // First payload cycle: skip output (FIFO dout may have stale UDP hdr byte due to read latency)
    logic skip_first_payload, skip_first_payload_c;
    
    // Byte Counters
    logic [15:0] byte_cnt, byte_cnt_c;
    
    // Header Data Capture
    logic [15:0] eth_type, eth_type_c;
    logic [7:0]  ip_proto, ip_proto_c;
    logic [15:0] udp_len, udp_len_c;
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            skip_first_payload <= 0;
            byte_cnt <= 0;
            eth_type <= 0;
            ip_proto <= 0;
            udp_len <= 0;
        end else begin
            state <= state_c;
            skip_first_payload <= skip_first_payload_c;
            byte_cnt <= byte_cnt_c;
            eth_type <= eth_type_c;
            ip_proto <= ip_proto_c;
            udp_len <= udp_len_c;
        end
    end

    always_comb begin
        // Defaults
        in_rd_en = 1'b0;
        out_wr_en = 1'b0;
        out_din = in_dout; 
        out_sof = 1'b0;
        out_eof = 1'b0;
        
        state_c = state;
        skip_first_payload_c = skip_first_payload;
        byte_cnt_c = byte_cnt;
        eth_type_c = eth_type;
        ip_proto_c = ip_proto;
        udp_len_c = udp_len;

        case (state)
            IDLE: begin
                // Wait for SOF
                if (!in_empty) begin
                    if (in_sof) begin
                        // Found SOF, start parsing Ethernet Header
                        // in_dout already has byte 0, don't advance yet
                        byte_cnt_c = 0; 
                        state_c = ETH_HDR;
                    end else begin
                        // Flush garbage if any
                        in_rd_en = 1'b1;
                    end
                end
            end

            ETH_HDR: begin
                // Consume Ethernet Header (14 bytes total: 0-13)
                // byte_cnt starts at 0, in_dout has byte 0
                if (!in_empty) begin
                    // Capture EtherType at byte 12 and 13
                    if (byte_cnt == 12) eth_type_c[15:8] = in_dout;
                    if (byte_cnt == 13) eth_type_c[7:0] = in_dout;
                    
                    // Advance FIFO for next byte
                    in_rd_en = 1'b1;
                    byte_cnt_c = byte_cnt + 1;
                    
                    if (byte_cnt == 13) begin 
                        // Done with Ethernet, check on next cycle after register
                        byte_cnt_c = 0;
                        state_c = ETH_CHK;
                    end
                end
            end

            ETH_CHK: begin
                // Check EtherType after it's been registered
                if (eth_type == 16'h0800) begin
                    state_c = IP_HDR;
                end else begin
                    // Not IPv4, drain packet
                    state_c = DRAIN;
                end
            end

            IP_HDR: begin
                // Consume IP Header (20 bytes total)
                if (!in_empty) begin
                    // Capture Protocol at byte 9 (0-based index)
                    if (byte_cnt == 9) ip_proto_c = in_dout;
                    
                    // Advance FIFO for next byte
                    in_rd_en = 1'b1;
                    byte_cnt_c = byte_cnt + 1;
                    
                    if (byte_cnt == 19) begin
                        // Done with IP, check on next cycle
                        byte_cnt_c = 0;
                        state_c = IP_CHK;
                    end
                end
            end

            IP_CHK: begin
                // Check Protocol after it's been registered
                if (ip_proto == 8'h11) begin
                    state_c = UDP_HDR;
                end else begin
                    // Not UDP, drain packet
                    state_c = DRAIN;
                end
            end

            UDP_HDR: begin
                // Consume UDP Header (8 bytes total)
                if (!in_empty) begin
                    // Capture Length at byte 4 and 5 (0-based index)
                    if (byte_cnt == 4) udp_len_c[15:8] = in_dout;
                    if (byte_cnt == 5) udp_len_c[7:0] = in_dout;

                    // Advance FIFO for next byte
                    in_rd_en = 1'b1;
                    byte_cnt_c = byte_cnt + 1;
                    
                    if (byte_cnt == 7) begin
                        // Done with UDP Header
                        $display("UDP Parser: UDP Length = %0d", udp_len_c);
                        
                        // Check for Empty Payload
                        if (udp_len_c <= 8) begin
                            if (in_eof) state_c = IDLE;
                            else state_c = DRAIN;
                        end else begin
                            byte_cnt_c = 0;
                            skip_first_payload_c = 1'b1;  // Skip first output (FIFO latency)
                            state_c = PAYLOAD;
                        end
                    end
                end
            end

            PAYLOAD: begin
                // Output Payload Data
                // skip_first_payload: in_dout may have stale UDP hdr byte (FIFO 1-cycle read latency)
                if (!in_empty) begin
                    if (skip_first_payload) begin
                        // Consume stale byte, don't output
                        in_rd_en = 1'b1;
                        skip_first_payload_c = 1'b0;
                    end else if (!out_full) begin
                        out_wr_en = 1'b1;
                        out_din = in_dout;
                        in_rd_en = 1'b1;
                        if (byte_cnt == 0) out_sof = 1'b1;
                        byte_cnt_c = byte_cnt + 1;
                        if (in_eof) begin
                            out_eof = 1'b1;
                            state_c = IDLE;
                        end else if (byte_cnt == (udp_len - 9)) begin
                            out_eof = 1'b1;
                            state_c = DRAIN;
                        end
                    end
                end
            end
            
            DRAIN: begin
                // Consume remaining padding bytes until input EOF
                if (!in_empty) begin
                    in_rd_en = 1'b1;
                    if (in_eof) begin
                        state_c = IDLE;
                    end
                end
            end

            default: state_c = IDLE;
        endcase
    end

endmodule
