typedef enum logic [5:0] {
    IDLE =          5'd0,
    LOAD =          5'd1,
    SHIFT_SETUP_CMD=5'd2,
    COUNT_SETUP_CMD=5'd3,
    SHIFT_CMD      =5'd4,
    COUNT_CMD     = 5'd5,
    ADDR_SHIFT     =5'd6,
    ADDR_COUNT     =5'd7,
    DUMMY_CYCLES   =5'd8,
    DATA_SAMPLE     =5'd9,
    DATA_COUNT     =5'd10,
    WRITE_RD_BUFFR=5'd11,
    WAIT           =5'd12,
    ONE_CYCLE_DELAY=5'd13,



    

} state_t;

module qspi_cont(
    //============= INPUTS FROM TOP =================
    input logic h_rstn,
    //============= OUTPUTS TO TOP =================
    output logic cs_n_out,
    //=============INPUTS FROM AHB SLAVE CONT===================
    input logic start_new_xip_seq,
    input logic break_seq_in,
    //==============INPUTS FROM SLAVE DATAPATH ==============
    input logic cpha_in,
    //============== INPUTS FROM QSPI DATAPATH =============
    input logic sclk,
    input logic addr_of_4B_in,
    input logic use_1_io_lines_in,
    input logic use_2_io_lines_in,
    input logic use_4_io_lines_in,
    input logic count_done_in,
    input logic burst_comp_in,

    
    //============= OUTPUTS TO QSPI DATAPATH =============
    
    output logic load_cmd_out,
    output logic laod_addr_out,
    output logic load_cfg_addr_shift_reg_out,
    output logic [1:0] cmd_sel_out,
    output logic gen_sclk_out, ///
    output logic cmd_shift_reg_en_out,
    output logic cfg_addr_shift_reg_en_out,
    output logic [2:0] io0_sel_out,
    output logic [1:0] io1_sel_out,
    output logic [1:0] io2_sel_out,
    output logic [1:0] io3_sel_out,
    output logic start_count_out,
    output logic [1:0] set_count_lim_out,
    output logic addr_shift_reg_en_out,
    output logic data_sample_reg_en_out,
    output logic burst_count_en_out,
    output logic sel_sample_1_line_out,

    

    //============= OUTPUTS TO AHB SLAVE CONT===================
    output logic qspi_busy_out,
    //============= OUTPUTS TO READ BUFFER =====================
    output logic wr_rd_buffr_en_out,
    //================= INPUTS FROM READ BUFFER =====================
    input logic rd_buffr_full_in,

);
state_t c_state, n_state;
//=========== DECLARATIONS AND ASSIGNMENTS ===============
logic rst_n;
assign rst_n = h_rstn;

//==================================================
always_ff @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        c_state <= IDLE;
    end else begin
        c_state <= n_state;
    end
end
//============ NEXT STATE LOGIC =================
always_comb begin
    case (c_state)
        IDLE: begin
            if (start_new_xip_seq) begin
                n_state = LOAD;
            end 
            else begin
                n_state = IDLE;
            end
        LOAD: begin 
            if (addr_of_4B_in = 'b1) begin
                n_state = SHIFT_SETUP_CMD;
            end else begin
                n_state = SHIFT_CMD;
            end
        end
        SHIFT_SETUP_CMD: begin
            n_state = COUNT_SETUP_CMD;
        end
        COUNT_SETUP_CMD: begin
            if (count_done_in) begin
                n_state = SHIFT_CMD;
            end else begin
                n_state = COUNT_SETUP_CMD;
            end
        end
        SHIFT_CMD: begin
            n_state = COUNT_CMD;
        end
        COUNT_CMD: begin
            if (count_done_in) begin
                n_state = ADDR_SHIFT;
            end else begin
                n_state = COUNT_CMD;
            end
        end
        ADDR_SHIFT: begin
            n_state = ADDR_COUNT;
        end
        ADDR_COUNT: begin
            if (count_done_in) begin
                n_state = DUMMY_CYCLES;
            end else begin
                n_state = ADDR_COUNT;
            end
        end
        DUMMY_CYCLES: begin
            if (count_done_in) begin
                n_state = DATA_SAMPLE;
            end else begin
                n_state = DUMMY_CYCLES;
            end
        end
        DATA_SAMPLE: begin
            if (burst_comp_in || break_seq_i ) begin
                n_state = IDLE;
            end else begin
                n_state = DATA_COUNT;
            end
        end
        DATA_COUNT: begin
            if (count_done_in && rd_buffr_full_in) begin
                n_state = WAIT;
            end
            else if (count_done_in) begin
                n_state = WRITE_RD_BUFFR;
            end else begin
                n_state = DATA_COUNT;
            end
        end
        WAIT: begin
            if (!rd_buffr_full_in) begin
                n_state = WRITE_RD_BUFFR;
            end else begin
                n_state = WAIT;
            end
        end
        WRITE_RD_BUFFR: begin
            if (cpha_in = 'b1) begin
                n_state = ONE_CYCLE_DELAY;
            end else begin
                n_state = DATA_SAMPLE;
            end
        end



    end

    endcase
end
//============ OUTPUT LOGIC =================
always_comb begin
    qspi_busy_out = 'b1;
    load_cmd_out  = 'b0;
    load_addr_out = 'b0;
    load_cfg_addr_shift_reg_out = 'b0;
    cmd_shift_reg_en_out = 'b0;
    cfg_addr_shift_reg_en_out = 'b0;
    gen_sclk_out = 'b0;
    io0_sel_out =  'b00;
    io1_sel_out =  'b00;
    io2_sel_out =  'b00;
    io3_sel_out =  'b00;
    start_count_out = 'b0;
    set_count_lim_out = 'b00;
    addr_shift_reg_en_out = 'b0;
    cs_n_out = 'b1;
    data_sample_reg_en_out = 'b0;
    wr_rd_buffr_en_out = 'b0;
    burst_count_en_out = 'b0;
    sel_sample_1_line_out = 'b0;


    case (c_state)
        IDLE: begin
            qspi_busy_out = 'b0;
            cs_n_out = 'b1;
        end
        LOAD: begin
            load_cmd_out       = 'b1;
            load_addr_out      = 'b1;
            load_cfg_addr_shift_reg_out = 'b1;
            cs_n_out           = 'b0;
            if (cpha_in = 'b1) begin
                gen_sclk_out = 'b1;

            end
            if (addr_of_4B_in = 'b1 && use_4_io_lines_in = 'b1) begin
                cmd_sel_out = 'b00;
            end else if (addr_of_4B_in = 'b1 && use_1_io_lines_in = 'b1) begin
                cmd_sel_out = 'b01;
            end else if (addr_of_4B_in = 'b0 && use_4_io_lines_in = 'b1) begin
                cmd_sel_out = 'b10;
            end else if (addr_of_4B_in = 'b0 && use_1_io_lines_in = 'b1) begin
                cmd_sel_out = 'b11;
            end
        end
        SHIFT_SETUP_CMD: begin
            cfg_addr_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b001;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        COUNT_SETUP_CMD: begin
            cfg_addr_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b001;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        SHIFT_CMD: begin
            cmd_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b010;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        COUNT_CMD: begin
            cmd_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b010;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        ADDR_SHIFT: begin
            addr_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b011;
            io1_sel_out = 'b01;
            io2_sel_out = 'b01;
            io3_sel_out = 'b01;
            start_count_out = 'b1;
            set_count_lim_out = 'b01;
        end
        COUNT_ADDR: begin
            addr_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b011;
            io1_sel_out = 'b01;
            io2_sel_out = 'b01;
            io3_sel_out = 'b01;
            start_count_out = 'b1;
            set_count_lim_out = 'b01;
        end
        DUMMY_CYCLES: begin
            cs_n_out = 'b0;
            gen_sclk_out = 'b1;
            start_count_out = 'b1;
            set_count_lim_out = 'b10;
        end
        DATA_SAMPLE: begin
            cs_n_out = 'b0;
            gen_sclk_out = 'b1;
            data_sample_reg_en_out = 'b1;
            io0_sel_out = 'b100;
            io1_sel_out = 'b10;
            io2_sel_out = 'b10;
            io3_sel_out = 'b10;
            start_count_out = 'b1;
            set_count_lim_out = 'b11;
        end
        DATA_COUNT: begin
            cs_n_out = 'b0;
            gen_sclk_out = 'b1;
            data_sample_reg_en_out = 'b1;
            io0_sel_out = 'b100;
            io1_sel_out = 'b10;
            io2_sel_out = 'b10;
            io3_sel_out = 'b10;
            start_count_out = 'b1;
            set_count_lim_out = 'b11;
        end
        WAIT: begin
            cs_n_out = 'b0;
            gen_sclk_out = 'b0;
        end
        ONE_CYCLE_DELAY: begin
            cs_n_out = 'b0;
            gen_sclk_out = 'b1;
        end
        WRITE_RD_BUFFR: begin
            wr_rd_buffr_en_out = 'b1;
            cs_n_out = 'b0;
            gen_sclk_out = 'b0;
            burst_count_en_out = 'b1;
        end
        

            








    endcase
end

endmodule 