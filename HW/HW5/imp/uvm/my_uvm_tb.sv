
`include "uvm_macros.svh"
`include "my_uvm_pkg.sv"
`include "udp_parser_if.sv"

module my_uvm_tb;
    import uvm_pkg::*;
    import my_uvm_pkg::*;

    logic clock;
    logic reset;

    udp_parser_if vif(clock, reset);

    udp_parser_top dut (
        .clock(clock),
        .reset(reset),
        
        .din_wr_en(vif.din_wr_en),
        .din(vif.din),
        .din_sof(vif.din_sof),
        .din_eof(vif.din_eof),
        .din_full(vif.din_full),
        
        .dout_rd_en(vif.dout_rd_en),
        .dout(vif.dout),
        .dout_sof(vif.dout_sof),
        .dout_eof(vif.dout_eof),
        .dout_empty(vif.dout_empty)
    );

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    initial begin
        reset = 1;
        #100;
        reset = 0;
    end

    initial begin
        uvm_config_db#(virtual udp_parser_if)::set(null, "*", "vif", vif);
        run_test("my_uvm_test");
    end

endmodule
