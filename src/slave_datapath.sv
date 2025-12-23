module slave_datapath (
    //--------------- INPUTS ---------------
    input logic         h_clk,
    input logic         h_rstn,
    input logic [31:0]  h_wdata,
    input logic [31:0]  h_addr,
    input logic [2:0]   h_burst,
    input logic [1:0]   h_trans,
    input logic         h_write,
    input logic         h_sel,
    //--------------- OUTPUTS---------------
    //output logic        h_ready,
    output logic [1:0]  h_resp,
    output logic [31:0] h_rdata
    //============== OUTPUT TO SLAVE CONTROLLER ==============
    output logic cfg_reg_wr,
    output logic enter_xip_mode,

    //============== INPUT FROM SLAVE CONTROLLER ==============
    input logic cfg_reg_wr_en,
    input logic load_h_addr,
    input logic load_h_burst,
    //============== OUTPUT TO QSPI DATAPATH ==============
    output logic clk_div_out,
    output logic [1:0] flash_addr_len_out,
    output logic [1:0] no_io_lines_use_out,
    output logic cpol_out,
    output logic [31:0] haddr_out,
    output logic [2:0] hburst_reg_out,
    //=============== OUTPUTS TO QSPI CONTROLLER =================
    output logic cpha_out,

);
//=================== CFG REGISTERS ===========================
logic [31:0] ctrl_reg;      // 0x00
logic [31:0] clk_div_reg;       // 0x04
logic [31:0] status_reg;    // 0x08
logic [31:0] cmd_reg;       // 0x0C
logic [31:0] addr_reg;      // 0x10
logic [31:0] tx_data_reg;   // 0x14
logic [31:0] rx_data_reg;   // 0x18
//============================================================
logic [31:0] addr_in;
logic [31:0] haddr_dec_out;
logic       cfg_reg_addr_in_range;
logic [1:0] flash_addr_len;
logic       xip_field;
logic       flash_addr_in_range;
logic [31:0] h_addr_reg_out;
logic [2:0] h_burst_reg;
logic [1:0] no_io_lines_used;
logic cpol;
logic cpha;

assign xip_field      = ctrl_reg[6];  // 1 --> XIP MODE ENABLED, 0 --> INDIRECT MODE
assign flash_addr_len = ctrl_reg[5:4];
assign addr_in        = h_addr;
assign clk_div_out = clk_div_reg[7:0];
assign flash_addr_len_out = flash_addr_len;
assign no_io_lines_use_out = no_io_lines_used;
assign cpol_out = cpol;
assign cpha_out = cpha;
assign haddr_out = haddr_dec_out;
assign hburst_reg_out = h_burst_reg;

//=============================================================



//================== ADDRESS DECODER AND XIP MODE DETERMINATION =========================================
always_comb begin
    if ( addr_in <= 32'h18 && addr_in >= 32'h00 ) begin
        cfg_reg_addr_in_range = 1'b1;
    end else begin
        cfg_reg_addr_in_range = 1'b0;
    end
    //--------------------------------------------------------------------
    if (cfg_reg_addr_in_range = 'b1 && h_write = 'b1 && h_sel = 'b1) begin
        cfg_reg_wr = '1;
    end else begin
        cfg_reg_wr = '0;
    end
    //---------------------------------------------------------------------
    if ( flash_addr_len = 2'b00 ) begin
        // 3 byte address
        if (addr_in >= 32'h2000_0000 && addr_in <= 32'h20FF_FFFF) begin // 32'h20FF_FFFF = 16 MB flash
            flash_addr_in_range = 1'b1;
        end else begin
            flash_addr_in_range = 1'b0;
        end
    end else if ( flash_addr_len = 2'b01 ) begin
        // 4 byte address
        if (addr_in >= 32'h2000_0000 && addr_in <= 32'h27FF_FFFF) begin // 32'h27FF_FFFF = 128 MB flash
            flash_addr_in_range = 1'b1;
        end else begin
            flash_addr_in_range = 1'b0;
        end
    end
    else begin
        flash_addr_in_range = 1'b0;
    end
    //---------------------------------------------------------------------
    if ( flash_addr_in_range = 'b1 && h_write = 'b0 && h_sel = 'b1 && h_trans = 'b00 && xip_field = 'b1) begin
        enter_xip_mode = 'b1;
    end else begin
        enter_xip_mode = 'b0;
    end
end
//=============================================================================


//================== ADDRESS ERROR GENERATOR  =================
always_comb begin
    h_resp = 2'b00; //OKAY
    if (h_sel && !cfg_reg_addr_in_range) begin
        h_resp = 2'b10; //SLVERR
    end
    else if (h_sel && !flash_addr_in_range) begin
        h_resp = 2'b10; //SLVERR
    end
end
//=============================================================================
//================== CONFIGURATION REGISTERS LOGIC =========================
always_ff @(posedge h_clk or negedge h_rstn) begin
    if (!h_rstn) begin
        ctrl_reg    <= 32'b0;
        clk_div     <= 32'b0;
        cmd_reg     <= 32'b0;
        addr_reg    <= 32'b0;
        tx_data_reg <= 32'b0;
        status_reg  <= 32'b0;
        rx_data_reg <= 32'b0;
    end else begin
        if (cfg_reg_wr_en) begin
            unique case (addr_in)
                32'h00: ctrl_reg    <= h_wdata;
                32'h04: clk_div     <= h_wdata;
                32'h0C: cmd_reg     <= h_wdata;
                32'h10: addr_reg    <= h_wdata;
                32'h14: tx_data_reg <= h_wdata;
            endcase
        end
        end
end
//=============================================================================

//================== REGISTERS FOR STORAGE ====================================
always_ff @(posedge h_clk or negedge h_rstn) begin
    if (!h_rstn) begin
        h_addr_reg_out  <= 'b0;
        h_burst_reg <= 'b0;
    end else begin
        if (load_h_addr) begin
            h_addr_reg_out <= h_addr;
        end 
        if (load_h_burst) begin
            h_burst_reg <= h_burst;
        end
    end
end
//==============================================================================
//================== ADDRESS DECODING ====================================
always_comb begin
    haddr_dec_out = 32'd0;
    unique case (flash_addr_len)
        2'b00: haddr_dec_out = {8'd0, h_addr_reg_out[23:0]}; // 3 byte address
        2'b01: haddr_dec_out = {5'd0, h_addr_reg_out[26:0]}; // 4 byte address
    endcase
end

endmodule