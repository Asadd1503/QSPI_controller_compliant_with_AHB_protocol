typedef enum logic [3:0] {
    IDLE =          4'd0,
    CFG_REG_WRITE = 4'd1,
    LOAD =          4'd2,

} state_t;

module salve_controller (
    //============= INPUTS =================
    input logic h_clk,
    input logic h_rstn,
    //============= OUTPUTS ================
    output logic h_ready,
    //============== INPUTS FROM DATAPATH ==============
    input logic cfg_reg_wr,
    input logic enter_xip_mode,
    //============== OUTPUTS TO DATAPATH ==============
    output logic cfg_reg_wr_en,
    output logic load_h_addr,
    output logic load_h_burst,

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
            if (cfg_reg_wr) begin
                n_state = CFG_REG_WRITE;
            end 
            else if (enter_xip_mode) begin
                n_state = LOAD;
            end
            else begin
                n_state = IDLE;
            end
            

        end 

    endcase
end
//============ OUTPUT LOGIC ====================
always_comb begin
    h_ready          = 'b0; 
    cfg_reg_wr_en    = 'b0;
    load_h_addr       = 'b0;
    load_h_burst      = 'b0;
    case (c_state)
        IDLE: begin
            h_ready = 'b1;
        end
        CFG_REG_WRITE: begin
            cfg_reg_wr_en = 'b1;
        end
        LOAD: begin
            load_h_addr  = 'b1;
            load_hburst = 'b1;
        end


    endcase
end






endmodule