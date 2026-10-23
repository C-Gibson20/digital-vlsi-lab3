// XOR the upper and lower halves of 32-bit input array

module xor_array (
    input logic [31:0] data_in,   // 32-bit input data
    output logic [15:0] data_out  // 16-bit output data after XOR operation
);
    // Perform XOR operation between upper and lower halves of the input
    always_comb begin
        data_out = data_in[31:16] ^ data_in[15:0];
    end
endmodule
