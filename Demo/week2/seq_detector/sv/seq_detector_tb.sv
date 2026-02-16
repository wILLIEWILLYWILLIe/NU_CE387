`timescale 1ns/1ns

module seq_detector_tb;

  logic clk = 1'b0; 
  logic reset = 1'b0;
  logic din = 1'h0;
  logic dout;

  // instantiate your design
  seq_detector sd(clk, reset, din, dout);

  // Clock Generator
  always begin
    #5 clk = 1'b1;
    #5 clk = 1'b0;
  end

  initial begin
    // Reset
    #0 reset = 0;
    #10 reset = 1;
    #10 reset = 0;

    for (int i=0; i < 100; i++ ) begin
        #10 din = $random;        
    end

    #10 din = 1'b1;        
    #10 din = 1'b0;        
    #10 din = 1'b1;        
    #10 din = 1'b1;        
    #10 din = 1'b0;
    #50;
      $stop;
  end
endmodule
