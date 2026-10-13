`timescale 1ns/1ps

module memtest (
    input logic clk,
    input logic rst,
    output logic [31:0] data_out
);

    logic ctrl;
    logic [4:0] addr;
    logic [15:0] data;


    Counter counter(
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .count(addr)
    );

    Control control(
        .clk(clk),
        .rst(rst),
        .ctrl(ctrl)     // control signal HIGH for write, LOW for read
    ); 

    PRBS16 prbs(
        .clk(clk),
        .rst(rst),
        .en(ctrl),
        .data_out(data)
    );

    TS1N65LPLL32X32M4 mem32x32( 
        .CLK(clk), 
        .CEB(1'b0), 
        .WEB(~ctrl),
        .A(addr), 
        .D({data,data}), 
        .BWEB(32'h0000_0000),
        .Q(data_out),
        .TSEL(2'b01)
    );

endmodule
