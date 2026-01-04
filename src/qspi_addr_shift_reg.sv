module qspi_addr_shift_reg (
    input  logic        clk,              // System Clock (HCLK)
    input  logic        rst_n,
    input  logic [31:0] data_in,          // Data from FIFO/AHB
    input  logic        load,             // Load new data
    input  logic        shift_en,         // Triggered by SCLK generator
    
    // Mode Control Signals (from your Config Registers)
    input  logic        use_1_io_lines_in,
    input  logic        use_2_io_lines_in,
    input  logic        use_4_io_lines_in,
    
    input logic         addrOF4B_in,
    
    // Physical QSPI Pins
    output logic qspi_io0,           // IO[3:0] pins
    output logic qspi_io1,
    output logic qspi_io2,
    output logic qspi_io3
);

    logic [31:0] shift_reg_32;
    logic [23:0] shift_reg_24;

    // --- Shift Logic ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_32 <= '0;
            shift_reg_24 <= '0;
        end else if (load) begin
            if (addrOF4B_in)
                shift_reg_32 <= data_in;
            else
                shift_reg_24 <= data_in[23:0];
        end
        else if (shift_en) begin
            if (addrOF4B_in) begin
                if (use_4_io_lines_in)
                    shift_reg_32 <= {shift_reg_32[27:0], 4'b0}; // Shift 4 bits
                else if (use_2_io_lines_in)
                    shift_reg_32 <= {shift_reg_32[29:0], 2'b0}; // Shift 2 bits
                else
                    shift_reg_32 <= {shift_reg_32[30:0], 1'b0}; // Shift 1 bit
            end else begin
                if (use_4_io_lines_in)
                    shift_reg_24 <= {shift_reg_24[19:0], 4'b0}; // Shift 8 bits
                else if (use_2_io_lines_in)
                    shift_reg_24 <= {shift_reg_24[21:0], 2'b0}; // Shift 4 bits
                else
                    shift_reg_24 <= {shift_reg_24[22:0], 1'b0}; // Shift 1 bit
            end
        end
    end


    // --- Output Multiplexing ---
    // In SPI/QSPI, the Most Significant Bits are sent out first.
    always_comb begin
        qspi_io0 = 1'bz; // Default to high-impedance
        qspi_io1 = 1'bz;
        qspi_io2 = 1'bz;
        qspi_io3 = 1'bz;
        if (addrOF4B_in) begin
            if (use_4_io_lines_in) begin
                // Quad Mode: All 4 lines carry data
                qspi_io3 = shift_reg_32[31];
                qspi_io2 = shift_reg_32[30];
                qspi_io1 = shift_reg_32[29];
                qspi_io0 = shift_reg_32[28];
            end else if (use_2_io_lines_in) begin
                // Dual Mode: IO0 and IO1 carry data
                qspi_io3 = 1'bz;
                qspi_io2 = 1'bz;
                qspi_io1 = shift_reg_32[31];
                qspi_io0 = shift_reg_32[30];
            end else if (use_1_io_lines_in) begin
                // Single Mode: Standard MOSI is IO0
                qspi_io3 = 1'bz;
                qspi_io2 = 1'bz;
                qspi_io1 = 1'bz;
                qspi_io0 = shift_reg_32[31];
            end
        end else begin
            if (use_4_io_lines_in) begin
                // Quad Mode: All 4 lines carry data
                qspi_io3 = shift_reg_24[23];
                qspi_io2 = shift_reg_24[22];
                qspi_io1 = shift_reg_24[21];
                qspi_io0 = shift_reg_24[20];
            end else if (use_2_io_lines_in) begin
                // Dual Mode: IO0 and IO1 carry data
                qspi_io3 = 1'bz;
                qspi_io2 = 1'bz;
                qspi_io1 = shift_reg_24[23];
                qspi_io0 = shift_reg_24[22];
            end else if (use_1_io_lines_in) begin
                // Single Mode: Standard MOSI is IO0
                qspi_io3 = 1'bz;
                qspi_io2 = 1'bz;
                qspi_io1 = 1'bz;
                qspi_io0 = shift_reg_24[23];
            end
        end
    end
    

endmodule