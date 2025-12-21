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
    input logic flash_addr_len_in,
    input logic no_io_lines_use_in,
    input logic cpol_in,
    input logic [31:0] haddr_in,
    //============= OUTPUTS TO QSPI CONT==================
    output logic sclk_out_cont,  // to TOP
    output logic addr_of_4B_out,
    output logic use_1_io_lines_out,
    output logic use_2_io_lines_out,
    output logic use_4_io_lines_out,
    output logic count_done_out,

    //============= INPUTS FROM QSPI CONT ================
    input logic load_cmd_in,
    input logic load_addr_in,
    input logic load_cfg_addr_shift_reg_in,
    input logic gen_sclk_in,
    input logic [1:0] cmd_sel_in,
    input logic cmd_shift_reg_en_in,
    input logic load_cfg_addr_shift_reg_in,
    input logic cfg_addr_shift_reg_en_in,
    input logic start_count_in,
    input logic [1:0] set_count_lim_in,
    input logic [2:0] io0_sel_in,
    input logic [1:0] io1_sel_in,
    input logic [1:0] io2_sel_in,
    input logic [1:0] io3_sel_in,
    input logic addr_shift_reg_en_in,
    input logic data_sample_reg_en_in,




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
logic [31:0] data_sample_reg_out;
logic [4:0] addr_count_value;
logic [4:0] data_count_value;

logic data_sample_reg_in0;
logic data_sample_reg_in1;
logic data_sample_reg_in2;
logic data_sample_reg_in3;


assign use_1_io_lines_out = use_1_io_lines;
assign use_2_io_lines_out = use_2_io_lines;
assign use_4_io_lines_out = use_4_io_lines;
assign sclk_out_cont = sclk;                 // SCLK for QSPI CONTROLLER

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
        2'b00: cmd_shift_reg_data_in = 8'hEC;  // QUAD READ FOR 4 BYTE ADDR SPACE
        2'b01: cmd_shift_reg_data_in = 8'h13;  // SINGLE READ FOR 4 BYTE ADDR SPACE
        2'b10: cmd_shift_reg_data_in = 8'hEB;  // QUAD READ FOR 3 BYTE ADDR SPACE
        2'b11: cmd_shift_reg_data_in = 8'h03;  // SINGLE READ FOR 3 BYTE ADDR SPACE
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
qspi_addr_shift_reg addr_shift_reg (
    .clk         (sclk),
    .rst_n       (h_rstn),
    .data_in     (haddr_in),
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
    .use_1_io_lines_in (use_1_io_lines),
    .use_2_io_lines_in (use_2_io_lines),
    .use_4_io_lines_in (use_4_io_lines),
    .data_out    (data_sample_reg_out) // ------> to be updated
);

//============== IO0 SEL MUX ============================
always_comb begin
    case (io0_sel_in)
        3'b000: io0_inout = 1'bz;
        3'b001: io0_inout = cfg_addr_shift_reg_out;
        3'b010: io0_inout = cmd_shift_reg_out;
        3'b011: io0_inout = addr_shift_reg_out0;
        3'b100: data_sample_reg_in0 = io0_inout;
        //------------- TBD
    endcase
    
end
//============== IO1 SEL MUX ============================
always_comb begin
    case (io1_sel_in)
        2'b00: io1_inout = 1'bz;
        2'b01: io1_inout = addr_shift_reg_out1;
        2'b10: data_sample_reg_in1 = io1_inout;
        //------------- TBD
    endcase
end
//============== IO2 SEL MUX ============================
always_comb begin
    case (io2_sel_in)
        2'b00: io2_inout = 1'bz;
        2'b01: io2_inout = addr_shift_reg_out2;
        2'b10: data_sample_reg_in2 = io2_inout;
        //------------- TBD
    endcase
end
//============== IO3 SEL MUX ============================
always_comb begin
    case (io3_sel_in)
        2'b00: io3_inout = 1'bz;
        2'b01: io3_inout = addr_shift_reg_out3;
        2'b10: data_sample_reg_in3 = io3_inout;
        //------------- TBD
    endcase
end
//============== FLASH ADDR CAL ===========================
always_comb begin

    if (flash_addr_len_in == 2'b01) begin
        addr_of_4B_out = 'b1;

    end else begin
        addr_of_4B_out = 'b0;
    end
    //-------------------- COUNT LIMIT FOR ADDRESS BITS----------------
    if (flash_addr_len_in == 'b00 && use_1_io_lines = 'b1) begin
        addr_count_value = 5'd24;
    end else if (flash_addr_len_in == 'b01 && use_1_io_lines = 'b1) begin
        addr_count_value = 5'd32;
    end else if (flash_addr_len_in == 'b00 && use_4_io_lines = 'b1) begin
        addr_count_value = 5'd6;
    end else if (flash_addr_len_in == 'b01 && use_4_io_lines = 'b1) begin
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
//======================== DATA BITS COUNT VALUE LOGIC ========================
always_comb begin
    if (use_1_io_lines = 'b1) begin
        data_count_value = 5'd32;
    end else if (use_2_io_lines = 'b1) begin
        data_count_value = 5'd16;
    end else if (use_4_io_lines = 'b1) begin
        data_count_value = 5'd8;
    end else begin
        data_count_value = 5'd0;
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


//======================== SCLK OUTPUT LOGIC ==========================
always_comb begin
    if (cpol_in = 1'b1) begin
        gen_sclk_mux_in = 1'b1;
    end else begin
        gen_sclk_mux_in = 1'b0;
    end
end
//----------------------------------
always_comb begin
    if (gen_sclk_in = 1'b1) begin
        sclk_out = sclk;
    end else begin
        sclk_out = gen_sclk_mux_in;
    end
end
//==============================================================






endmodule