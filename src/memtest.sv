// Top level module connecting the control, PRBS, counter, and SRAM modules

module memtest (
    input logic clk,           // Clock input
    input logic reset,         // Asynchronous reset input
    // input logic TEST,       // TASK 3 test signal
    output logic [31:0] DATA   // 32-bit data output from SRAM
    // output logic GO_NO_GO   // TASK 3 output signal for the signal analyser
);
    // Internal signals for control
    logic CEB;                      // SRAM chip enable (active low)
    logic WEB;                      // SRAM write enable (active low)
    logic [4:0] address;            // 5-bit address for SRAM
    logic [15:0] prbs;              // 16-bit PRBS output
    logic counter_en;               // Enable signal for the counter
    logic prbs_en;                  // Enable signal for the PRBS generator
    // logic [15:0] xor_array_out;  // TASK 3 output from the signal analyser
    // logic sig_a_en;              // TASK 3 Enable signal for the signal analyser
    // logic [15:0] signature;      // TASK 3 output from the signal analyser
    // logic sig_a_rst;             // TASK 3 Reset signal for the signal analyser
    // localparam [15:0] REF_SIGNATURE = 16'd0; // TASK 3 reference signal for the signal analyser

    // Instantiate control module
    control ctrl (
        .clk(clk),
        .reset(reset),
        // .TEST(TEST), // TASK 3 requires additional test signal
        .CEB(CEB),
        .WEB(WEB),
        .counter_en(counter_en),
        .prbs_en(prbs_en)
        // .sig_a_en(sig_a_en), // TASK 3 requires additional signal analyser enable
        // .sig_a_rst(sig_a_rst) // TASK 3 requires additional signal analyser reset
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

    // Instantiate SRAM module Challenge
    // SRAM32X32 mem32x32(
    //     .CLK(clk),
    //     .A(address),
    //     .D({prbs, prbs}),
    //     .Q(DATA),
    //     .CEB(CEB),
    //     .WEB(WEB),
    //     .BWEB(32'h0),
    //     .TSEL(2'b01)
    // );

    // Instantiate XOR array module
    // xor_array xor_block (
    //    .data_in(DATA),
    //    .data_out(xor_array_out)
    // );

    // Instantiate signature analyser module
    // signature_analyser sig_analyser (
    //    .clk(clk),
    //    .enable(sig_a_en),
    //    .reset(reset),
    //    .clear(sig_a_rst),
    //    .data_in(xor_array_out),
    //    .signature(signature)
    // );

    // Instantiate comparator module
    // comparator comp (
    //    .clk(clk),
    //    .data_in1(signature),
    //    .data_in2(REF_SIGNATURE),
    //    .equal(GO_NO_GO)
    // );
endmodule
