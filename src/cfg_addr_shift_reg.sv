module cfg_addr_shift_reg (
    input  logic        clk,         
    input  logic        rst_n,
    input  logic [7:0]  data_in,     // Data to be sent (from FIFO/AHB)
    input  logic        load,        // Load data into register
    input  logic        shift_en,    // Pulse from clk_gen to shift 1 bit
    output logic        mosi     // Single IO line (IO0)
);

    logic [7:0] shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'h0;
        end else if (load) begin
            // Load the full word to prepare for transmission
            shift_reg <= data_in;
        end else if (shift_en) begin
            // Shift left by 1 bit, filling with 0
            // Most Significant Bit (MSB) is sent first in SPI
            shift_reg <= {shift_reg[30:0], 1'b0};
        end
    end

    // The output is always the current MSB of the register
    assign mosi = shift_reg[7];

endmodule