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
logic         cs_n;
logic         sclk;
tri          io0 = 1'bz;
tri          io1 = 1'bz;
tri          io2 = 1'bz;
tri          io3 = 1'bz;
logic        busy;
logic        send_data;


logic [3:0] io_out = 4'b0000; 
logic       tb_io_en = 1'b0;  // 1 = Testbench drives pins, 0 = Testbench floats (DUT drives)
logic [31:0] flash_data [0:3] = '{32'haaaa_aaaa, 32'hcccc_cccc, 32'h3333_3333, 32'hcccc_cccc};

assign io0 = tb_io_en ? io_out[0] : 1'bz;
assign io1 = tb_io_en ? io_out[1] : 1'bz;
assign io2 = tb_io_en ? io_out[2] : 1'bz;
assign io3 = tb_io_en ? io_out[3] : 1'bz;
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
    .io3     (io3),
    .QSPIbusy    (busy),
    .send_data (send_data)
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


task automatic host_write(input [31:0] addr, input [31:0] data);
    @(posedge h_clk);
    h_addr  <= addr;
    h_wdata <= data;
    h_sel   <= 1'b1;
    h_write <= 1'b1;
    h_trans <= 2'b10;
    @(posedge h_clk); // hold for one cycle
    h_sel   <= 1'b0;
    h_write <= 1'b0;
   h_trans <= 2'b00;
    @(posedge h_clk);
endtask

// Helper task: read reg via top interface (returns h_rdata after read cycle)
task automatic host_read(input [31:0] addr, output [31:0] data_out);
    @(posedge h_clk);
    h_addr  <= addr;
    h_sel   <= 1'b1;
    h_write <= 1'b0;
    h_trans <= 2'b10;
    @(posedge h_clk); // allow slave to drive h_rdata
    h_sel   <= 1'b0;
    h_trans <= 2'b00;
    # 2;
    data_out = h_rdata;
    
    //@(posedge h_clk);
endtask
task automatic xip_mode_test(input [31:0] addr);
    @(posedge h_clk);
    h_addr <= addr;
    h_sel   <= 1'b1;
    h_write <= 1'b0;
    h_trans <= 2'b10;
    h_burst <= 3'b011; // INCR4
    @(posedge h_clk);
    h_trans <= 2'b11; //seq
    
    $display(" Data phase detected, driving IO lines.");
    wait(send_data == 1'b1); 
    tb_io_en = 1'b1; 
    for (int i=0; i<8; i++) begin
        io_out = flash_data[0][3:0];
        @(posedge sclk);
         
    end
    #3;
    tb_io_en = 1'b0;
    wait (send_data == 1'b1);
    tb_io_en = 1'b1;
    for (int i=0; i<8; i++) begin
        io_out = flash_data[1][3:0];
        @(posedge sclk);
         
    end
    #3;
    tb_io_en = 1'b0;
    #2;
    wait (send_data == 1'b1);
    tb_io_en = 1'b1;
    for (int i=0; i<8; i++) begin
        io_out = flash_data[2][3:0];
        @(posedge sclk);
         
    end
    #3;
    tb_io_en = 1'b0;
    wait (send_data == 1'b1);
    tb_io_en = 1'b1;
    for (int i=0; i<8; i++) begin
        io_out = flash_data[3][3:0];
        @(posedge sclk);
         
    end
    #3;
    tb_io_en = 1'b0;
    wait (h_ready == 1'b0);
    wait (h_ready == 1'b1);
    #2;
    for (int i=0; i < 4; i++) begin
        $display("FIFO[%0d] = %h , Expected--> FIFO[%0d] = %h", i, uut.read_buffer.mem[i], i, flash_data[i]);
    end
endtask

initial begin
    // Wait for reset release
    @(posedge h_clk);
    //@(posedge h_clk);
    // write ctrl reg (0x00)
    host_write(32'h00, 32'h4A); //  , XIP MODE = 1'b1, FLASH ADDR LEN = 24 bits (2'b00), IO LINES = QUAD (2'b10), CPOL = 1, CPHA = 0
    // Write clk_div_reg (0x04)
    host_write(32'h04, 32'h00000001); // h_clk/2
    // Write cmd_reg (0x0C)
    host_write(32'h0C, 32'h0000005A);
    // Write addr_reg (0x10)
    host_write(32'h10, 32'h20000004);

    // Read back and check
    
    host_read(32'h00, read_data);
    if (read_data[7:0] !== 8'h4A) $display("FAIL: ctrl_reg read 0x%0h (expected 0x4A)", read_data[7:0]);
    else $display("PASS: ctrl_reg == 0x%0h", read_data[7:0]);
    host_read(32'h04, read_data);
    if (read_data[7:0] !== 8'h01) $display("FAIL: clk_div read 0x%0h (expected 0x01)", read_data[7:0]); 
    else $display("PASS: clk_div == 0x%0h", read_data[7:0]);

    host_read(32'h0C, read_data);
    if (read_data[7:0] !== 8'h5A) $display("FAIL: cmd_reg read 0x%0h (expected 0x5A)", read_data[7:0]); 
    else $display("PASS: cmd_reg == 0x%0h", read_data[7:0]);

    host_read(32'h10, read_data);
    if (read_data !== 32'h20000004) $display("FAIL: addr_reg read 0x%0h (expected 0x20000004)", read_data); 
    else $display("PASS: addr_reg == 0x%0h", read_data);
    $display("--------------------------------------------------------");
    $display("Configuration registers Write and Readback Test Complete");
    $display("--------------------------------------------------------");
    xip_mode_test(32'h20000F00);
    $display("----------------------");
    $display("XIP MODE TEST COMPLETE");
    $display("----------------------");


    #10 $finish;
end
endmodule