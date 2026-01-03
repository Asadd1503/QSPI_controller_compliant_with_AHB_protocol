module qspi_datapath (
    //============= INPUTS FROM TOP =================
    input logic h_clk,
    input logic h_rstn,
    //============== OUTPUTS TO TOP ==================
    output logic sclk_out,
    inout logic io0_inout,
    inout logic io1_inout,
    inout logic io2_inout,
    inout logic io3_inout,
    
    //=============== INPUTS FROM SLAVE DATAPATH ==============
    input logic [7:0] clk_div_in,
    input logic [1:0] flash_addr_len_in,
    input logic [1:0] no_io_lines_use_in,
    input logic cpol_in,
    input logic [31:0] haddr_in,
    input logic [2:0] hburst_reg_in,
    input logic [31:0] addr_reg_in,
    input logic [7:0] cmd_reg_in,
    input logic xip_field_in,
    input logic [7:0] indrct_bytes_num_in,
    //============= OUTPUTS TO QSPI CONT==================
    output logic sclk_out_cont,  // to TOP
    output logic addr_of_4B_out,
    output logic use_1_io_lines_out,
    output logic use_2_io_lines_out,
    output logic use_4_io_lines_out,
    output logic count_done_out,
    output logic setup_cmd_sent_out,
    output logic burst_comp_out,
    //============= INPUTS FROM QSPI CONT ================
    input logic load_cmd_in,
    input logic load_addr_in,
    input logic load_cfg_addr_shift_reg_in,
    input logic gen_sclk_in,
    input logic [2:0] cmd_sel_in,
    input logic cmd_shift_reg_en_in,
    //input logic load_cfg_addr_shift_reg_in,
    input logic cfg_addr_shift_reg_en_in,
    input logic start_count_in,
    input logic [1:0] set_count_lim_in,
    input logic [2:0] io0_sel_in,
    input logic [1:0] io1_sel_in,
    input logic [1:0] io2_sel_in,
    input logic [1:0] io3_sel_in,
    input logic addr_shift_reg_en_in,
    input logic data_sample_reg_en_in,
    input logic sel_sample_1_line_in,
    input logic burst_count_en_in,
    input logic sel_shift_addr_reg_in,
    input logic set_setup_flag_in,
    input logic load_shift_data_en_in,
    input logic data_Shift_reg_en_in,
    //================ OUTPUTS TO READ BUFFER =====================
    output logic [31:0] data_sample_reg_out,
    //================ INPUTS FROM WRITE BUFFER ==================
    input logic [31:0] wr_buffr_rd_data_in

);

logic sclk;
logic cmd_shift_reg_mux_out;
logic cmd_shift_reg_out;
logic cfg_addr_shift_reg_out;
logic use_1_io_lines;
logic use_2_io_lines;
logic use_4_io_lines;
logic [7:0] cmd_shift_reg_data_in;
logic [4:0] target_value_counter_in;
logic gen_sclk_mux_in;
logic addr_shift_reg_out0;
logic addr_shift_reg_out1;
logic addr_shift_reg_out2;
logic addr_shift_reg_out3;
logic [31:0] data_sample_reg_value;
logic [4:0] addr_count_value;
logic [4:0] data_count_value;
logic use_1_io_lines_sample_reg;
logic [31:0] shift_addr_reg_in;
logic data_shift_reg_out0;
logic data_shift_reg_out1;
logic data_shift_reg_out2;
logic data_shift_reg_out3;

logic data_sample_reg_in0;
logic data_sample_reg_in1;
logic data_sample_reg_in2;
logic data_sample_reg_in3;
logic [3:0] total_beats;

// Internal signals to control the pin
logic io0_out_val; // The value we WANT to send out
logic io0_oe;      // Output Enable (1 = Drive Output, 0 = Input/High-Z)

// --- Internal Signals for IO1 ---
logic io1_out_val; // Value to drive out
logic io1_oe;      // Output Enable (1 = Output, 0 = Input)

// --- Internal Signals for IO3 ---
logic io3_out_val; // Value to drive out
logic io3_oe;      // Output Enable (1 = Output, 0 = Input)

// --- Internal Signals for IO2 ---
logic io2_out_val; // Value to drive out
logic io2_oe;      // Output Enable (1 = Output, 0 = Input)


assign use_1_io_lines_out = use_1_io_lines;
assign use_2_io_lines_out = use_2_io_lines;
assign use_4_io_lines_out = use_4_io_lines;
assign sclk_out_cont = sclk;                        // SCLK for QSPI CONTROLLER
assign data_sample_reg_out = data_sample_reg_value; // DATA TO READ BUFFER

//=============== CLK  GENERATOR INSTANCE ==================
qspi_clk_gen u_qspi_clk_gen (
    .h_clk      (h_clk),
    .h_rstn     (h_rstn),
    .clk_div_in (clk_div_in),
    .sclk_out   (sclk)
);

//================ CMD SEL MUX ===========================
always_comb begin
    case (cmd_sel_in)
        3'b000: cmd_shift_reg_data_in = 8'hEC;  // QUAD READ FOR 4 BYTE ADDR SPACE
        3'b001: cmd_shift_reg_data_in = 8'h13;  // SINGLE READ FOR 4 BYTE ADDR SPACE
        3'b010: cmd_shift_reg_data_in = 8'hEB;  // QUAD READ FOR 3 BYTE ADDR SPACE
        3'b011: cmd_shift_reg_data_in = 8'h03;  // SINGLE READ FOR 3 BYTE ADDR SPACE
        3'b100: cmd_shift_reg_data_in = cmd_reg_in; // CMD FROM CMG REG
    endcase

end

//=============== CMD SHIFT REGISTER ===========================
qspi_cmd_shift_reg u_qspi_cmd_shift_reg (
    .clk           (sclk),
    .rst_n         (h_rstn),
    .data_in       (cmd_shift_reg_data_in),
    .load          (load_cmd_in),
    .shift_en      (cmd_shift_reg_en_in),
    .mosi          (cmd_shift_reg_out)
);
//================ MUX TO SELECT ADDR SHIFT REG VALUE===============
always_comb begin
    if (sel_shift_addr_reg_in) begin
        shift_addr_reg_in = addr_reg_in;
    end else begin
        shift_addr_reg_in = haddr_in;
    end
end
//================= CFG ADDR SHIFT REGISTER ========================
qspi_cmd_shift_reg cfg_addr_shift_reg (
    .clk           (sclk),
    .rst_n         (h_rstn),
    .data_in       (8'hB7),
    .load          (load_cfg_addr_shift_reg_in),
    .shift_en      (cfg_addr_shift_reg_en_in),
    .mosi          (cfg_addr_shift_reg_out)
);
//================ ADDRESS SHIFT REGISTER ==========================
qspi_shift_reg addr_shift_reg (
    .clk         (sclk),
    .rst_n       (h_rstn),
    .data_in     (shift_addr_reg_in),
    .load        (load_addr_in),
    .shift_en    (addr_shift_reg_en_in),
    .use_1_io_lines_in (use_1_io_lines),
    .use_2_io_lines_in (use_2_io_lines),
    .use_4_io_lines_in (use_4_io_lines),
    .qspi_io0      (addr_shift_reg_out0),
    .qspi_io1      (addr_shift_reg_out1),
    .qspi_io2      (addr_shift_reg_out2),
    .qspi_io3      (addr_shift_reg_out3)
);
//========================= DATA SAMPLE REG======================
qspi_data_sample_reg data_sample_reg (
    .clk         (sclk),
    .rst_n       (h_rstn),
    .sample_en   (data_sample_reg_en_in),
    .qspi_io0    (data_sample_reg_in0), // to be updated for multiple IO lines
    .qspi_io1    (data_sample_reg_in1),
    .qspi_io2    (data_sample_reg_in2),
    .qspi_io3    (data_sample_reg_in3),
    .use_1_io_lines_in (use_1_io_lines_sample_reg),
    .use_2_io_lines_in (use_2_io_lines),
    .use_4_io_lines_in (use_4_io_lines),
    .data_out    (data_sample_reg_value) 
);
//====================== DATA SHIFT REG ==========================
qspi_shift_reg data_shift_reg (
    .clk         (sclk),
    .rst_n       (h_rstn),
    .data_in     (wr_buffr_rd_data_in),
    .load        (load_shift_data_en_in), // Load when sampling starts
    .shift_en    (data_shift_reg_en_in), // Shift when sampling
    .use_1_io_lines_in (use_1_io_lines),
    .use_2_io_lines_in (use_2_io_lines),
    .use_4_io_lines_in (use_4_io_lines),
    .qspi_io0      (data_shift_reg_out0),
    .qspi_io1      (data_shift_reg_out1),
    .qspi_io2      (data_shift_reg_out2),
    .qspi_io3      (data_shift_reg_out3)
);
//================= SAMPLE REG IO1 SELECT LOGIC ====================
always_comb begin
    if (sel_sample_1_line_in == 'b1) begin
        use_1_io_lines_sample_reg = 'b1;
    end else begin
        use_1_io_lines_sample_reg = use_1_io_lines;
    end
end


//============== IO0 SEL MUX ============================

// 1. Logic to determine what to do (Procedural Block)
always_comb begin
    // Defaults to prevent latches
    io0_out_val = 1'b0; 
    io0_oe      = 1'b0; 
    data_sample_reg_in0 = 1'b0;
    case (io0_sel_in)
        3'b000: begin
            io0_oe = 1'b0;        // High-Z state
        end
        
        3'b001: begin
            io0_out_val = cfg_addr_shift_reg_out;
            io0_oe      = 1'b1;   // Enable Output
        end
        3'b010: begin
            io0_out_val = cmd_shift_reg_out;
            io0_oe      = 1'b1;   // Enable Output
        end
        3'b011: begin
            io0_out_val = addr_shift_reg_out0;
            io0_oe      = 1'b1;   // Enable Output
        end
        3'b100: begin
            io0_oe = 1'b0;                   // Disable Output (Input Mode)
            data_sample_reg_in0 = io0_inout; // Read FROM the pin
        end
        3'b101: begin
            io0_out_val = data_shift_reg_out0;
            io0_oe      = 1'b1;   // Enable Output
        end
        
        default: io0_oe = 1'b0;
    endcase
end
// 2. The Physical Tri-state Driver (Continuous Assignment)
// This is the ONLY legal way to drive an inout wire
assign io0_inout = (io0_oe) ? io0_out_val : 1'bz;
//============== IO1 SEL MUX ============================

// 1. Control Logic
always_comb begin
    // Defaults to prevent latches
    io1_out_val = 1'b0;
    io1_oe      = 1'b0;
    data_sample_reg_in1 = 1'b0;
    case (io1_sel_in)
        2'b00: begin
            io1_oe = 1'b0;        // High-Z
        end
        2'b01: begin
            io1_out_val = addr_shift_reg_out1;
            io1_oe      = 1'b1;   // Enable Output
        end
        2'b10: begin
            io1_oe = 1'b0;                   // Input Mode
            data_sample_reg_in1 = io1_inout; // Read pin
        end
        2'b11: begin
            io1_out_val = data_shift_reg_out1;
            io1_oe      = 1'b1;   // Enable Output
        end
        
        default: io1_oe = 1'b0;
    endcase
end
// 2. Physical Tri-state Driver
assign io1_inout = (io1_oe) ? io1_out_val : 1'bz;
//============== IO2 SEL MUX ============================

// 1. Control Logic
always_comb begin
    // Defaults to prevent latches
    io2_out_val = 1'b0;
    io2_oe      = 1'b0;
    data_sample_reg_in2 = 1'b0;
    case (io2_sel_in)
        2'b00: begin
            io2_oe = 1'b0;        // High-Z
        end
        2'b01: begin
            io2_out_val = addr_shift_reg_out2;
            io2_oe      = 1'b1;   // Enable Output
        end
        2'b10: begin
            io2_oe = 1'b0;                   // Input Mode
            data_sample_reg_in2 = io2_inout; // Read pin
        end
        2'b11: begin
            io2_out_val = data_shift_reg_out2;
            io2_oe      = 1'b1;   // Enable Output
        end

        default: io2_oe = 1'b0;
    endcase
end
// 2. Physical Tri-state Driver
assign io2_inout = (io2_oe) ? io2_out_val : 1'bz;
//============== IO3 SEL MUX ============================

// 1. Control Logic
always_comb begin
    // Defaults to prevent latches
    io3_out_val = 1'b0;
    io3_oe      = 1'b0;
    data_sample_reg_in3 = 1'b0;
    case (io3_sel_in)
        2'b00: begin
            io3_oe = 1'b0;        // High-Z
        end
        2'b01: begin
            io3_out_val = addr_shift_reg_out3;
            io3_oe      = 1'b1;   // Enable Output
        end
        2'b10: begin
            io3_oe = 1'b0;                   // Input Mode
            data_sample_reg_in3 = io3_inout; // Read pin
        end
        2'b11: begin
            io3_out_val = data_shift_reg_out3;
            io3_oe      = 1'b1;   // Enable Output
        end

        default: io3_oe = 1'b0;
    endcase
end
// 2. Physical Tri-state Driver
assign io3_inout = (io3_oe) ? io3_out_val : 1'bz;
//============== FLASH ADDR CAL ===========================
always_comb begin

    if (flash_addr_len_in == 2'b01) begin
        addr_of_4B_out = 'b1;

    end else begin
        addr_of_4B_out = 'b0;
    end
    //-------------------- COUNT LIMIT FOR ADDRESS BITS----------------
    if (flash_addr_len_in == 'b00 && use_1_io_lines == 'b1) begin
        addr_count_value = 5'd24;
    end else if (flash_addr_len_in == 'b01 && use_1_io_lines == 'b1) begin
        addr_count_value = 5'd32;
    end else if (flash_addr_len_in == 'b00 && use_4_io_lines == 'b1) begin
        addr_count_value = 5'd6;
    end else if (flash_addr_len_in == 'b01 && use_4_io_lines == 'b1) begin
        addr_count_value = 5'd8;
    end else begin
        addr_count_value = 5'd0;
    end
end
    
//============= IO LINES CAL ============================
always_comb begin
    if (no_io_lines_use_in == 2'b00) begin          // SINGLE IO MODE
        use_1_io_lines = 1'b1;
        use_2_io_lines = 1'b0;
        use_4_io_lines = 1'b0;
    end else if (no_io_lines_use_in == 2'b01) begin // DUAL IO MODE
        use_1_io_lines = 1'b0;
        use_2_io_lines = 1'b1;
        use_4_io_lines = 1'b0;
    end else if (no_io_lines_use_in == 2'b10) begin // QUAD IO MODE
        use_1_io_lines = 1'b0;
        use_2_io_lines = 1'b0;
        use_4_io_lines = 1'b1;
    end else begin
        use_1_io_lines = 1'b0;
        use_2_io_lines = 1'b0;
        use_4_io_lines = 1'b0;
    end
end
//======================== DATA BITS AND BEAT LEN COUNT VALUE LOGIC ========================
always_comb begin
    if (use_1_io_lines == 'b1) begin
        data_count_value = 5'd32;
    end else if (use_2_io_lines == 'b1) begin
        data_count_value = 5'd16;
    end else if (use_4_io_lines == 'b1) begin
        data_count_value = 5'd8;
    end else begin
        data_count_value = 5'd0;
    end

    //-------------- LOGIC TO DETERMINE TOTAL BEATS -------------------
    if (!xip_field_in) begin
        total_beats = indrct_bytes_num_in / 'd4;
    end else begin
    if (hburst_reg_in == 3'b000) begin          // SINGLE BEAT
        total_beats = 'd1;
    end else if (hburst_reg_in == 3'b011) begin   // INCR4
        total_beats = 'd4;
    end else if (hburst_reg_in == 3'b101) begin   // INCR8
        total_beats = 'd8;
    end else if (hburst_reg_in == 3'b111) begin   // INCR16
        total_beats = 'd16;
    end 
    end
end


//========================= MUX TO SELECT TARGET COUNT VALUE ==============
always_comb begin
    case (set_count_lim_in)
        2'b00: target_value_counter_in = 5'd8;
        2'b01: target_value_counter_in = addr_count_value;
        2'b10: target_value_counter_in = 5'd4;
        2'b11: target_value_counter_in = data_count_value;

        //----------- to be filled
    endcase
end

//======================== SHIFTED BITS COUNTER ==========================
qspi_counter shifted_bits_counter (
    .clk            (sclk),
    .rst_n          (h_rstn),
    .start_count    (start_count_in),
    .target_count   (target_value_counter_in),
    .count_done     (count_done_out)
);
//======================= BURST COUNTER ==========================
beat_counter burst_counter (
    .clk            (sclk),
    .rst_n          (h_rstn),
    .start_count    (burst_count_en_in),
    .target_count   (total_beats),
    .xip_field_in   (xip_field_in),
    .count_done     (burst_comp_out)
);

//======================== SCLK OUTPUT LOGIC ==========================
always_comb begin
    if (cpol_in == 1'b1) begin
        gen_sclk_mux_in = 1'b1;
    end else begin
        gen_sclk_mux_in = 1'b0;
    end
end
//----------------------------------
always_comb begin
    if (gen_sclk_in == 1'b1) begin
        sclk_out = sclk;
    end else begin
        sclk_out = gen_sclk_mux_in;
    end
end
//==============================================================
//======================== SETUP FLAG LOGIC =====================
always_ff @(posedge sclk or negedge h_rstn) begin
    if (!h_rstn) begin
        setup_cmd_sent_out <= 'b0;
    end else begin
        if (set_setup_flag_in) begin
            setup_cmd_sent_out <= 'b1;
        end
    end
end





endmodule