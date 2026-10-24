// Finite state machine that:
// fills SRAM with PRBS data
// then reads it back

module control (
    input logic clk,           // Clock input
    input logic reset,         // Asynchronous reset input
    input logic TEST,          // TASK 3 test signal
    output logic CEB,          // SRAM chip enable (active low)
    output logic WEB,          // SRAM write enable (active low)
    output logic counter_en,   // Enable signal for the counter
    output logic prbs_en,      // Enable signal for the PRBS generator
    output logic sig_a_en,     // TASK 3 Enable signal for the signal analyser
    output logic sig_a_rst     // TASK 3 Reset signal for the signal analyser
);
    // Task 2 States IDLE, WRITE, READ, (repeat from WRITE)
    // Task 3 States IDLE, (TEST) WRITE, READ, IDLE
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        WRITE = 2'b01,
        READ = 2'b10
    } state_t;
    state_t current_state, next_state;

    // Checking for TEST transition
    logic TEST_prev;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            TEST_prev <= 1'b0;
        else
            TEST_prev <= TEST; // TASK 3 requires additional test signal
    end
    logic TEST_rising_edge;
    assign TEST_rising_edge = TEST & ~TEST_prev; // TASK 3 requires additional test signal

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

    // Output logic for signature analyser enable
    // SRAM Q is valid one cycle after the read address is applied
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            sig_a_en <= 1'b0;
        else
            sig_a_en <= (current_state == READ);
    end

    // Next state and output logic
    always_comb begin
        // Default values
        next_state = current_state;
        CEB = 1'b1;
        WEB = 1'b1;
        counter_en = 1'b0;
        prbs_en = 1'b0;
        sig_a_rst = 1'b0; // TASK 3 requires additional signal analyser reset

        case (current_state)
            IDLE: begin
                // next_state = WRITE;  // TASK 2
                if (TEST_rising_edge) begin // TASK 3
                    next_state = WRITE;
                    sig_a_rst = 1'b1;
                end
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
                    // next_state = WRITE; // TASK 2
                    next_state = IDLE; // TASK 3
                end
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
