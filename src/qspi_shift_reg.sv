module qspi_shift_reg (
    input  logic        clk,              // System Clock (HCLK)
    input  logic        rst_n,
    input  logic [31:0] data_in,          // Data from FIFO/AHB
    input  logic        load,             // Load new data
    input  logic        shift_en,         // Triggered by SCLK generator
    
    // Mode Control Signals (from your Config Registers)
    input  logic        use_1_io_lines_in,
    input  logic        use_2_io_lines_in,
    input  logic        use_4_io_lines_in,
    
    // Physical QSPI Pins
    output logic qspi_io0,           // IO[3:0] pins
    output logic qspi_io1,
    output logic qspi_io2,
    output logic qspi_io3,
);

    logic [31:0] shift_reg;

    // --- Shift Logic ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= '0;
        end else if (load) begin
            shift_reg <= data_in;
        end else if (shift_en) begin
            if (use_4_io_lines_in)
                shift_reg <= {shift_reg[27:0], 4'b0}; // Shift 4 bits
            else if (use_2_io_lines_in)
                shift_reg <= {shift_reg[29:0], 2'b0}; // Shift 2 bits
            else
                shift_reg <= {shift_reg[30:0], 1'b0}; // Shift 1 bit
        end
    end

    // --- Output Multiplexing ---
    // In SPI/QSPI, the Most Significant Bits are sent out first.
    always_comb begin
        qspi_io0 = 1'bz; // Default to high-impedance
        qspi_io1 = 1'bz;
        qspi_io2 = 1'bz;
        qspi_io3 = 1'bz;
        
        if (use_4_io_lines) begin
            // Quad Mode: All 4 lines carry data
            qspi_io3 = shift_reg[31];
            qspi_io2 = shift_reg[30];
            qspi_io1 = shift_reg[29];
            qspi_io0 = shift_reg[28];
        end else if (use_2_io_lines) begin
            // Dual Mode: IO0 and IO1 carry data
            qspi_io3 = 1'bz;
            qspi_io2 = 1'bz;
            qspi_io1 = shift_reg[31];
            qspi_io0 = shift_reg[30];
        end else if (use_1_io_lines_in) begin
            // Single Mode: Standard MOSI is IO0
            qspi_io3 = 1'bz;
            qspi_io2 = 1'bz;
            qspi_io1 = 1'bz;
            qspi_io0 = shift_reg[31];
        end
    end
    

endmodule