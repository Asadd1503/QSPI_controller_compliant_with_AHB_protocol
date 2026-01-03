module qspi_data_sample_reg (
    input  logic        clk,               // System Clock (HCLK)
    input  logic        rst_n,
    input  logic        sample_en,         // Triggered by SCLK generator (sampling pulse)
    
    // Mode Control Signals
    input  logic        use_1_io_lines_in,
    input  logic        use_2_io_lines_in,
    input  logic        use_4_io_lines_in,
    
    // Physical QSPI Pins (Inputs during Read)
    input  logic        qspi_io0,
    input  logic        qspi_io1,
    input  logic        qspi_io2,
    input  logic        qspi_io3,
    
    // Output to AHB/FIFO
    output logic [31:0] data_out
);

    logic [31:0] sample_reg;

    // --- Sampling Logic ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_reg <= '0;
        end else if (sample_en) begin
            if (use_1_io_lines_in) begin
                // Single Mode: Standard MISO is usually on IO1
                
                sample_reg <= {sample_reg[30:0], qspi_io1}; 
            end else if (use_2_io_lines_in) begin
                // Dual Mode: Shift in 2 bits
                sample_reg <= {sample_reg[29:0], qspi_io1, qspi_io0};
            end else if (use_4_io_lines_in) begin
                // Quad Mode: Shift in 4 bits at once into the LSBs
                sample_reg <= {sample_reg[27:0], qspi_io3, qspi_io2, qspi_io1, qspi_io0};
            end   
        end
    end

    // Continuous output of the gathered bits
    assign data_out = sample_reg;

endmodule