`timescale 1ns/1ps
module memtest_tb;
    // Clock and reset signals
    logic clk;
    logic reset;

    // SRAM data output
    logic [31:0] DATA;

    // Instantiate the memtest module
    memtest dut (
        .clk(clk),
        .reset(reset),
        .DATA(DATA)
    );

    // Clock generation: 10ns period (100MHz)
    always begin
        #5 clk = ~clk;
    end

    // Testbench procedure
    initial begin
        // Setup waveform dump for simulation
        $dumpfile("waveform.vcd");
        $dumpvars(0, memtest_tb);

        // Initialize signals
        clk = 0;
        reset = 1;

        // Apply reset for a few clock cycles
        #20;
        reset = 0;

        // Run the simulation for a sufficient time (100 cycles) to observe behavior
        #1000;

        // Finish simulation
        $finish;
    end

endmodule
