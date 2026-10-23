// 5-bit address counter with asynchronous reset and enable

module counter (
    input logic clk,          // Clock input
    input logic reset,        // Asynchronous reset input
    input logic enable,       // Enable input
    output logic [4:0] count  // 5-bit counter output
);

    // Counter 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset counter to 0
            count <= 5'd0;
        end else if (enable) begin
            // Increment counter
            count <= count + 1;
        end
    end
endmodule
