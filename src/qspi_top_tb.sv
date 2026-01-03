module qspi_top_tb;
logic        h_clk;
logic        h_rstn;
logic [31:0] h_wdata;
logic [31:0] h_addr;
logic [2:0]  h_burst;
logic [1:0]  h_trans;
logic        h_write;
logic        h_sel;
logic [31:0] read_data;

// DUT outputs
logic        h_ready;
logic [1:0]  h_resp;
logic [31:0] h_rdata;
wire         cs_n;
wire         sclk;
tri          io0 = 1'bz;
tri          io1 = 1'bz;
tri          io2 = 1'bz;
tri          io3 = 1'bz;

// Instantiate top
qspi_top uut (
    .h_clk   (h_clk),
    .h_rstn  (h_rstn),
    .h_wdata (h_wdata),
    .h_addr  (h_addr),
    .h_burst (h_burst),
    .h_trans (h_trans),
    .h_write (h_write),
    .h_sel   (h_sel),
    .h_ready (h_ready),
    .h_resp  (h_resp),
    .h_rdata (h_rdata),
    .cs_n    (cs_n),
    .sclk    (sclk),
    .io0     (io0),
    .io1     (io1),
    .io2     (io2),
    .io3     (io3)
);

// Clock: 10 time units period
initial begin
    h_clk = 0;
    forever #5 h_clk = ~h_clk;
end

// Reset and default init
initial begin
    h_rstn   = 0;
    h_wdata  = 32'h0;
    h_addr   = 32'h0;
    h_burst  = 3'd0;
    h_trans  = 2'b00;
    h_write  = 1'b0;
    h_sel    = 1'b0;
    @(posedge h_clk);
    h_rstn = 1;
end

// Helper task: write reg via top interface
task automatic host_write(input [31:0] addr, input [31:0] data);
    @(posedge h_clk);
    h_addr  <= addr;
    h_wdata <= data;
    h_sel   <= 1'b1;
    h_write <= 1'b1;
    //h_trans <= 2'b10;
    @(posedge h_clk); // hold for one cycle
    h_sel   <= 1'b0;
    h_write <= 1'b0;
   // h_trans <= 2'b00;
    @(posedge h_clk);
endtask

// Helper task: read reg via top interface (returns h_rdata after read cycle)
task automatic host_read(input [31:0] addr, output [31:0] data_out);
    @(posedge h_clk);
    h_addr  <= addr;
    h_sel   <= 1'b1;
    h_write <= 1'b0;
    //h_trans <= 2'b10;
    @(posedge h_clk); // allow slave to drive h_rdata
    data_out = h_rdata;
    h_sel   <= 1'b0;
    //h_trans <= 2'b00;
    @(posedge h_clk);
endtask

initial begin
    // Wait for reset release
    @(posedge h_clk);
    //@(posedge h_clk);
    // write ctrl reg
    host_write(32'h00, 32'h00000002); 
    // Write clk_div_reg @ 0x04 with 0x0000_00AA
    host_write(32'h04, 32'h00000001); // clk/2
    // Write cmd_reg @ 0x0C with 0x0000_005A
    host_write(32'h0C, 32'h0000005A);
    // Write addr_reg @ 0x10 with 0xDEADBEEF
    host_write(32'h10, 32'hDEADBEEF);

    // Read back and check
    
    host_read(32'h00, read_data);
    if (read_data[1:0] !== 2'b10) $display("FAIL: ctrl_reg read 0x%0h (expected 0x2)", read_data[1:0]);
    else $display("PASS: ctrl_reg == 0x%0h", read_data[1:0]);
    host_read(32'h04, read_data);
    if (read_data[7:0] !== 8'h01) $display("FAIL: clk_div read 0x%0h (expected 0x01)", read_data[7:0]); 
    else $display("PASS: clk_div == 0x%0h", read_data[7:0]);

    host_read(32'h0C, read_data);
    if (read_data[7:0] !== 8'h5A) $display("FAIL: cmd_reg read 0x%0h (expected 0x5A)", read_data[7:0]); 
    else $display("PASS: cmd_reg == 0x%0h", read_data[7:0]);

    host_read(32'h10, read_data);
    if (read_data !== 32'hDEADBEEF) $display("FAIL: addr_reg read 0x%0h (expected 0xDEADBEEF)", read_data); 
    else $display("PASS: addr_reg == 0x%0h", read_data);

    $display("Simple config register test completed.");
    #10 $finish;
end
endmodule