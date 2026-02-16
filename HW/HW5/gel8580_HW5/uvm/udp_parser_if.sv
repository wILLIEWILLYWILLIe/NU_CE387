
interface udp_parser_if(input logic clock, input logic reset);
    logic        din_wr_en;
    logic [7:0]  din;
    logic        din_sof;
    logic        din_eof;
    logic        din_full;
    
    logic        dout_rd_en;
    logic [7:0]  dout;
    logic        dout_sof;
    logic        dout_eof;
    logic        dout_empty;
endinterface
