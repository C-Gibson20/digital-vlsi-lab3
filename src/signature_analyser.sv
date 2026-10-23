// 16-bit parallel signature analyser (MISR) with asynchronous reset and enable
// Compresses a stream of 16-bit words into a single 16-bit signature

module signature_analyser (
    input logic clk,                 // Clock input
    input logic enable,              // Enable signal for the signature analyser
    input logic reset,               // Asynchronous reset input
    input logic clear,               // Clear signal for the signature analyser  
    input logic [15:0] data_in,      // 16-bit input data from XOR array block
    output logic [15:0] signature    // 16-bit signature output
);
    // Primitive polynomial: 1 + x^2 + x^3 + x^5 + x^16
    // Taps on Q1, Q2, Q4 and Q15 are XORed and fed back into stage 0
    logic feedback;
    assign feedback = signature[15] ^ signature[4] ^ signature[2] ^ signature[1];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            signature <= 16'h0000;
        end else if (clear) begins
            signature <= 16'h0000;
        end else if (enable) begin
            // Each stage takes the previous stage's Q XORed with its input bit:
            // D0 = X0 ^ feedback, Di = Xi ^ Q(i-1)
            signature <= {signature[14:0], feedback} ^ data_in;
        end
    end

endmodule
