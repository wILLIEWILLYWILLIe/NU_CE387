// =============================================================
// qarctan.sv — Quick arctan as a FUNCTION (not module)
// Matches C reference: qarctan() in fm_radio.cpp exactly
// Piecewise rational approximation, all 32-bit signed math
// =============================================================

package qarctan_pkg;

    import fir_pkg::*;

    // PI/4 * 1024 = 804,  3*PI/4 * 1024 = 2412
    // Calculated: (int)(3.14159265/4.0 * 1024) = 804
    //             (int)(3.0*3.14159265/4.0 * 1024) = 2412
    localparam int QUAD1 = 804;
    localparam int QUAD3 = 2412;

    function automatic int qarctan_f(input int y, input int x);
        int abs_y;
        int r;
        int angle;
        int prod;

        // abs(y) + 1
        abs_y = (y < 0) ? -y : y;
        abs_y = abs_y + 1;

        if (x >= 0) begin
            // r = QUANTIZE_I(x - abs_y) / (x + abs_y)
            //   = (x - abs_y) * 1024 / (x + abs_y)
            r = ((x - abs_y) * QUANT_VAL) / (x + abs_y);
            // angle = quad1 - DEQUANTIZE(quad1 * r)
            prod = QUAD1 * r;
            angle = QUAD1 - fir_pkg::div1024_f(prod);
        end else begin
            // r = QUANTIZE_I(x + abs_y) / (abs_y - x)
            r = ((x + abs_y) * QUANT_VAL) / (abs_y - x);
            // angle = quad3 - DEQUANTIZE(quad1 * r)
            prod = QUAD1 * r;
            angle = QUAD3 - fir_pkg::div1024_f(prod);
        end

        // negate if in quad III or IV
        return (y < 0) ? -angle : angle;
    endfunction

endpackage
