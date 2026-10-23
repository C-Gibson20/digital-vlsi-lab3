// Finite state machine that: 
// fills SRAM with PRBS data 
// then reads it back

module control (
    input logic clk,           // Clock input
    input logic reset,         // Asynchronous reset input
    output logic CEB,          // SRAM chip enable (active low)
    output logic WEB,          // SRAM write enable (active low)
    output logic counter_en,   // Enable signal for the counter
    output logic prbs_en       // Enable signal for the PRBS generator
);
    // States IDLE, WRITE, READ, (repeat from WRITE)
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        WRITE = 2'b01,
        READ = 2'b10
    } state_t;
    state_t current_state, next_state;

    // Incrementing SRAM address
    logic [4:0] address;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            address <= 5'd0;
        else if (current_state == WRITE || current_state == READ)
            address <= address + 1;
    end

    // State register logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Next state and output logic
    always_comb begin
        // Default values
        next_state = current_state;
        CEB = 1'b1;
        WEB = 1'b1;
        counter_en = 1'b0;
        prbs_en = 1'b0;

        case (current_state)
            IDLE: begin
                next_state = WRITE;
            end

            WRITE: begin
                // Enable SRAM write
                CEB = 1'b0;
                WEB = 1'b0;
                counter_en = 1'b1;
                prbs_en = 1'b1;
                if (address == 5'd31) begin 
                    next_state = READ;
                end
            end

            READ: begin
                // Enable SRAM read
                CEB = 1'b0;
                WEB = 1'b1;
                counter_en = 1'b1;
                prbs_en = 1'b0;
                if (address == 5'd31) begin 
                    next_state = WRITE; 
                end
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
