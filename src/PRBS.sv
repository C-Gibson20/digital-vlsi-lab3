// 16-bit Psuedorandom Binary Sequence (PRBS) generator with asynchronous reset and enable

module PRBS (
    input logic clk,           // Clock input
    input logic reset,         // Asynchronous reset input
    input logic enable,        // Enable input
    output logic [15:0] prbs   // 16-bit PRBS output
);

    // PRBS generation using a linear feedback shift register (LFSR)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset PRBS to a non-zero value (e.g., 1)
            prbs <= 16'd1;
        end else if (enable) begin
            // Generate next PRBS value using polynomial x^16 + x^14 + x^13 + x^11 + 1
            prbs <= {prbs[14:0], prbs[15] ^ prbs[13] ^ prbs[12] ^ prbs[10]};
        end
    end
endmodule
