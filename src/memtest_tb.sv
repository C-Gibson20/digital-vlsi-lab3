`timescale 1ns/1ps
module memtest_tb;
    // Clock and reset signals
    logic clk;
    logic reset;
    // logic TEST; // Task 3 test signal
    // logic GO_NO_GO; // TASK 3 

    // SRAM data output
    logic [31:0] DATA;

    // Instantiate the memtest module
    memtest dut (
        .clk(clk),
        .reset(reset),
        // .TEST(TEST), // TASK 3 requires additional test signal
        // .GO_NO_GO(GO_NO_GO), // TASK 3 requires additional output signal
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
        // TEST = 0; // TASK 3 requires additional test signal

        // Apply reset for a few clock cycles
        #20;
        reset = 0;

        // Run the simulation for a sufficient time (100 cycles) to observe behavior
        #1000; // Task 3 will comment this line out

        // Test 1: fault-free memory, expect GO
        // repeat (5) @(posedge clk);
        // TEST = 1;                       // rising edge starts the test
        // repeat (10) @(posedge clk);     // held high: must not retrigger
        // TEST = 0;
        // repeat (70) @(posedge clk);     // 1 + 32 writes + 32 reads + latency
        // $display("Test 1 (good):  signature=%h GO_NO_GO=%b %s", dut.signature, GO_NO_GO, GO_NO_GO ? "PASS" : "FAIL");

        // Test 2: stuck-at-0 on DATA[3], expect NO_GO
        // force dut.DATA[3] = 1'b0;
        // @(posedge clk) TEST = 1;
        // @(posedge clk) TEST = 0;
        // repeat (70) @(posedge clk);
        // $display("Test 2 (fault): signature=%h GO_NO_GO=%b %s", dut.signature, GO_NO_GO, !GO_NO_GO ? "PASS" : "FAIL");
        // release dut.DATA[3];
        
        // Finish simulation
        $finish;
    end

endmodule
