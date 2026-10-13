module PRBS16 #(
    parameter SEED = 16'hFFFF
)(
  input logic clk,        // clock
  input logic rst,        // reset
  input logic en,
  output logic [15:0]  data_out    // pseudo-random output
);
  logic [15:0]  sreg;

  always_ff @ (posedge clk)
    if (rst)
        sreg <= SEED;
    else 
        if(en)
	        sreg <= {sreg[14:0], sreg[15] ^ sreg[14] ^ sreg[12] ^ sreg[3]};

  assign data_out = sreg;
  
endmodule 