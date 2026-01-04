module rd_sync_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 16
)(
    input  logic                    rd_clk,
    input logic                     wr_clk,
    input  logic                    rst_n,
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    full,
    output logic                    empty
    //output logic                    almost_full,
    //output logic                    almost_empty
    
);

    logic [$clog2(FIFO_DEPTH):0] count;
    logic [$clog2(FIFO_DEPTH):0] wr_count;
    logic [$clog2(FIFO_DEPTH):0] rd_count;
    logic [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [DATA_WIDTH-1:0] mem[FIFO_DEPTH-1:0];

    always_ff @(posedge wr_clk or posedge rst_n) begin
        if (rst_n) begin
            wr_ptr <= 'd0;
        end
        else if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 'd1;
        end
        
    end

    always_ff @(posedge rd_clk or posedge rst_n) begin
        if (rst_n) begin
            rd_count <= 'd0;
            
        end
        else begin
            case ({rd_en && !empty})
                1'b1: rd_count <= rd_count + 1'd1;  // Read only
                1'b0: rd_count <= rd_count;         // No operation
                
            endcase
        end
    end

 
    always_ff @(posedge wr_clk or posedge rst_n) begin
        if (rst_n) begin
            wr_count <= 'd0;
        end
        else begin
            case ({wr_en && !full})
                1'b1: wr_count <= wr_count + 1'd1;  // Write only
                1'b0: wr_count <= wr_count;         // No operation
            endcase
        end
    end

   
    always_comb begin
        full = (count == FIFO_DEPTH);
        //almost_full = (count >= ALMOST_FULL_THRESH);
    end

    
    always_ff @(posedge rd_clk or posedge rst_n) begin
        if (rst_n) begin
            rd_ptr <= 'd0;  
        end
        else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 'd1;
            
        end
    end

  
    always_ff @(posedge rd_clk or posedge rst_n) begin
        if (rst_n) begin
            rd_data <= 'd0;
        end
        else if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr];
        end
    end

    
    always_comb begin
        empty = (count == 'd0);
        //almost_empty = (count <= ALMOST_EMPTY_THRESH);
    end
    always_comb begin
        if (rst_n) begin
             count = 'd0;
        end
        else begin
            count = wr_count - rd_count;
        end
    end
endmodule