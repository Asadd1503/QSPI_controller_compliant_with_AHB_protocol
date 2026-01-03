module qspi_top (
    //=============INPUTS ===================
    input logic         h_clk,
    input logic         h_rstn,
    input logic [31:0]  h_wdata,
    input logic [31:0]  h_addr,
    input logic [2:0]   h_burst,
    input logic [1:0]   h_trans,
    input logic         h_write,
    input logic         h_sel,
    //============= OUTPUTS ==================
    output logic        h_ready,
    output logic [1:0]  h_resp,
    output logic [31:0] h_rdata,
    output logic        cs_n,
    output logic        sclk,
    inout logic         io0,
    inout logic         io1,
    inout logic         io2,
    inout logic         io3,
    //============== TEST sIGNALS ==============
    output logic        send_data,
    output logic        QSPIbusy
);

logic cfg_reg_wr;
//logic enter_xip_mode;
//logic cfg_reg_wr_en;
logic load_h_addr;
logic load_h_burst;
//logic clk_div;
logic qspi_busy;
logic start_new_xip_seq;
logic enter_xip_mode;
logic [7:0] clk_div;
logic sclk_cont;
logic [1:0] flash_addr_len;
logic [1:0] no_io_lines_use;
logic cpol, cpha;
logic addr_of_4B;
logic use_1_io_lines;
logic use_2_io_lines;
logic use_4_io_lines;
logic load_cmd;
logic load_addr;
logic [2:0] cmd_sel;
logic gen_sclk;
logic load_cfg_addr_shift_reg;
logic cfg_addr_shift_reg_en;
logic cmd_shift_reg_en;
logic [2:0] io0_sel;
logic [1:0] io1_sel;
logic [1:0] io2_sel;
logic [1:0] io3_sel;
logic start_count;
logic [1:0] set_count_lim;
logic count_done;
logic [31:0] haddr;
logic [2:0] hburst;
logic addr_shift_reg_en;
logic data_sample_reg_en;
logic [31:0] data_sample_reg;
logic wr_rd_buffer_en;
logic rst_buffr_n;
logic rd_buffr_full;
logic burst_count_en;
logic burst_comp;
logic rst_rd_fifo;
logic non_seq, seq, idle, busy;
logic rd_fifo_empty;
logic rd_buffr_rd_en;
logic break_seq;
logic [31:0] rd_buffr_data_out;
logic [31:0] wr_buffr_wr_data;
logic wr_buffr_wr_en;
logic wr_buffr_full;
logic enter_indrct_mode;
logic tx_data_valid;
logic start_indrct_mode;
logic [31:0] addr_reg_value;
logic sel_shift_addr_reg;
logic [7:0] cmd_reg_value;
logic indrct_wr;
logic sel_sample_1_line;
logic set_done_flag;
logic set_setup_flag;
logic wr_buffr_empty;
logic wr_buffr_rd_en;
logic [31:0] wr_buffr_rd_data;
logic load_shift_data_en;
logic data_shift_reg_en;
logic [7:0] indrct_bytes_num;
logic wr_rx_reg;
//assign sclk_out = sclk;
assign QSPIbusy = qspi_busy;

slave_datapath u_slave_datapath (
    //============= INPUTS FROM TOP ==================
    .h_clk              (h_clk),
    .h_rstn             (h_rstn),
    .h_wdata            (h_wdata),
    .h_addr             (h_addr),
    .h_burst            (h_burst),
    .h_trans            (h_trans),
    .h_write            (h_write),
    .h_sel              (h_sel),
    //============= OUTPUTS TO TOP ==================
    .h_rdata            (h_rdata),
    .h_resp             (h_resp),
    //.h_rdata_out        (h_rdata),
    //============== OUTPUTS TO SLAVE CONTROLLER ==============
    //.cfg_reg_wr         (cfg_reg_wr),
    .enter_xip_mode     (enter_xip_mode),
    .non_Seq_out        (non_seq),
    .seq_out            (seq),
    .idle_out           (idle),
    .busy_out           (busy),
    .tx_data_valid_out  (tx_data_valid),
    .enter_indrct_mode_out (enter_indrct_mode),
    //============== INPUTS FROM SLAVE CONTROLLER ==============
    //.cfg_reg_wr_en      (cfg_reg_wr_en),
    .load_h_addr        (load_h_addr),
    .load_h_burst       (load_h_burst),
    .wr_rx_reg_in       (wr_rx_reg),
    //============== OUTPUTS TO QSPI DATAPATH ==============
    .clk_div_out        (clk_div),
    .flash_addr_len_out (flash_addr_len),
    .no_io_lines_use_out (no_io_lines_use),
    .cpol_out            (cpol),
    .haddr_out            (haddr),
    .hburst_reg_out      (hburst),
    .addr_reg_out       (addr_reg_value),
    .cmd_reg_out        (cmd_reg_value),
    .indrct_bytes_num_out (indrct_bytes_num),
    //================= INPUTS FROM QSPI CONTROLLER ==============
    .set_done_flag_in   (set_done_flag),
    //=============== OUTPUTS TO QSPI CONTROLLER =================
    .cpha_out           (cpha),
    .indrct_wr_out      (indrct_wr),
    .xip_field_out      (xip_field),
    //================ INPUTS FROM READ BUFFER =================
    .rd_buffr_data_in   (rd_buffr_data_out),
    //==================== OUTPUTS TO WRITE BUFFER ========================
    .wr_buffr_wr_data_out (wr_buffr_wr_data)
);
slave_controller u_slave_controller (
    //============= INPUTS FROM TOP =================
    .h_clk              (h_clk),
    .h_rstn             (h_rstn),
    //============= OUTPUTS TO TOP =================
    .h_ready            (h_ready),
    //============== INPUTS FROM SLAVE DATAPATH ==============
    //.cfg_reg_wr         (cfg_reg_wr),
    .enter_xip_mode     (enter_xip_mode),
    .non_seq_in         (non_seq),
    .seq_in             (seq),
    .idle_in            (idle),
    .busy_in            (busy),
    .tx_data_valid_in   (tx_data_valid),
    .enter_indrct_mode_in (enter_indrct_mode),
    .xip_field_in       (xip_field),
    //============== OUTPUTS TO SLAVE DATAPATH ==============
    //.cfg_reg_wr_en      (cfg_reg_wr_en),
    .load_h_addr        (load_h_addr),
    .load_h_burst       (load_h_burst),
    .wr_rx_reg_out      (wr_rx_reg),
    //============== OUTPUTS TO QSPI CONTROLLER==============
    .start_new_xip_seq  (start_new_xip_seq),
    .break_seq_out      (break_seq),
    .start_indrct_mode_out (start_indrct_mode),
    //==============INPUTS FROM QSPI CONT ================
    .qspi_busy_in       (qspi_busy),
    //===============OUTPUTS TO READ FIFO ==================
    .rst_rd_fifo_out    (rst_rd_fifo),
    .rd_buffr_rd_en_out (rd_buffr_rd_en),
    //=============== INPUTS FROM READ FIFO ==================
    .rd_fifo_empty_in       (rd_fifo_empty),
    //=============== OUTPUTS TO WRITE BUFFER ==================
    .wr_buffer_wr_en_out    (wr_buffr_wr_en),
    //=============== INPUTS FROM WRITE BUFFER ==================
    .wr_buffr_full_in       (wr_buffr_full)


);
qspi_datapath u_qspi_datapath (
    //============= INPUTS FROM ToP =================
    .h_clk          (h_clk),
    .h_rstn         (h_rstn),
    //============== OUTPUTS TO TOP ==================
    .sclk_out       (sclk),
    .io0_inout        (io0),
    .io1_inout        (io1),
    .io2_inout        (io2),
    .io3_inout        (io3),
    //=============== INPUTS FROM SLAVE DATAPATH ==============
    .clk_div_in         (clk_div),
    .flash_addr_len_in (flash_addr_len),
    .no_io_lines_use_in (no_io_lines_use),
    .cpol_in            (cpol),
    .haddr_in           (haddr),
    .hburst_reg_in       (hburst),
    .addr_reg_in        (addr_reg_value),
    .cmd_reg_in         (cmd_reg_value),
    .xip_field_in       (xip_field),
    .indrct_bytes_num_in (indrct_bytes_num),
    //=============INPUTS FROM QSPI CONT ===============
    .load_cmd_in       (load_cmd),
    .load_addr_in      (load_addr),
    .load_cfg_addr_shift_reg_in (load_cfg_addr_shift_reg),
    .cmd_sel_in        (cmd_sel),
    .gen_sclk_in       (gen_sclk),
    .cmd_shift_reg_en_in (cmd_shift_reg_en),
    .cfg_addr_shift_reg_en_in (cfg_addr_shift_reg_en),
    .io0_sel_in        (io0_sel),
    .io1_sel_in        (io1_sel),
    .io2_sel_in        (io2_sel),
    .io3_sel_in        (io3_sel),
    .start_count_in    (start_count),
    .set_count_lim_in  (set_count_lim),
    .addr_shift_reg_en_in (addr_shift_reg_en),
    
    .data_sample_reg_en_in (data_sample_reg_en),
    .burst_count_en_in (burst_count_en),
    .sel_shift_addr_reg_in (sel_shift_addr_reg),
    .sel_sample_1_line_in (sel_sample_1_line),
    .set_setup_flag_in (set_setup_flag),
    .load_shift_data_en_in (load_shift_data_en),
    .data_shift_reg_en_in (data_shift_reg_en),
    //============= OUTPUTS TO QSPI CONT==================
    .sclk_out_cont       (sclk_cont),
    .addr_of_4B_out (addr_of_4B),
    .use_1_io_lines_out (use_1_io_lines),
    .use_2_io_lines_out (use_2_io_lines),
    .use_4_io_lines_out (use_4_io_lines),
    .burst_comp_out    (burst_comp),
    .count_done_out    (count_done),
    .setup_cmd_sent_out (sent_setup_cmd),
    //============== OUTPUTS TO READ BUFFER =======================
    .data_sample_reg_out (data_sample_reg),
    //===================== INPUTS FROM WRITE BUFFER ===============
    .wr_buffr_rd_data_in (wr_buffr_rd_data)
    

);
qspi_cont u_qspi_cont (
    //============= INPUTS FROM TOP =================
    .h_rstn                 (h_rstn),
    //============= OUTPUTS TO TOP =================
    .cs_n_out                 (cs_n),
    .send_data_out           (send_data),
     //=============INPUTS FROM AHB SLAVE CONT===================
    .start_new_xip_seq      (start_new_xip_seq),
    .break_seq_in           (break_seq),
    .start_indrct_mode_in   (start_indrct_mode),
    //==============INPUTS FROM SLAVE DATAPATH ==============
    .cpha_in                (cpha),
    .indrct_wr_in           (indrct_wr),
    .xip_field_in           (xip_field),
    //============== OUTPUTS TO SLAVE DATAPATH ==============
    .set_done_flag_out      (set_done_flag),
    //============= OUTPUTS TO AHB SLAVE CONT===================
    .qspi_busy_out          (qspi_busy),
   
    //============== INPUTS FROM QSPI DATAPATH =============
    .sclk_in                 (sclk_cont),
    .addr_of_4B_in           (addr_of_4B),
    .use_1_io_lines_in       (use_1_io_lines),
    .use_2_io_lines_in       (use_2_io_lines),
    .use_4_io_lines_in       (use_4_io_lines),
    .count_done_in          (count_done),
    .burst_comp_in          (burst_comp),
    .sent_setup_cmd_in      (sent_setup_cmd),
    //============= OUTPUTS TO QSPI DATAPATH =============
    .load_cmd_out             (load_cmd),
    .load_addr_out            (load_addr),
    .load_cfg_addr_shift_reg_out (load_cfg_addr_shift_reg),
    .cmd_sel_out              (cmd_sel),
    .gen_sclk_out             (gen_sclk),
    .cfg_addr_shift_reg_en_out (cfg_addr_shift_reg_en),
    .cmd_shift_reg_en_out     (cmd_shift_reg_en),
    .io0_sel_out               (io0_sel),
    .io1_sel_out                (io1_sel),
    .io2_sel_out               (io2_sel),
    .io3_sel_out                (io3_sel),
    .start_count_out           (start_count),
    .set_count_lim_out         (set_count_lim),
    .addr_shift_reg_en_out     (addr_shift_reg_en),
    .data_sample_reg_en_out    (data_sample_reg_en),
    .burst_count_en_out        (burst_count_en),
    .sel_shift_addr_reg_out    (sel_shift_addr_reg),
    .sel_sample_1_line_out    (sel_sample_1_line),
    .set_setup_flag_out        (set_setup_flag),
    .load_shift_data_en_out   (load_shift_data_en),
    .data_Shift_reg_en_out   (data_shift_reg_en),
    //============== OUTPUTS TO READ BUFFER =======================
    .wr_rd_buffr_en_out        (wr_rd_buffer_en),
    //===================== INPUT FROM READ BUFFER ========================
    .rd_buffr_full_in          (rd_buffr_full),
    //========================INPUTS FROM WRITE BUFFER ========================
    .wr_buffr_empty_in      (wr_buffr_empty),
    //======================== OUTPUTS TO WRITE BUFFER ==============
    .wr_buffr_rd_en_out        (wr_buffr_rd_en)

    
    

);
//====================== READ BUFFER ==========================
sync_fifo #(
    .DATA_WIDTH (32),
    .FIFO_DEPTH (16)
) read_buffer (
    .clk            (h_clk),
    // INPUT FROM SLAVE CONTROLLER
    .rst_n          (rst_rd_fifo),
    // Write Side
    .wr_en       (wr_rd_buffer_en),
    .wr_data        (data_sample_reg),
    
    .full           (rd_buffr_full), 
    // Read Side
    .rd_data       (rd_buffr_data_out),
    .rd_en        (rd_buffr_rd_en),
    .empty          (rd_fifo_empty)  
);
//====================== READ BUFFER ==========================
sync_fifo #(
    .DATA_WIDTH (32),
    .FIFO_DEPTH (64)        // 256/4 = 64 words
) write_buffer (
    .clk            (h_clk),
    .rst_n          (h_rstn),
    // Write Side
    .wr_data        (wr_buffr_wr_data),
    .wr_en          (wr_buffr_wr_en),
    .full           (wr_buffr_full), 
    // Read Side
    .rd_data        (wr_buffr_rd_data),
    .rd_en          (wr_buffr_rd_en),
    .empty          (wr_buffr_empty)  
);

endmodule