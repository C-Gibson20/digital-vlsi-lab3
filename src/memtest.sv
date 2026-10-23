// Top level module connecting the control, PRBS, counter, and SRAM modules

module memtest (
    input logic clk,           // Clock input
    input logic reset,         // Asynchronous reset input
    output logic [31:0] DATA   // 32-bit data output from SRAM
);
    // Internal signals for control
    logic CEB;             // SRAM chip enable (active low)
    logic WEB;             // SRAM write enable (active low)
    logic [4:0] address;   // 5-bit address for SRAM
    logic [15:0] prbs;     // 16-bit PRBS output
    logic counter_en;      // Enable signal for the counter
    logic prbs_en;         // Enable signal for the PRBS generator

    // Instantiate control module
    control ctrl (
        .clk(clk),
        .reset(reset),
        .CEB(CEB),
        .WEB(WEB),
        .counter_en(counter_en),
        .prbs_en(prbs_en)
    );

    // Instantiate counter module
    counter addr_counter (
        .clk(clk),
        .reset(reset),
        .enable(counter_en),
        .count(address)
    );

    // Instantiate PRBS module
    PRBS prbs_gen (
        .clk(clk),
        .reset(reset),
        .enable(prbs_en),
        .prbs(prbs)
    );

    // Instantiate SRAM module
    TS1N65LPLL32X32M4 mem32x32 (
        .CLK(clk),
        .A(address),
        .D({prbs, prbs}),
        .Q(DATA),
        .CEB(CEB),
        .WEB(WEB),
        .BWEB(32'h0),
        .TSEL(2'b01)
    );
endmodule
