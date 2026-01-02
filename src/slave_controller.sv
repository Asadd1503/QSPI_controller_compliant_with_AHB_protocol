typedef enum logic [3:0] {
    IDLE =          4'd0,
    //CFG_REG_WRITE = 4'd1,
    LOAD =          4'd1,
    BURST_PHASE =   4'd2,
    BREAK_SEQ =     4'd3,
    READ_DATA =     4'd4,
    TRANSFER_DATA = 4'd5,
    INDIRECT_MODE = 4'd6,
    READ_RD_BUFFER  = 4'd7,
    WRITE_RX_REG  = 4'd8

} state_t;

module slave_controller (
    //============= INPUTS =================
    input logic h_clk,
    input logic h_rstn,
    //============= OUTPUTS ================
    output logic h_ready,
    //============== INPUTS FROM SLAVE DATAPATH ==============
    //input logic cfg_reg_wr,
    input logic enter_xip_mode,
    input logic non_Seq_in,
    input logic seq_in,
    input logic idle_in,
    input logic busy_in,
    input logic tx_data_valid_in,
    input logic enter_indrct_mode_in,
    //============== OUTPUTS TO DATAPATH ==============
    //output logic cfg_reg_wr_en,
    output logic load_h_addr,
    output logic load_h_burst,
    output logic wr_rx_reg_out,
    
    //============== OUTPUTS TO QSPI CONT =============
    output logic start_new_xip_seq,
    output logic break_seq_out,
    output logic start_indrct_mode_out,
    //==============INPUTS FROM QSPI CONT ================
    input logic qspi_busy_in,
    //===============OUTPUTS TO READ FIFO ==================
    output logic rst_rd_fifo_out,
    output logic rd_buffr_rd_en_out,
    //=============== INPUTS FROM READ FIFO ==================
    input logic rd_fifo_empty_in,
    //=============== OUTPUTS TO WRITE BUFFER ==================
    output logic wr_buffer_wr_en_out,
    //=============== INPUTS FROM WRITE BUFFER ==================
    input logic wr_buffr_full_in

);

state_t c_state, n_state;
//=========== DECLARATIONS AND ASSIGNMENTS ===============
logic clk, rst_n;
assign clk   = h_clk;
assign rst_n = h_rstn;


//==================================================
always_ff @(posedge clk or negedge rst_n) begin
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
            if (enter_indrct_mode_in) begin
                n_state = INDIRECT_MODE;
            end
            else if (enter_xip_mode) begin
                n_state = LOAD;
            end
            else if (!rd_fifo_empty_in && !xip_field_in) begin
                n_state = READ_RD_BUFFER;
            end
            else if (!rd_fifo_empty_in && seq_in) begin
                n_state = READ_DATA;
            end
            
            else if (wr_buffr_full_in) begin
                n_state = IDLE;
            end
            else if (tx_data_valid_in) begin
                n_state = TRANSFER_DATA;
            end
            else begin
                n_state = IDLE;
            end
        end
        LOAD: begin
            if (qspi_busy_in) begin
                n_state = BURST_PHASE;
            end else begin
                n_state = LOAD;
            end
        end
        BURST_PHASE: begin
            if (idle_in || non_seq_in) begin
                n_state = BREAK_SEQ;
            end else if (busy_in) begin
                n_state = IDLE;
            end else if (!rd_fifo_empty_in) begin
                n_state = READ_DATA;
            end else begin
                n_state = BURST_PHASE;
            end
        end
        READ_DATA: begin
            n_state = IDLE;
        end
        BREAK_SEQ: begin
            if (qspi_busy_in) begin
                n_state = IDLE;
            end else begin
                n_state = BREAK_SEQ;
            end
        end
        TRANSFER_DATA: begin
            n_state = IDLE;
        end
        INDIRECT_MODE: begin
            if (qspi_busy_in) begin
                n_state = IDLE;
            end else begin
                n_state = INDIRECT_MODE;
            end
        end
        READ_RD_BUFFER: begin
            n_state = WRITE_RX_REG;
        end
            

        

    endcase
end
//============ OUTPUT LOGIC ====================
always_comb begin
    h_ready          = 'b0; 
    //cfg_reg_wr_en    = 'b0;
    load_h_addr       = 'b0;
    load_h_burst      = 'b0;
    start_new_xip_seq = 'b0;
    rst_rd_fifo_out   = 'b0;
    rd_buffr_rd_en_out = 'b0;
    break_seq_out       = 'b0;
    wr_buffer_wr_en_out = 'b0;
    start_indrct_mode_out = 'b0;
    wr_rx_reg_out       = 'b0;
    case (c_state)
        IDLE: begin
            h_ready = 'b1;
        end
        LOAD: begin
            load_h_addr  =      'b1;
            load_h_burst =      'b1;
            start_new_xip_seq = 'b1;
            rst_rd_fifo_out   = 'b1;
        end
        READ_DATA: begin
            rd_buffr_rd_en_out = 'b1;
        end
        BREAK_SEQ: begin
            break_seq_out = 'b1;
        end
        TRANSFER_DATA: begin
            wr_buffer_wr_en_out = 'b1;
        end
        INDIRECT_MODE: begin
            start_indrct_mode_out = 'b1;
        end
        READ_RD_BUFFER: begin
            rd_buffr_rd_en_out = 'b1;
        end
        WRITE_RX_REG: begin
            wr_rx_reg_out = 'b1;
        end
    endcase
end






endmodule