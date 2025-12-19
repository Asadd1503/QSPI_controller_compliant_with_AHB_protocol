module qspi_clk_gen (
    input  logic        h_clk,       // Fast System Clock (e.g., 100MHz)
    input  logic        h_rstn,   
    input  logic [7:0]  clk_div_in,    // Division factor from Register
    output logic        sclk_out    // The actual SPI Clock pin
);

    logic [7:0] count;
    logic       internal_clk;

    // 1. Frequency Divider Logic
    // SCLK frequency = HCLK / (2 * (clk_div + 1))
    always_ff @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            count        <= 8'h0;
            internal_clk <= 1'b0;
        end else begin
            if (count == clk_div) begin
                count        <= 8'h0;
                internal_clk <= ~internal_clk; 
            end else begin
                count        <= count + 1;
            end
        end
        
    end

    assign sclk_out = internal_clk;

    

endmodule