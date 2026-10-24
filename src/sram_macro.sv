// Task 1 macro on its own, for the challenge comparison
// Same ports as SRAM32X32, so both blocks share one SDC and one flow

module sram_macro (
    input  logic        CLK,    // Clock input
    input  logic [4:0]  A,      // Address
    input  logic [31:0] D,      // Write data
    output logic [31:0] Q,      // Read data
    input  logic        CEB,    // Chip enable (active low)
    input  logic        WEB,    // Write enable (active low)
    input  logic [31:0] BWEB,   // Per-bit write enable (active low)
    input  logic [1:0]  TSEL    // Timing select
);
    // Instance name matches SRAM_INST, which floorplan.tcl places
    TS1N65LPLL32X32M4 mem32x32 (
        .CLK(CLK),
        .A(A),
        .D(D),
        .Q(Q),
        .CEB(CEB),
        .WEB(WEB),
        .BWEB(BWEB),
        .TSEL(TSEL)
    );
endmodule
