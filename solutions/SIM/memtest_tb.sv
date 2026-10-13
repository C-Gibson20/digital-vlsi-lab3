`timescale 1ns/1ps

module memtest_tb();

    localparam TESTS = 4;
    localparam CLK_PERIOD = 10;
    localparam PRBS_SEED = 16'hFFFF;


    logic clk;
    logic rst;
    logic [31:0] dut_data;
    logic [15:0] mdl_data;
    string res;

    logic WRITE=0;

    always #(CLK_PERIOD/2) clk=~clk;


    memtest dut(
        .rst (rst),
        .clk (clk),
        .data_out(dut_data)
    );



    initial begin
        // reset clock
        clk <= 1 ; rst <= 1;
        #(CLK_PERIOD) rst <= 0;


        mdl_data = PRBS_SEED;

        // Wait two cycles to sync the reading
        repeat(2) @(posedge clk);

        for (int i = 0; i < TESTS ; i++) begin
            // Memory write
            WRITE = 1;
            repeat(32) @(posedge clk);



            // Memory read
            WRITE = 0;
            for(int j = 0; j < 32; j++) begin
                @(posedge clk); 
                
                res = ({mdl_data,mdl_data} == dut_data) ? "PASS" : "FAIL";

                $display("T: %d #:%2d MDL: %H\t DUT: %H --> %s\n", $time,j, mdl_data, dut_data[15:0], res);

                mdl_data = prbs16(mdl_data);

            end
        end

        $finish(2);

    end

    // function for a 16bit PRBS
    function automatic [15:0] prbs16(input [15:0] seed);
        prbs16 = {seed[14:0], seed[15] ^ seed[14] ^ seed[12] ^ seed[3]};

    endfunction

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(3, memtest_tb, dut);
    end

endmodule

