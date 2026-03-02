// =============================================================
// fir_pkg.sv — Package: FIR filter coefficients from fm_radio.h
// Q10 format (hex values directly from C header)
// =============================================================

package fir_pkg;

    // Quantization
    parameter int BITS      = 10;
    parameter int QUANT_VAL = 1 << BITS; // 1024

    // Helper function for dividing by QUANT_VAL (1024)
    // C integer division truncates towards zero (e.g. -5 / 2 = -2)
    // SV arithmetic right shift (>>>) truncates towards -infinity (e.g. -5 >>> 1 = -3)
    // To fix this without huge hardware dividers, we build a bit-true equivalent:
    function automatic int div1024_f(input int x);
        if (x >= 0) begin
            return x >>> 10;
        end else begin
            // For negative numbers, add 1023 before right-shifting
            return (x + 1023) >>> 10;
        end
    endfunction

    // Data widths
    parameter int WIDTH     = 32;
    parameter int CWIDTH    = 32;

    // Channel Filter (20-tap complex LPF, 80 kHz cutoff)
    // IMAG coeffs are all zero → only REAL needed
    parameter int CHANNEL_TAPS = 20;
    parameter logic signed [31:0] CHANNEL_COEFFS [0:19] = '{
        32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009,
        32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3,
        32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1,
        32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b,
        32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001
    };

    // L+R LPF (32-tap, 15 kHz cutoff, decimation=8)
    parameter int AUDIO_LPR_TAPS = 32;
    parameter logic signed [31:0] AUDIO_LPR_COEFFS [0:31] = '{
        32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed,
        32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3,
        32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9,
        32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243,
        32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d,
        32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015,
        32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5,
        32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
    };

    // L-R LPF (32-tap, same coeffs as LPR, decimation=8)
    parameter int AUDIO_LMR_TAPS = 32;
    parameter logic signed [31:0] AUDIO_LMR_COEFFS [0:31] = '{
        32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed,
        32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3,
        32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9,
        32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243,
        32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d,
        32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015,
        32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5,
        32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
    };

    // Pilot BPF (32-tap, 19 kHz)
    parameter int BP_PILOT_TAPS = 32;
    parameter logic signed [31:0] BP_PILOT_COEFFS [0:31] = '{
        32'h0000000e, 32'h0000001f, 32'h00000034, 32'h00000048,
        32'h0000004e, 32'h00000036, 32'hfffffff8, 32'hffffff98,
        32'hffffff2d, 32'hfffffeda, 32'hfffffec3, 32'hfffffefe,
        32'hffffff8a, 32'h0000004a, 32'h0000010f, 32'h000001a1,
        32'h000001a1, 32'h0000010f, 32'h0000004a, 32'hffffff8a,
        32'hfffffefe, 32'hfffffec3, 32'hfffffeda, 32'hffffff2d,
        32'hffffff98, 32'hfffffff8, 32'h00000036, 32'h0000004e,
        32'h00000048, 32'h00000034, 32'h0000001f, 32'h0000000e
    };

    // L-R BPF (32-tap, 23-53 kHz)
    parameter int BP_LMR_TAPS = 32;
    parameter logic signed [31:0] BP_LMR_COEFFS [0:31] = '{
        32'h00000000, 32'h00000000, 32'hfffffffc, 32'hfffffff9,
        32'hfffffffe, 32'h00000008, 32'h0000000c, 32'h00000002,
        32'h00000003, 32'h0000001e, 32'h00000030, 32'hfffffffc,
        32'hffffff8c, 32'hffffff58, 32'hffffffc3, 32'h0000008a,
        32'h0000008a, 32'hffffffc3, 32'hffffff58, 32'hffffff8c,
        32'hfffffffc, 32'h00000030, 32'h0000001e, 32'h00000003,
        32'h00000002, 32'h0000000c, 32'h00000008, 32'hfffffffe,
        32'hfffffff9, 32'hfffffffc, 32'h00000000, 32'h00000000
    };

    // HP filter (32-tap, removes DC after pilot squaring)
    parameter int HP_TAPS = 32;
    parameter logic signed [31:0] HP_COEFFS [0:31] = '{
        32'hffffffff, 32'h00000000, 32'h00000000, 32'h00000002,
        32'h00000004, 32'h00000008, 32'h0000000b, 32'h0000000c,
        32'h00000008, 32'hffffffff, 32'hffffffee, 32'hffffffd7,
        32'hffffffbb, 32'hffffff9f, 32'hffffff87, 32'hffffff76,
        32'hffffff76, 32'hffffff87, 32'hffffff9f, 32'hffffffbb,
        32'hffffffd7, 32'hffffffee, 32'hffffffff, 32'h00000008,
        32'h0000000c, 32'h0000000b, 32'h00000008, 32'h00000004,
        32'h00000002, 32'h00000000, 32'h00000000, 32'hffffffff
    };

    // IIR deemphasis coefficients (Q10, 1st-order)
    // x_coeffs = QUANTIZE_F(W_PP/(1+W_PP)) = (int)(0.17448*1024) = 178
    // y_coeffs[1] = QUANTIZE_F((W_PP-1)/(W_PP+1)) = (int)(-0.65098*1024) = -666
    parameter logic signed [31:0] IIR_X_COEFFS [0:1] = '{32'd178, 32'd178};
    parameter logic signed [31:0] IIR_Y_COEFFS [0:1] = '{32'd0,  -32'd666};

    // FM demod gain = (int)((float)QUAD_RATE / (2*PI*MAX_DEV) * 1024)
    //               = (int)(256000 / 345575.19 * 1024) = 758
    parameter int FM_DEMOD_GAIN = 758;

    // Audio decimation factor
    parameter int AUDIO_DECIM = 8;

    // Volume level = QUANTIZE_F(1.0f) = 1024
    parameter int VOLUME_LEVEL = QUANT_VAL;

endpackage
