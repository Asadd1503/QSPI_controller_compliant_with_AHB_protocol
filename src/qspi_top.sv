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
    output logic        io0,
    output logic        io1,
    output logic        io2,
    output logic        io3
);

logic cfg_reg_wr;
logic enter_xip_mode;
logic cfg_reg_wr_en,
logic load_h_addr;
logic load_h_burst;
logic clk_div;
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
logic [1:0] cmd_sel;
logic gen_sclk;
logic load_cfg_addr_shift_reg;
logic cfg_addr_shift_reg_en;
logic [1:0] io0_sel;
logic [1:0] io1_sel;
logic [1:0] io2_sel;
logic [1:0] io3_sel;
logic start_count;
logic [1:0] set_count_lim;
logic count_done;
logic [31:0] haddr;
logic addr_shift_reg_en;




//assign sclk_out = sclk;

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
    .h_ready            (h_ready),
    .h_resp             (h_resp),
    .h_rdata            (h_rdata),
    //============== OUTPUTS TO SLAVE CONTROLLER ==============
    .cfg_reg_wr         (cfg_reg_wr),
    .enter_xip_mode     (enter_xip_mode),
    //============== INPUTS FROM SLAVE CONTROLLER ==============
    .cfg_reg_wr_en      (cfg_reg_wr_en),
    .load_h_addr        (load_h_addr),
    .load_h_burst       (load_h_burst),
    //============== OUTPUTS TO QSPI DATAPATH ==============
    .clk_div_out        (clk_div),
    .flash_addr_len_out (flash_addr_len),
    .no_io_lines_use_out (no_io_lines_use),
    .cpol_out            (cpol),
    .haddr_out            (haddr),
    
    //=============== OUTPUTS TO QSPI CONTROLLER =================
    .cpha_out           (cpha),

);
slave_controller u_slave_controller (
    //============= INPUTS FROM TOP =================
    .h_clk              (h_clk),
    .h_rstn             (h_rstn),
    //============= OUTPUTS TO TOP =================
    .h_ready            (h_ready),
    //============== INPUTS FROM SLAVE DATAPATH ==============
    .cfg_reg_wr         (cfg_reg_wr),
    .enter_xip_mode     (enter_xip_mode),
    //============== OUTPUTS TO SLAVE DATAPATH ==============
    .cfg_reg_wr_en      (cfg_reg_wr_en),
    .load_h_addr        (load_h_addr),
    .load_h_burst       (load_h_burst),
    //============== OUTPUTS TO QSPI DATAPAH ==============
    .start_new_xip_seq  (start_new_xip_seq),
    //==============INPUTS FROM QSPI CONT ================
    .qspi_busy_in       (qspi_busy),


);
qspi_datapath u_qspi_datapath (
    //============= INPUTS FROM ToP =================
    .h_clk          (h_clk),
    .h_rstn         (h_rstn),
    //============== OUTPUTS TO TOP ==================
    .sclk_out       (sclk),
    .io0_out        (io0),
    .io1_out        (io1),
    .io2_out        (io2),
    .io3_out        (io3),
    //=============== INPUTS FROM SLAVE DATAPATH ==============
    .clk_div_in         (clk_div),
    .flash_addr_len_in (flash_addr_len),
    .no_io_lines_use_in (no_io_lines_use),
    .cpol_in            (cpol),
    .haddr_in           (haddr),
    //=============INPUTS FROM QSPI CONT ===============
    .load_cmd_in       (load_cmd),
    .load_addr_in      (load_addr),
    .load_cfg_addr_shift_reg_in (load_cfg_addr_shift_reg),
    .cmd_sel_in        (cmd_sel),
    .gen_sclk_in       (gen_sclk),
    
    .cfg_addr_shift_reg_en_in (cfg_addr_shift_reg_en),
    .io0_sel_in        (io0_sel),
    .io1_sel_in        (io1_sel),
    .io2_sel_in        (io2_sel),
    .io3_sel_in        (io3_sel),
    .start_count_in    (start_count),
    .set_count_lim_in  (set_count_lim),
    .addr_shift_reg_en_in (addr_shift_reg_en),

    //============= OUTPUTS TO QSPI CONT==================
    .sclk_out_cont       (sclk_cont),
    .addr_of_4B_out (addr_of_4B),
    .use_1_io_lines_out (use_1_io_lines),
    .use_2_io_lines_out (use_2_io_lines),
    .use_4_io_lines_out (use_4_io_lines),

);
qspi_cont u_qspi_cont (
    //============= INPUTS FROM TOP =================
    .h_rstn                 (h_rstn),
    //============= OUTPUTS TO TOP =================
    .cs_n_out                 (cs_n),
     //=============INPUTS FROM AHB SLAVE CONT===================
    .start_new_xip_seq      (start_new_xip_seq),
    //==============INPUTS FROM SLAVE DATAPATH ==============
    .cpha_in                (cpha),
    //============= OUTPUTS TO AHB SLAVE CONT===================
    .qspi_busy_out          (qspi_busy),
   
    //============== INPUTS FROM QSPI DATAPATH =============
    .sclk_in                 (sclk_cont),
    .addr_of_4B_in           (addr_of_4B),
    .use_1_io_lines_in       (use_1_io_lines),
    .use_2_io_lines_in       (use_2_io_lines),
    .use_4_io_lines_in       (use_4_io_lines),
    //============= OUTPUTS TO QSPI DATAPATH =============
    .load_cmd_out             (load_cmd),
    .load_addr_out            (load_addr),
    .load_cfg_addr_shift_reg_out (load_cfg_addr_shift_reg),
    .cmd_sel_out              (cmd_sel),
    .gen_sclk_out             (gen_sclk),
    .cfg_addr_shift_reg_en_out (cfg_addr_shift_reg_en),
    .io0_sel_out               (io0_sel),
    .io1_sel_out                (io1_sel),
    .io2_sel_out               (io2_sel),
    .io3_sel_out                (io3_sel),
    .start_count_out           (start_count),
    .set_count_lim_out         (set_count_lim),
    .addr_shift_reg_en_out     (addr_shift_reg_en)

    
    

);

endmodule