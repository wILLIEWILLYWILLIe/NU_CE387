
`ifndef MY_UVM_GLOBALS_SV
`define MY_UVM_GLOBALS_SV

parameter string REF_REAL_IN = "../source/fft_in_real.txt";
parameter string REF_IMAG_IN = "../source/fft_in_imag.txt";
parameter string REF_REAL_OUT = "../source/fft_out_real.txt";
parameter string REF_IMAG_OUT = "../source/fft_out_imag.txt";

parameter int FFT_N = my_fft_pkg::N;
parameter int DATA_WIDTH = my_fft_pkg::DATA_WIDTH;

`endif
