`timescale 1ns/1ps
module memtest_tb;
    // Clock and reset signals
    logic clk;
    logic reset;
    logic TEST; // Task 3 test signal
    logic GO_NO_GO; // TASK 3

    // SRAM data output
    logic [31:0] DATA;

    // Number of failed checks, reported at the end
    int errors = 0;

    // Instantiate the memtest module
    memtest dut (
        .clk(clk),
        .reset(reset),
        .TEST(TEST), // TASK 3 requires additional test signal
        .GO_NO_GO(GO_NO_GO), // TASK 3 requires additional output signal
        .DATA(DATA)
    );

    // Clock generation: 10ns period (100MHz)
    always begin
        #5 clk = ~clk;
    end

    // CHALLENGE: the RTL SRAM (RTL_SRAM, set in the Makefile) is flattened into cells at gate
    // level, so its pins cannot be probed there. Its unit test only runs in RTL simulation
`ifdef RTL_SRAM
`ifdef GATE_LEVEL
`define NO_SRAM_PINS
`else
`define SRAM_UNIT_TEST
`endif
`endif

    // Scoreboard: checks the counter, PRBS, FSM and SRAM read-back every cycle
    // Sampled on the falling edge, when every signal has settled
    logic [15:0] exp_prbs = 16'd1;      // software copy of PRBS.sv
    logic [4:0]  exp_addr = 5'd0;       // address the next access should use
    logic [31:0] exp_mem [0:31];        // what each address should hold
    logic        read_pending = 1'b0;   // a read was issued last cycle
    logic [4:0]  read_addr;
    logic        check_reads = 1'b1;    // turned off while a fault is forced
    int          writes = 0;
    int          reads = 0;

`ifndef NO_SRAM_PINS
    always @(negedge clk) begin
        if (!reset) begin
            // SRAM output is valid the cycle after the read was issued
            if (read_pending && check_reads && DATA !== exp_mem[read_addr]) begin
                $display("ERROR %0t: read address %0d got %h, expected %h", $time, read_addr, DATA, exp_mem[read_addr]);
                errors++;
            end
            read_pending = 1'b0;

            if (!dut.mem32x32.CEB) begin
                // Address must step through 0..31 in order
                if (dut.mem32x32.A !== exp_addr) begin
                    $display("ERROR %0t: address=%0d, expected %0d", $time, dut.mem32x32.A, exp_addr);
                    errors++;
                end

                if (!dut.mem32x32.WEB) begin
                    // Write: PRBS must match the model, and the word is recorded
                    if (dut.mem32x32.D[15:0] !== exp_prbs) begin
                        $display("ERROR %0t: PRBS=%h, expected %h", $time, dut.mem32x32.D[15:0], exp_prbs);
                        errors++;
                    end
                    exp_mem[exp_addr] = {exp_prbs, exp_prbs};
                    exp_prbs = {exp_prbs[14:0], exp_prbs[15] ^ exp_prbs[13] ^ exp_prbs[12] ^ exp_prbs[10]};
                    writes++;
                end else begin
                    // Read: checked on the next falling edge
                    read_pending = 1'b1;
                    read_addr = exp_addr;
                    reads++;
                end
                exp_addr = exp_addr + 1;
            end
        end
    end
`endif

    // TASK 3: count test starts (SRAM idle -> writing) and analyser enable cycles
    int tests_started = 0;
    int en_cycles = 0;
    logic prev_CEB = 1'b1;
    always @(negedge clk) begin
`ifndef NO_SRAM_PINS
        if (prev_CEB && !dut.mem32x32.CEB && !dut.mem32x32.WEB) tests_started++;
        prev_CEB = dut.mem32x32.CEB;
`endif
`ifndef GATE_LEVEL
        if (dut.sig_a_en) en_cycles++;   // internal net, removed by synthesis
`endif
    end

    // TASK 3: raise TEST, hold it for hold_cycles, then wait for the test to finish
    task automatic run_test(input int hold_cycles);
        tests_started = 0;
        en_cycles = 0;
        @(negedge clk) TEST = 1;
        repeat (hold_cycles) @(negedge clk);
        TEST = 0;
        repeat (80) @(negedge clk);     // 1 + 32 writes + 32 reads + latency, with margin
    endtask

    // TASK 3: one test must start, the analyser must see 32 words, and the result must match
    // At gate level the signature and enable nets no longer exist, so only ports and SRAM pins are checked
    task automatic check_test(input string name, input logic exp_go, input logic [15:0] exp_sig);
`ifdef NO_SRAM_PINS
        if (GO_NO_GO !== exp_go) begin
            $display("FAIL %s: GO_NO_GO=%b (expected %b)", name, GO_NO_GO, exp_go);
            errors++;
        end else
            $display("PASS %s: GO_NO_GO=%b", name, GO_NO_GO);
`elsif GATE_LEVEL
        if (GO_NO_GO !== exp_go || tests_started != 1) begin
            $display("FAIL %s: GO_NO_GO=%b tests=%0d (expected %b, 1)", name, GO_NO_GO, tests_started, exp_go);
            errors++;
        end else
            $display("PASS %s: GO_NO_GO=%b", name, GO_NO_GO);
`else
        if (GO_NO_GO !== exp_go || dut.signature !== exp_sig || tests_started != 1 || en_cycles != 32) begin
            $display("FAIL %s: GO_NO_GO=%b signature=%h tests=%0d enable_cycles=%0d (expected %b, %h, 1, 32)",
                     name, GO_NO_GO, dut.signature, tests_started, en_cycles, exp_go, exp_sig);
            errors++;
        end else
            $display("PASS %s: GO_NO_GO=%b signature=%h", name, GO_NO_GO, dut.signature);
`endif
    endtask

`ifdef SRAM_UNIT_TEST
    // CHALLENGE: direct test of SRAM32X32, including BWEB, which memtest ties to 0
    logic [4:0]  ut_A;
    logic [31:0] ut_D, ut_Q, ut_BWEB;
    logic        ut_CEB = 1'b1;
    logic        ut_WEB = 1'b1;
    SRAM32X32 sram_ut (
        .CLK(clk), .A(ut_A), .D(ut_D), .Q(ut_Q),
        .CEB(ut_CEB), .WEB(ut_WEB), .BWEB(ut_BWEB), .TSEL(2'b01)
    );

    // CHALLENGE: drive one access on the falling edge; the rising edge in between performs it
    task automatic ut_cycle(input logic ceb, input logic web, input logic [4:0] a,
                            input logic [31:0] d, input logic [31:0] bweb);
        ut_CEB = ceb; ut_WEB = web; ut_A = a; ut_D = d; ut_BWEB = bweb;
        @(negedge clk);
    endtask

    task automatic ut_expect(input string name, input logic [31:0] exp);
        if (ut_Q !== exp) begin
            $display("FAIL SRAM %s: Q=%h, expected %h", name, ut_Q, exp);
            errors++;
        end else
            $display("PASS SRAM %s: Q=%h", name, ut_Q);
    endtask

    task automatic sram_unit_test();
        @(negedge clk);
        ut_cycle(0, 0, 5'd7, 32'hA5A5_5A5A, 32'h0);          // full write to address 7
        ut_cycle(0, 0, 5'd8, 32'h1234_5678, 32'h0);          // full write to address 8
        ut_cycle(0, 1, 5'd8, 32'h0, 32'h0);                  // read address 8
        ut_expect("read address 8", 32'h1234_5678);
        ut_CEB = 0; ut_WEB = 1; ut_A = 5'd7; #1;             // read address 7, before the edge
        ut_expect("no new data before the clock edge", 32'h1234_5678);
        @(negedge clk);
        ut_expect("read address 7 one edge later", 32'hA5A5_5A5A);
        ut_cycle(0, 0, 5'd7, 32'hFFFF_FFFF, 32'hFFFF_0000);  // write lower half only
        ut_expect("Q unchanged by a write", 32'hA5A5_5A5A);
        ut_cycle(0, 1, 5'd7, 32'h0, 32'h0);
        ut_expect("BWEB masks the upper half", 32'hA5A5_FFFF);
        ut_cycle(1, 1, 5'd8, 32'h0, 32'h0);                  // chip disabled
        ut_expect("Q holds while disabled", 32'hA5A5_FFFF);
        ut_cycle(1, 0, 5'd8, 32'h0, 32'h0);                  // write while disabled is ignored
        ut_cycle(0, 1, 5'd8, 32'h0, 32'h0);
        ut_expect("write ignored while disabled", 32'h1234_5678);
    endtask
`endif

    // Testbench procedure
    initial begin
        // Setup waveform dump for simulation
        $dumpfile("waveform.vcd");
        $dumpvars(0, memtest_tb);

        // Initialize signals
        clk = 0;
        reset = 1;
        TEST = 0; // TASK 3 requires additional test signal

        // Apply reset for a few clock cycles
        #20;
        reset = 0;

`ifdef SRAM_UNIT_TEST
        sram_unit_test(); // CHALLENGE
`endif

        // Task 2: two full write/read loops, checked by the scoreboard
        // repeat (140) @(posedge clk); // Task 3 will comment this line out

        // Test 1: straight after reset GO_NO_GO already shows GO, because the reset
        // signature equals the reference. Known limitation, reported rather than failed
        repeat (5) @(negedge clk);
        $display("NOTE before any test: GO_NO_GO=%b", GO_NO_GO);

        // Test 2: stuck-at-0 on DATA[3], first test after reset so the PRBS starts at its seed
        // Expected signature from reference_signature.py
        check_reads = 0;
        force dut.DATA[3] = 1'b0;
        run_test(1);
        check_test("stuck-at-0 DATA[3]", 1'b0, 16'hE5F5);
        release dut.DATA[3];
        check_reads = 1;

        // Test 3: fault-free memory, TEST held high past the end: must run once and pass
        // Also checks the analyser was cleared after the failed test
        run_test(100);
        check_test("good memory, TEST held", 1'b1, 16'h0000);

        // Test 4: repeat without reset, must pass again
        run_test(1);
        check_test("good memory, repeat", 1'b1, 16'h0000);

        // Test 5: same stuck bit in both halves cancels in the XOR array. Known limitation
        check_reads = 0;
        force dut.DATA[3] = 1'b0;
        force dut.DATA[19] = 1'b0;
        run_test(1);
        check_test("cancelling fault DATA[3] and DATA[19] (undetected)", 1'b1, 16'h0000);
        release dut.DATA[3];
        release dut.DATA[19];
        check_reads = 1;

        // Summary
`ifndef NO_SRAM_PINS
        if (writes == 0 || reads == 0) begin
            $display("ERROR no SRAM accesses seen");
            errors++;
        end
`endif
        if (errors == 0)
            $display("ALL CHECKS PASSED (%0d writes, %0d reads)", writes, reads);
        else
            $display("%0d CHECKS FAILED", errors);

        // Finish simulation
        $finish;
    end

endmodule
