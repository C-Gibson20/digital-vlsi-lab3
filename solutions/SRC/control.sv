module Control(
    input logic clk,
    input logic rst,
    output logic ctrl
);

    logic [5:0] counter;

    always_ff @(posedge clk) begin
        if(rst) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end 
    end

    assign ctrl = ~counter[5];

endmodule