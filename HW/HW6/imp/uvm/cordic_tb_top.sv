
module cordic_tb_top;
    import uvm_pkg::*;
    import cordic_pkg::*;

    logic clock;
    logic reset;

    // Interface
    cordic_if vif(clock, reset);

    // DUT Connection
    cordic_top dut (
        .clock(clock),
        .reset(reset),
        .valid_in(vif.valid_in),
        .rad_in(vif.rad_in),
        .full_out(), // Connect if interface has it, otherwise leave open
        .valid_out(vif.valid_out),
        .sin_out(vif.sin_out),
        .cos_out(vif.cos_out)
    );

    // Clock
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Reset Generation
    initial begin
        reset = 1;
        #20 reset = 0;
    end

    // Config and Run
    initial begin
        uvm_config_db#(virtual cordic_if)::set(null, "*", "vif", vif);
        run_test("cordic_test");
    end

endmodule
