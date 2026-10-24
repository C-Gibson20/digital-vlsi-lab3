`timescale 1ns/1ps
// Testbench for a 32x32 memory block on its own, checked against a reference model.
// SRAM_DUT picks the block: SRAM32X32 (default, the challenge RTL SRAM) or sram_macro
// (the Task 1 macro), set from the Makefile with BLOCK=

`ifndef SRAM_DUT
`define SRAM_DUT SRAM32X32
`endif

module sram_tb;
    // Clock: 10ns period (100MHz)
    logic clk = 0;
    always #5 clk = ~clk;

    // Memory inputs, driven on the falling edge so they are stable at the rising edge
    logic [4:0]  A;
    logic [31:0] D, BWEB;
    logic        CEB = 1'b1;
    logic        WEB = 1'b1;
    logic [31:0] Q;

    `SRAM_DUT dut (
        .CLK(clk), .A(A), .D(D), .Q(Q),
        .CEB(CEB), .WEB(WEB), .BWEB(BWEB), .TSEL(2'b01)
    );

    // Reference model: what each address should hold
    logic [31:0] model [0:31];
    int errors = 0;
    int checks = 0;

    // Write: bits with BWEB = 0 take D, bits with BWEB = 1 keep their value
    task automatic write(input logic [4:0] a, input logic [31:0] d, input logic [31:0] bweb = 32'h0);
        CEB = 0; WEB = 0; A = a; D = d; BWEB = bweb;
        @(negedge clk);
        model[a] = (d & ~bweb) | (model[a] & bweb);
    endtask

    // Read: Q must hold the addressed word one edge after the address is applied.
    // D and BWEB carry random values, which a read must ignore
    task automatic read_check(input logic [4:0] a, input string what);
        CEB = 0; WEB = 1; A = a; D = $urandom; BWEB = $urandom;
        @(negedge clk);
        check(model[a], what);
    endtask

    // Chip disabled for one cycle, with the given inputs on the pins
    task automatic disabled(input logic web, input logic [4:0] a, input logic [31:0] d);
        CEB = 1; WEB = web; A = a; D = d; BWEB = 32'h0;
        @(negedge clk);
    endtask

    task automatic check(input logic [31:0] exp, input string what);
        checks++;
        if (Q !== exp) begin
            $display("FAIL %0t: %s: Q=%h, expected %h", $time, what, Q, exp);
            errors++;
        end
    endtask

    initial begin
        logic [31:0] q_prev;
        logic [4:0]  a;

        $dumpfile("waveform.vcd");
        $dumpvars(0, sram_tb);
        void'($urandom(42));    // fixed seed, so a failure can be rerun
        @(negedge clk);

        // Test 1: every address holds its own word. A decoder fault that
        // aliases two addresses makes one overwrite the other
        for (int i = 0; i < 32; i++) write(i, $urandom);
        for (int i = 0; i < 32; i++) read_check(i, "unique word per address, ascending");
        for (int i = 31; i >= 0; i--) read_check(i, "unique word per address, descending");
        $display("Test 1 done: address decoding");

        // Test 2: walking one and walking zero through every data bit, so a
        // stuck or shorted bit shows up
        for (int b = 0; b < 32; b++) begin
            write(5'd9, 32'h1 << b);
            read_check(5'd9, $sformatf("walking one, bit %0d", b));
            write(5'd9, ~(32'h1 << b));
            read_check(5'd9, $sformatf("walking zero, bit %0d", b));
        end
        $display("Test 2 done: data bits");

        // Test 3: read latency. Q must not change until the clock edge after the address
        read_check(5'd3, "latency setup");
        q_prev = Q;
        a = (model[5'd4] !== q_prev) ? 5'd4 : 5'd5;     // an address holding a different word
        CEB = 0; WEB = 1; A = a; #1;
        check(q_prev, "no new data before the clock edge");
        @(negedge clk);
        check(model[a], "new data one edge later");
        $display("Test 3 done: read latency");

        // Test 4: chip disabled. Q holds and writes are ignored (memtest relies on the hold)
        q_prev = Q;
        disabled(1'b1, 5'd12, $urandom);
        check(q_prev, "Q holds while disabled");
        disabled(1'b0, 5'd12, ~model[5'd12]);
        read_check(5'd12, "write ignored while disabled");
        $display("Test 4 done: chip enable");

        // Test 5: constrained-random mix of masked writes, reads and idle cycles,
        // all checked against the model
        for (int i = 0; i < 2000; i++) begin
            a = $urandom_range(31);
            case ($urandom_range(3))
                0: write(a, $urandom, 32'h0);
                1: write(a, $urandom, $urandom);    // random BWEB mask
                2: read_check(a, $sformatf("random read %0d", i));
                3: disabled($urandom_range(1), a, $urandom);
            endcase
        end
        for (int i = 0; i < 32; i++) read_check(i, "final read-back");
        $display("Test 5 done: 2000 random operations with BWEB masks");

        if (errors == 0)
            $display("ALL CHECKS PASSED (%0d checks)", checks);
        else
            $display("%0d of %0d CHECKS FAILED", errors, checks);
        $finish;
    end
endmodule
