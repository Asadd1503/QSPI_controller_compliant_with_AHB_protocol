module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH = 16,
    parameter int ALMOST_FULL_THRESH = 14,
    parameter int ALMOST_EMPTY_THRESH = 2
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    full,
    output logic                    empty,
    output logic                    almost_full,
    output logic                    almost_empty,
    output logic [$clog2(FIFO_DEPTH):0] count
);

    
    logic [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [DATA_WIDTH-1:0] mem[FIFO_DEPTH-1:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 'd0;
        end
        else if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 'd1;
        end
        
    end

 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 'd0;
        end
        else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'd1;  // Write only
                2'b01: count <= count - 1'd1;  // Read only
                2'b11: count <= count;         // Simultaneous read/write
                2'b00: count <= count;         // No operation
            endcase
        end
    end

   
    always_comb begin
        full = (count == FIFO_DEPTH);
        almost_full = (count >= ALMOST_FULL_THRESH);
    end

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 'd0;  
        end
        else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 'd1;
            
        end
    end

  
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data <= 'd0;
        end
        else if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr];
        end
    end

    
    always_comb begin
        empty = (count == 'd0);
        almost_empty = (count <= ALMOST_EMPTY_THRESH);
    end

endmodule