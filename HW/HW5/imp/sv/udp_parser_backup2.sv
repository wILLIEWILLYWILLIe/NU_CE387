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
        PAYLOAD_START,
        PAYLOAD,
        DRAIN
    } state_t;

    state_t state, state_c;
    
    logic [15:0] byte_cnt, byte_cnt_c;
    logic [15:0] eth_type, eth_type_c;
    logic [7:0]  ip_proto, ip_proto_c;
    logic [15:0] udp_len, udp_len_c;
    
    // Debug counters
    logic [31:0] total_writes, total_writes_c;
    logic [31:0] total_reads, total_reads_c;
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_cnt <= 0;
            eth_type <= 0;
            ip_proto <= 0;
            udp_len <= 0;
            total_writes <= 0;
            total_reads <= 0;
        end else begin
            state <= state_c;
            byte_cnt <= byte_cnt_c;
            eth_type <= eth_type_c;
            ip_proto <= ip_proto_c;
            udp_len <= udp_len_c;
            total_writes <= total_writes_c;
            total_reads <= total_reads_c;
        end
    end

    always_comb begin
        in_rd_en = 1'b0;
        out_wr_en = 1'b0;
        out_din = in_dout; 
        out_sof = 1'b0;
        out_eof = 1'b0;
        
        state_c = state;
        byte_cnt_c = byte_cnt;
        eth_type_c = eth_type;
        ip_proto_c = ip_proto;
        udp_len_c = udp_len;
        total_writes_c = total_writes;
        total_reads_c = total_reads;

        case (state)
            IDLE: begin
                if (!in_empty) begin
                    if (in_sof) begin
                        byte_cnt_c = 0; 
                        state_c = ETH_HDR;
                    end else begin
                        in_rd_en = 1'b1;
                    end
                end
            end

            ETH_HDR: begin
                if (!in_empty) begin
                    if (byte_cnt == 12) eth_type_c[15:8] = in_dout;
                    if (byte_cnt == 13) eth_type_c[7:0] = in_dout;
                    
                    in_rd_en = 1'b1;
                    byte_cnt_c = byte_cnt + 1;
                    
                    if (byte_cnt == 13) begin 
                        byte_cnt_c = 0;
                        state_c = ETH_CHK;
                    end
                end
            end

            ETH_CHK: begin
                if (eth_type == 16'h0800) begin
                    state_c = IP_HDR;
                end else begin
                    state_c = DRAIN;
                end
            end

            IP_HDR: begin
                if (!in_empty) begin
                    if (byte_cnt == 9) ip_proto_c = in_dout;
                    
                    in_rd_en = 1'b1;
                    byte_cnt_c = byte_cnt + 1;
                    
                    if (byte_cnt == 19) begin
                        byte_cnt_c = 0;
                        state_c = IP_CHK;
                    end
                end
            end

            IP_CHK: begin
                if (ip_proto == 8'h11) begin
                    state_c = UDP_HDR;
                end else begin
                    state_c = DRAIN;
                end
            end

            UDP_HDR: begin
                if (!in_empty) begin
                    if (byte_cnt == 4) udp_len_c[15:8] = in_dout;
                    if (byte_cnt == 5) udp_len_c[7:0] = in_dout;
                    
                    if (byte_cnt < 7) begin
                        in_rd_en = 1'b1;
                        total_reads_c = total_reads + 1;
                        byte_cnt_c = byte_cnt + 1;
                    end else begin
                        // byte_cnt == 7
                        $display("Time=%0t UDP_HDR byte 7: udp_len=%0d, in_dout=0x%02h, total_reads=%0d", 
                                 $time, udp_len_c, in_dout, total_reads);
                        
                        if (udp_len_c <= 8) begin
                            in_rd_en = 1'b1;
                            total_reads_c = total_reads + 1;
                            if (in_eof) state_c = IDLE;
                            else state_c = DRAIN;
                        end else begin
                            byte_cnt_c = 0;
                            state_c = PAYLOAD_START;
                        end
                    end
                end
            end

            PAYLOAD_START: begin
                if (!in_empty) begin
                    $display("Time=%0t PAYLOAD_START: in_dout=0x%02h ('%c'), total_reads=%0d, issuing rd_en", 
                             $time, in_dout, in_dout, total_reads);
                    in_rd_en = 1'b1;
                    total_reads_c = total_reads + 1;
                    state_c = PAYLOAD;
                end
            end

            PAYLOAD: begin
                if (!in_empty && !out_full) begin
                    out_wr_en = 1'b1;
                    out_din = in_dout;
                    
                    if (byte_cnt == 0) out_sof = 1'b1;
                    
                    // Debug print for critical positions
                    if ((total_writes >= 0 && total_writes < 5) ||
                        (total_writes >= 1020 && total_writes < 1028) ||
                        (total_writes >= 2044 && total_writes < 2052) ||
                        (total_writes >= 3068 && total_writes < 3076)) begin
                        $display("Time=%0t PAYLOAD write[%0d]: byte_cnt=%0d, data=0x%02h ('%c'), udp_len=%0d, payload_left=%0d, total_reads=%0d", 
                                 $time, total_writes, byte_cnt, in_dout, in_dout, udp_len, 
                                 (udp_len - 16'd8 - byte_cnt - 1), total_reads);
                    end
                    
                    total_writes_c = total_writes + 1;
                    byte_cnt_c = byte_cnt + 1;
                    
                    if (byte_cnt + 1 == (udp_len - 16'd8)) begin
                        $display("Time=%0t PAYLOAD END: wrote %0d bytes (expected %0d), setting EOF, total_writes=%0d, total_reads=%0d", 
                                 $time, byte_cnt + 1, udp_len - 8, total_writes + 1, total_reads);
                        out_eof = 1'b1;
                        
                        if (in_eof) begin
                            state_c = IDLE;
                        end else begin
                            in_rd_en = 1'b1;
                            total_reads_c = total_reads + 1;
                            state_c = DRAIN;
                        end
                    end else if (in_eof) begin
                        out_eof = 1'b1;
                        state_c = IDLE;
                    end else begin
                        in_rd_en = 1'b1;
                        total_reads_c = total_reads + 1;
                    end
                end
            end
            
            DRAIN: begin
                if (!in_empty) begin
                    in_rd_en = 1'b1;
                    total_reads_c = total_reads + 1;
                    if (in_eof) begin
                        state_c = IDLE;
                    end
                end
            end

            default: state_c = IDLE;
        endcase
    end

endmodule