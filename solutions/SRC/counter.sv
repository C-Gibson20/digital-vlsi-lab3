module Counter (
    input logic clk,
    input logic rst,
    input logic en,
    output logic [4:0] count
);
    always_ff @(posedge clk) begin
        if (rst)
            count <= 5'd0;
        else if (en)
            count <= count + 1;
    end
endmodule