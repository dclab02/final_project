// TODO:
// 1. ensure if i need to send finish playing...
// 
module AudPlayerController (
	input   i_rst_n,
	input   i_clk,
	input   i_start,
	input   [20:0] i_speed,
	input   i_daclrck,
	input   [15:0] i_sram_data,
	input	[20:0] i_end_addr, // end address
	output  [15:0] o_dac_data,
	output  [20:0] o_sram_addr,
);


localparam S_IDLE 	= 3'd0;
localparam S_RUN 	= 3'd1;


logic [2:0] state_r, state_w;
logic signed [15:0] out_dac_data;
logic signed [15:0] dac_data_r, dac_data_w;
logic [20:0] addr_counter_r, addr_counter_w;

assign o_sram_addr = addr_counter_r;
assign o_dac_data = out_dac_data;

// [debug]
// assign o_state = state_r;

always_comb begin
	// design your control here
	state_w					= state_r;
	addr_counter_w			= addr_counter_r;
	dac_data_w				= dac_data_r;
	out_dac_data			= 16'b0;

	case (state_r)
		S_IDLE: begin
			addr_counter_w = 21'b0;
			out_dac_data = 16'b0;
			pre_dac_data_w = 16'b0;
			dac_data_w = 16'b0;
			if (i_start) begin
				state_w = S_RUN;
				dac_data_w = i_sram_data;
			end
		end
		S_RUN: begin
			if (i_stop) begin
				state_w = S_IDLE;
			end
			else if (i_pause) begin
				state_w = S_PAUSE;
			end
			else begin
				out_dac_data = dac_data_r;
				dac_data_w = i_sram_data;
				pre_dac_data_w = dac_data_r;
				addr_counter_w = addr_counter_r + i_speed;
				if (addr_counter_r >= i_end_addr) begin
					state_w = S_IDLE;
				end
				else if (i_pause) begin
					state_w = S_PAUSE;
				end
			end
		end
	endcase
end

always_ff @(negedge i_daclrck or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		dac_data_r 					<= 16'b0;
		state_r 					<= S_IDLE;
		addr_counter_r 				<= 21'b0;
	end
	else begin
		dac_data_r 					<= dac_data_w;
		state_r 					<= state_w;
		addr_counter_r 				<= addr_counter_w;
	end
end

endmodule