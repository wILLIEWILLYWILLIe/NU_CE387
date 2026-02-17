
`ifndef CORDIC_IF_SV
`define CORDIC_IF_SV

interface cordic_if(input logic clock, input logic reset);
    logic        valid_in;
    logic signed [31:0] rad_in;
    logic        valid_out;
    logic signed [15:0] sin_out;
    logic signed [15:0] cos_out;

    clocking cb @(posedge clock);
        default input #1step output #1step;
        output valid_in, rad_in;
        input  valid_out, sin_out, cos_out;
    endclocking

    modport drv (clocking cb, input reset);
    modport mon (clocking cb, input reset);

endinterface

`endif
