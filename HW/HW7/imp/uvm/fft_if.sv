
`ifndef FFT_IF_SV
`define FFT_IF_SV

interface fft_if(input logic clock, input logic reset);
    parameter int DATA_WIDTH = 16;

    // Input FIFO
    logic wr_en;
    logic signed [DATA_WIDTH-1:0] real_in;
    logic signed [DATA_WIDTH-1:0] imag_in;
    logic in_full;

    // Output FIFO
    logic rd_en;
    logic signed [DATA_WIDTH-1:0] real_out;
    logic signed [DATA_WIDTH-1:0] imag_out;
    logic out_empty;

    modport driver (
        input  clock, reset,
        output wr_en, real_in, imag_in,
        input  in_full
    );

    modport monitor (
        input  clock, reset,
        input  wr_en, real_in, imag_in, in_full,
        output rd_en,
        input  real_out, imag_out, out_empty
    );

endinterface

`endif
