module qspi_counter (
    input  logic        clk,           
    input  logic        rst_n,       // Active low reset
    input  logic        start_count,         // Trigger to start_count counting
    input  logic [4:0]  target_count,  // Input: How many cycles to count
    output logic        count_done,    // Set to 1 when count is complete

    
);

    logic [5:0] count_reg;
    logic       active;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg     <= '0;
            count_done    <= 'b0;
            active        <= 'b0;
        end else begin
            if (active) begin
                count_reg  <= '0;
                count_done <= 'b0;
                active    <= 'b0;
            end
            else if (start_count) begin
                if (count_reg == (target_count - 5'd1)) begin
                    count_done <= 1'b1;
                    active     <= 1'b1;
                end else begin
                    count_reg  <= count_reg + 1'b1;
                end
            end else begin
                count_done <= 1'b0;
            end
        end
    end

    

endmodule