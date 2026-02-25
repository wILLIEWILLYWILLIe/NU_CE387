
package my_fft_pkg;
    parameter int N = 16;
    parameter int DATA_WIDTH = 16;
    parameter int TWIDDLE_WIDTH = 16;
    parameter int Q = 14;
    parameter int NUM_STAGES = $clog2(N);
    parameter int INT_WIDTH = 32; // Match C reference's 32-bit int precision
    parameter int DEBUG = 0;      // 0: quiet (performance+summary only), 1: verbose debug prints

    typedef struct packed {
        logic signed [TWIDDLE_WIDTH-1:0] real_val;
        logic signed [TWIDDLE_WIDTH-1:0] imag_val;
    } complex_t;

    // W_16^k = exp(-j * 2 * pi * k / 16), quantized Q14
    parameter complex_t TWIDDLES [0:N/2-1] = '{
        '{real_val: 16'sh4000, imag_val: 16'sh0000}, // W_16^0
        '{real_val: 16'sh3B20, imag_val: 16'shE783}, // W_16^1
        '{real_val: 16'sh2D41, imag_val: 16'shD2BF}, // W_16^2
        '{real_val: 16'sh187D, imag_val: 16'shC4E0}, // W_16^3
        '{real_val: 16'sh0000, imag_val: 16'shC000}, // W_16^4
        '{real_val: 16'shE783, imag_val: 16'shC4E0}, // W_16^5
        '{real_val: 16'shD2BF, imag_val: 16'shD2BF}, // W_16^6
        '{real_val: 16'shC4E0, imag_val: 16'shE783}  // W_16^7
    };

endpackage
