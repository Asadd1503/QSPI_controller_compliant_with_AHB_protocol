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
    output logic [31:0] h_rdata,
    //============== OUTPUT TO SLAVE CONTROLLER ==============
    //output logic cfg_reg_wr,
    output logic enter_xip_mode,
    output logic non_Seq_out,
    output logic seq_out,
    output logic idle_out,
    output logic busy_out,
    output logic tx_data_valid_out,
    output logic enter_indrct_mode_out,
    //============== INPUT FROM SLAVE CONTROLLER ==============
    //input logic cfg_reg_wr_en,
    input logic load_h_addr,
    input logic load_h_burst,
    input logic wr_rx_reg_in,
    //============== OUTPUT TO QSPI DATAPATH ==============
    output logic [7:0] clk_div_out,
    output logic [1:0] flash_addr_len_out,
    output logic [1:0] no_io_lines_use_out,
    output logic cpol_out,
    output logic [31:0] haddr_out,
    output logic [2:0] hburst_reg_out,
    output logic [31:0] addr_reg_out,
    output logic [7:0] cmd_reg_out,
    output logic [7:0] indrct_bytes_num_out,
    //============== INPUTS FROM QSPI CONT ================
    input logic set_done_flag_in,
    //=============== OUTPUTS TO QSPI CONTROLLER =================
    output logic cpha_out,
    output logic indrct_wr_out,
    output logic xip_field_out,
    //================ INPUTS FROM READ BUFFER =================
    input logic [31:0] rd_buffr_data_in,
    //=============== OUTUPTS TO WRITE BUFFER ==================
    output logic [31:0] wr_buffr_wr_data_out

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
logic cfg_reg_wr_en;
logic cfg_reg_rd_en;
logic [2:0] hrDATAsel; // 00 - read buffer, 01 - rx_data_reg, 10 - status_reg
logic clear_status_reg;


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
assign wr_buffr_wr_data_out = tx_data_reg;
assign indrct_start = ctrl_reg[7]; // Start bit for indirect transfers
assign cmd_reg_out = cmd_reg[7:0];
assign indirct_wr_out = ctrl_reg[16]; // 1 - write, 0 - read
assign xip_field_out = xip_field;
assign indrct_bytes_num_out = ctrl_reg[15:8]; // Number of bytes to transfer in indirect mode
//=============================================================
//=================== INDIRECT MODE LOGIC ==================
always_comb begin
    if (indrct_start && !xip_field) begin
        enter_indrct_mode_out = 'b1;
    end else begin
        enter_indrct_mode_out = 'b0;
    end
end


//================== ADDRESS DECODER AND XIP MODE DETERMINATION =========================================
always_comb begin
    if ( addr_in <= 32'h18 && addr_in >= 32'h00 ) begin
        cfg_reg_addr_in_range = 1'b1;
    end else begin
        cfg_reg_addr_in_range = 1'b0;
    end
    //--------------------------------------------------------------------
    if (cfg_reg_addr_in_range == 'b1 && h_write == 'b1 && h_sel == 'b1) begin
        cfg_reg_wr_en = 'b1;
    end else begin
        cfg_reg_wr_en = 'b0;
    end
    if (cfg_reg_addr_in_range == 'b1 && h_write == 'b0 && h_sel == 'b1) begin
        cfg_reg_rd_en = 'b1;
    end else begin
        cfg_reg_rd_en = 'b0;
    end 
    

    //---------------------------------------------------------------------
    if ( flash_addr_len == 2'b00 ) begin
        // 3 byte address
        if (addr_in >= 32'h2000_0000 && addr_in <= 32'h20FF_FFFF) begin // 32'h20FF_FFFF = 16 MB flash
            flash_addr_in_range = 1'b1;
        end else begin
            flash_addr_in_range = 1'b0;
        end
    end else if ( flash_addr_len == 2'b01 ) begin
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
    if ( flash_addr_in_range == 'b1 && h_write == 'b0 && h_sel == 'b1 && h_trans == 'b00 && xip_field == 'b1) begin
        enter_xip_mode = 'b1;
    end else begin
        enter_xip_mode = 'b0;
    end
end
//================ TRANSFER SIGNAL LOGIC ========================
always_comb begin
    case (h_trans) 
        2'b00: non_Seq_out = 'b1;
        2'b01: seq_out =     'b1;
        2'b10: idle_out =    'b1;
        2'b11: busy_out =    'b1;
    endcase
    
end


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
    hrDATAsel <= 2'b00; // Default to read buffer
    tx_data_valid_out <= 'b0;
    if (!h_rstn) begin
        ctrl_reg    <= 32'b0;
        clk_div_reg  <= 32'b0;
        cmd_reg     <= 32'b0;
        addr_reg    <= 32'b0;
        tx_data_reg <= 32'b0;
        status_reg  <= 32'b0;
        rx_data_reg <= 32'b0;
    end else begin
        
        if (cfg_reg_wr_en) begin
            unique case (addr_in)
                32'h00: ctrl_reg    <= h_wdata;
                32'h04: clk_div_reg <= h_wdata;
                32'h0C: cmd_reg     <= h_wdata;
                32'h10: addr_reg    <= h_wdata;
                32'h14: begin
                        tx_data_reg       <= h_wdata;
                        tx_data_valid_out <= 'b1;
                end

            endcase
        end
        else if (cfg_reg_rd_en) begin
            unique case (addr_in)
                32'h08: hrDATAsel <= 3'b001; // read status reg
                32'h18: hrDATAsel <= 3'b010; // read rx data reg
                32'h00: hrDATAsel <= 3'b011; // read ctrl reg
                32'h04: hrDATAsel <= 3'b100; // read clk div reg
                32'h0C: hrDATAsel <= 3'b101; // read cmd reg
                32'h10: hrDATAsel <= 3'b110; // read addr reg
                32'h14: hrDATAsel <= 3'b111; // read tx data reg
            endcase
        end
        if (wr_rx_reg_in) begin
            rx_data_reg <= rd_buffr_data_in;
        end
        if (set_done_flag_in) begin
            status_reg[0] <= 1'b1; // Set done flag
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
        2'b01: haddr_dec_out = {5'd0, h_addr_reg_out[26:0]}; // 4 byte address // 128 MB
    endcase
end
//================= DECODING LOGIC FOR ADDR REG =================
always_comb begin
    addr_reg_out = 32'd0;
    unique case (flash_addr_len)
        2'b00: addr_reg_out = {8'd0, addr_reg[23:0]}; // 3 byte address
        2'b01: addr_reg_out = {5'd0, addr_reg[26:0]}; // 4 byte address // 128 MB
    endcase
end
//================= HR_DATA OUTPUT MUX =========================
always_comb begin
    clear_status_reg = 'b0;
    case (hrDATAsel)
        3'b000: h_rdata = rd_buffr_data_in;
        3'b001: h_rdata = rx_data_reg;
        3'b010: begin
            h_rdata = status_reg;
            clear_status_reg = 'b1;
        end
        3'b011: h_rdata = ctrl_reg;
        3'b100: h_rdata = clk_div_reg;
        3'b101: h_rdata = cmd_reg;
        3'b110: h_rdata = addr_reg;
        3'b111: h_rdata = tx_data_reg;  
        default: h_rdata = 32'd0;
    endcase
end
always_ff @(posedge h_clk or negedge h_rstn) begin
        if (clear_status_reg) begin
            status_reg <= 32'b0; // Clear done flag after reading status reg
        end
    end

endmodule