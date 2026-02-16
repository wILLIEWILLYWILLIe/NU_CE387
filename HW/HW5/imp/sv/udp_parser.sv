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
        UDP_DONE,
        PAYLOAD,
        DRAIN
    } state_t;

    state_t state, state_c;
    
    logic [15:0] byte_cnt, byte_cnt_c;
    logic [15:0] eth_type, eth_type_c;
    logic [7:0]  ip_proto, ip_proto_c;
    logic [15:0] udp_len, udp_len_c;
    
    // Debug counters
    logic [31:0] global_payload_cnt, global_payload_cnt_c;
    logic [31:0] actual_writes, actual_writes_c;

    // Debug controls (English only)
    localparam bit DEBUG = 1'b0;
    function automatic bit dbg_zone(input logic [31:0] w);
        return (w < 32'd8) ||
               (w >= 32'd1018 && w < 32'd1032) ||
               (w >= 32'd2042 && w < 32'd2056) ||
               (w >= 32'd3066 && w < 32'd3080);
    endfunction

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_cnt <= 16'd0;
            eth_type <= 16'd0;
            ip_proto <= 8'd0;
            udp_len <= 16'd0;
            global_payload_cnt <= 32'd0;
            actual_writes <= 32'd0;
        end else begin
            state <= state_c;
            byte_cnt <= byte_cnt_c;
            eth_type <= eth_type_c;
            ip_proto <= ip_proto_c;
            udp_len <= udp_len_c;
            global_payload_cnt <= global_payload_cnt_c;
            actual_writes <= actual_writes_c;
        end
    end

    always_comb begin
        // defaults
        in_rd_en  = 1'b0;
        out_wr_en = 1'b0;
        out_din   = in_dout;
        out_sof   = 1'b0;
        out_eof   = 1'b0;
        
        state_c              = state;
        byte_cnt_c           = byte_cnt;
        eth_type_c           = eth_type;
        ip_proto_c           = ip_proto;
        udp_len_c            = udp_len;
        global_payload_cnt_c = global_payload_cnt;
        actual_writes_c      = actual_writes;

        case (state)
            IDLE: begin
                if (!in_empty) begin
                    if (in_sof) begin
                        byte_cnt_c = 16'd0; 
                        state_c    = ETH_HDR;
                    end else begin
                        // discard until sof
                        in_rd_en = 1'b1;
                    end
                end
            end

            // Ethernet header: 14 bytes (type at bytes 12..13)
            ETH_HDR: begin
                if (!in_empty) begin
                    if (byte_cnt == 16'd12) eth_type_c[15:8] = in_dout;
                    if (byte_cnt == 16'd13) eth_type_c[7:0]  = in_dout;
                    
                    in_rd_en   = 1'b1;
                    byte_cnt_c = byte_cnt + 16'd1;
                    
                    if (byte_cnt == 16'd13) begin 
                        byte_cnt_c = 16'd0;
                        state_c    = ETH_CHK;
                    end
                end
            end

            ETH_CHK: begin
                if (eth_type == 16'h0800) state_c = IP_HDR;
                else                      state_c = DRAIN;
            end

            // IPv4 fixed header assumed 20 bytes (protocol at byte 9)
            IP_HDR: begin
                if (!in_empty) begin
                    if (byte_cnt == 16'd9) ip_proto_c = in_dout;
                    
                    in_rd_en   = 1'b1;
                    byte_cnt_c = byte_cnt + 16'd1;
                    
                    if (byte_cnt == 16'd19) begin
                        byte_cnt_c = 16'd0;
                        state_c    = IP_CHK;
                    end
                end
            end

            IP_CHK: begin
                if (ip_proto == 8'h11) state_c = UDP_HDR;
                else                   state_c = DRAIN;
            end

            // UDP header 8 bytes (length at bytes 4..5)
            UDP_HDR: begin
                if (!in_empty) begin
                    if (byte_cnt == 16'd4) udp_len_c[15:8] = in_dout;
                    if (byte_cnt == 16'd5) udp_len_c[7:0]  = in_dout;

                    in_rd_en   = 1'b1;
                    byte_cnt_c = byte_cnt + 16'd1;
                    
                    if (byte_cnt == 16'd7) begin
                        if (DEBUG) begin
                            $display("UDP_HDR: udp_len=%0d payload_len=%0d global=%0d writes=%0d time=%0t",
                                     udp_len_c,
                                     (udp_len_c >= 16'd8) ? (udp_len_c - 16'd8) : 16'd0,
                                     global_payload_cnt, actual_writes, $time);
                        end

                        if (udp_len_c <= 16'd8) begin
                            if (in_eof) state_c = IDLE;
                            else        state_c = DRAIN;
                        end else begin
                            byte_cnt_c = 16'd0;
                            state_c    = UDP_DONE;
                        end
                    end
                end
            end

            UDP_DONE: begin
                state_c = PAYLOAD;
            end

            // Payload: NO SKIP. Output exactly (udp_len-8) bytes per packet, matching your C/reference.
            PAYLOAD: begin
                if (!in_empty && !out_full) begin
                    logic [15:0] payload_len;
                    payload_len = (udp_len >= 16'd8) ? (udp_len - 16'd8) : 16'd0;

                    if (DEBUG && dbg_zone(global_payload_cnt)) begin
                        $display("WRITE: g=%0d bc=%0d wr=%0d data=0x%02h ('%c') in_eof=%0b time=%0t",
                                 global_payload_cnt, byte_cnt, actual_writes, in_dout,
                                 (in_dout >= 8'd32 && in_dout < 8'd127) ? in_dout : 8'h2E,
                                 in_eof, $time);
                    end

                    out_wr_en = 1'b1;
                    out_din   = in_dout;

                    if (byte_cnt == 16'd0) out_sof = 1'b1;

                    // advance counters
                    byte_cnt_c           = byte_cnt + 16'd1;
                    global_payload_cnt_c = global_payload_cnt + 32'd1;
                    actual_writes_c      = actual_writes + 32'd1;

                    // end of this UDP payload?
                    if ((byte_cnt + 16'd1) >= payload_len) begin
                        out_eof = 1'b1;

                        if (DEBUG) begin
                            $display("PKT-END: wrote=%0d payload_len=%0d g_next=%0d wr_next=%0d in_eof=%0b time=%0t",
                                     (byte_cnt + 16'd1), payload_len,
                                     (global_payload_cnt + 32'd1), (actual_writes + 32'd1),
                                     in_eof, $time);
                        end

                        if (in_eof) begin
                            state_c = IDLE;
                        end else begin
                            // consume one more to reach in_eof (drain rest of frame)
                            in_rd_en = 1'b1;
                            state_c  = DRAIN;
                        end
                    end else if (in_eof) begin
                        // safety if frame ended early
                        out_eof = 1'b1;
                        if (DEBUG) $display("EARLY-EOF: frame ended early at bc=%0d g=%0d time=%0t",
                                            byte_cnt, global_payload_cnt, $time);
                        state_c = IDLE;
                    end else begin
                        // continue payload
                        in_rd_en = 1'b1;
                    end
                end
            end
            
            // Drain remaining bytes until in_eof
            DRAIN: begin
                if (!in_empty) begin
                    in_rd_en = 1'b1;
                    if (in_eof) state_c = IDLE;
                end
            end

            default: state_c = IDLE;
        endcase
    end

endmodule