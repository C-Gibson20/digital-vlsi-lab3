// Compare two 16 bit numbers and output a boolean

module comparator (
    input logic [15:0] data_in1,       // First 16-bit input
    input logic [15:0] data_in2,       // Second 16-bit input
    output logic equal          // Output signal indicating equality
);
    // Compare the two inputs and set the output accordingly
    always_comb begin
        if (data_in1 == data_in2)
            equal = 1'b1;      // Set equal to 1 if a and b are equal
        else
            equal = 1'b0;      // Set equal to 0 if a and b are not equal
    end
endmodule
