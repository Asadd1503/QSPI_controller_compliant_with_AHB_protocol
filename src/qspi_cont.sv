typedef enum logic [5:0] {
    IDLE =          5'd0,
    LOAD =          5'd1,
    SHIFT_SETUP_CMD=5'd2,
    SHIFT_CMD      =5'd3,
    COUNT_SETUP_CMD=5'd4,
    COUNT_CMD     = 5'd5,


    

} state_t;

module qspi_cont(
    //============= INPUTS FROM TOP =================
    input logic h_rstn,
    //============= OUTPUTS TO TOP =================
    output logic cs_n_out,
    //=============INPUTS FROM AHB SLAVE CONT===================
    input logic start_new_xip_seq,
    //==============INPUTS FROM SLAVE DATAPATH ==============
    input logic cpha_in,
    //============== INPUTS FROM QSPI DATAPATH =============
    input logic sclk,
    input logic addr_of_4B_in,
    input logic use_1_io_lines_in,
    input logic use_2_io_lines_in,
    input logic use_4_io_lines_in,
    input logic count_done_in,

    
    //============= OUTPUTS TO QSPI DATAPATH =============
    
    output logic load_cmd_out,
    output logic laod_addr_out,
    output logic load_cfg_addr_shift_reg_out,
    output logic [1:0] cmd_sel_out,
    output logic gen_sclk_out, ///
    output logic cmd_shift_reg_en_out,
    output logic cfg_addr_shift_reg_en_out,
    output logic [1:0] io0_sel_out,
    output logic [1:0] io1_sel_out,
    output logic [1:0] io2_sel_out,
    output logic [1:0] io3_sel_out,
    output logic start_count_out,
    output logic [1:0] set_count_lim_out,
    output logic addr_shift_reg_en_out,

    

    //============= OUTPUTS TO AHB SLAVE CONT===================
    output logic qspi_busy_out,

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
            io0_sel_out = 'b00;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        COUNT_SETUP_CMD: begin
            cfg_addr_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b00;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        SHIFT_CMD: begin
            cmd_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b01;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        COUNT_CMD: begin
            cmd_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b01;
            start_count_out = 'b1;
            set_count_lim_out = 'b00;
        end
        ADDR_SHIFT: begin
            addr_shift_reg_en_out = 'b1;
            gen_sclk_out = 'b1;
            cs_n_out = 'b0;
            io0_sel_out = 'b10;
            io1_sel_out = 'b01;
            io2_sel_out = 'b01;
            io3_sel_out = 'b01;
            start_count_out = 'b1;
            set_count_lim_out = 'b01;
        end






    endcase
end

endmodule 