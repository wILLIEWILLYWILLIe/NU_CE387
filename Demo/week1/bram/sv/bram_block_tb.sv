`timescale 1ns/1ns

module bram_block_tb;

  localparam BRAM_ADDR_WIDTH = 10;
  localparam BRAM_DATA_WIDTH = 32;
  localparam PERIOD = 10;

  logic clock = 1'b0; 
  logic reset = 1'b0;

  logic [BRAM_ADDR_WIDTH-1:0] addr = 'h0;
  logic [BRAM_ADDR_WIDTH-1:0] rd_addr = 'h0;
  logic [BRAM_ADDR_WIDTH-1:0] wr_addr = 'h0;
  logic [BRAM_DATA_WIDTH/8-1:0] wr_en = 'h0;
  logic [BRAM_DATA_WIDTH-1:0] din = 'h0;
  logic [BRAM_DATA_WIDTH-1:0] dout;
  
  // instantiate your design
  bram_block #(
    .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
    .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH)
  ) bb (
    .clock(clock), 
    .rd_addr(rd_addr), 
    .wr_addr(wr_addr), 
    .wr_en(wr_en), 
    .din(din),
    .dout(dout)
  );

  // Clock Generator
  always begin
    #(PERIOD/2) clock = 1'b1;
    #(PERIOD/2) clock = 1'b0;
  end

  initial begin
    // Reset
    #0 reset = 0;
    #PERIOD reset = 1;
    #PERIOD reset = 0;

    for (int i=0; i < (2**BRAM_ADDR_WIDTH); i++ ) begin
        // write a value to the BRAM
        #PERIOD
        din = $random;
        wr_en = ~('h0);

        // write to a random address
        addr = $urandom_range(0, (2**BRAM_ADDR_WIDTH)-1); // or use i
        rd_addr = addr;
        wr_addr = addr;
    
        // read it back and check for errors
        #PERIOD
        wr_en = 'h0;
        if ( dout == din ) begin
            $display("Data matched at address %d: %h", addr, dout);
        end
        else if ( dout != din ) begin
            $display("Error: data mismatch at address %d: expected %h, got %h", i, din, dout);
            $stop;
        end
    end

    $display("Simulation complete.");
    $stop;
  end
endmodule
