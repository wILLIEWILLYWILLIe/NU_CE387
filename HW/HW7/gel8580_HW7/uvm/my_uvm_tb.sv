
`timescale 1ns/10ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import my_uvm_pkg::*;

module my_uvm_tb;

    logic clock;
    logic reset;

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // rst_n: active-low reset
    // Start deasserted (reset=0 → rst_n=0), then assert after some time
    initial begin
        reset = 0;  // rst_n = 0 → DUT in reset
        #100;
        reset = 1;  // rst_n = 1 → DUT active
    end

    // Interface
    fft_if vif(clock, reset);

    // DUT
    fft_top dut (
        .clk(vif.clock),
        .rst_n(vif.reset),
        
        .wr_en(vif.wr_en),
        .real_in(vif.real_in),
        .imag_in(vif.imag_in),
        .in_full(vif.in_full),
        
        .rd_en(vif.rd_en),
        .real_out(vif.real_out),
        .imag_out(vif.imag_out),
        .out_empty(vif.out_empty)
    );

    initial begin
        uvm_config_db#(virtual fft_if)::set(uvm_root::get(), "*", "vif", vif);
        run_test("my_uvm_test");
    end

endmodule
