
`ifndef CORDIC_TRANSACTION_SV
`define CORDIC_TRANSACTION_SV

class cordic_transaction extends uvm_sequence_item;
    `uvm_object_utils(cordic_transaction)

    rand logic signed [31:0] rad_in;
    logic signed [15:0] sin_out;
    logic signed [15:0] cos_out;

    function new(string name = "cordic_transaction");
        super.new(name);
    endfunction

    // Constraint for random angle generation
    // -PI to PI approx. PI = 3.14159 * 2^14 = 51471. 
    // In 32-bit fixed point (rad_in is input), this range is small.
    // However, CORDIC design supports large inputs via range reduction.
    // Let's constrain to a reasonable range to exercise logic, e.g. -2PI to 2PI.
    constraint c_rad {
        rad_in inside {[-100000:100000]}; 
    }

    function string convert2string();
        return $sformatf("rad_in=0x%0h sin_out=0x%0h cos_out=0x%0h", rad_in, sin_out, cos_out);
    endfunction

endclass

`endif
