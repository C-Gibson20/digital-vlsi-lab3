// 32x32 synchronous SRAM built from standard-cell registers
// Same ports and timing as TS1N65LPLL32X32M4 so it drops into memtest

module SRAM32X32 (
    input  logic        CLK,    // Clock input
    input  logic [4:0]  A,      // Address
    input  logic [31:0] D,      // Write data
    output logic [31:0] Q,      // Read data, valid the cycle after the read
    input  logic        CEB,    // Chip enable (active low)
    input  logic        WEB,    // Write enable (active low)
    input  logic [31:0] BWEB,   // Per-bit write enable (active low)
    input  logic [1:0]  TSEL    // Timing select, unused in the RTL model
);
    // Storage: 32 words of 32 bits, no reset (same as the macro)
    logic [31:0] mem [0:31];

    always_ff @(posedge CLK) begin
        if (!CEB) begin
            if (!WEB) begin
                // Write: bits with BWEB = 0 take D, bits with BWEB = 1 keep their value
                mem[A] <= (D & ~BWEB) | (mem[A] & BWEB);
            end else begin
                // Read: registered, so Q is valid the cycle after the address
                Q <= mem[A];
            end
        end
        // Chip disabled or writing: Q holds its last value
    end

endmodule
