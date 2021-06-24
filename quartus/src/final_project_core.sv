module final_project_core (
    input i_rst_n,
	input i_clk,
    input i_clk12M,

    input i_key_0,
	input i_key_1,
	input i_key_2,

    input udp_ready,


    // SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,

    // I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,

    output [8:0] led_g,

    output [6:0] hex0,
    output [6:0] hex1
);


logic [2:0] state_r, state_w;

logic [19:0] addr_record;
logic [19:0] addr_read;

logic [7:0] led_reg_r, led_reg_w;
logic [15:0] data_record;

// assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_read[19:0];
// assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
// assign play_data   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

// assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign led_g = led_reg_r;

localparam S_IDLE = 3'd0;
localparam S_TMP  = 3'd1;
localparam S_RECD = 3'd3;

always_comb begin
    state_w = state_r;
    led_reg_w = led_reg_r;

    case (state_r)
        S_IDLE: begin
            led_reg_w = 8'b00110000;
            
        end
        default: begin
            state_w = state_r;
        end
    endcase
end

always_ff @( posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        led_reg_r <= 8'b0;

    end
    else begin
        state_r <= state_w;
        led_reg_r <= led_reg_w;
        
    end
    
end


    
endmodule