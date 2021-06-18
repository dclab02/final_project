module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,  // Record/Pause
	input i_key_1,  // Play/Pause
	input i_key_2,  // Stop
	// input [3:0] i_speed, // design how user can decide mode on your own
	
	// AudDSP and SRAM
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
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	output [5:0] o_record_time,
	output [5:0] o_play_time,
	output [5:0] o_state,
	// output [5:0] o_state_dsp,
	// functional select switch
	input i_switch_0, // slow_0
	input i_switch_1, // slow_1
	input i_switch_2, // fast
	input i_switch_3, // bit[0]
	input i_switch_4, // bit[1]
	input i_switch_5, // bit[2]
	input i_switch_6, // repeat

	// LCD (optional display)
	input        i_clk_800k,
	inout  [7:0] o_LCD_DATA,
	output       o_LCD_EN,
	output       o_LCD_RS,
	output       o_LCD_RW,
	output       o_LCD_ON,
	output       o_LCD_BLON,

	// LED
	output  [8:0] o_ledg
	// output [17:0] o_ledr
);

// design the FSM and states as you like
localparam S_I2C_INIT   = 2'd0;
localparam S_IDLE       = 2'd1;
localparam S_PLAY       = 2'd2;

logic [2:0] state_r, state_w;
logic i2c_oen;
wire i2c_sdat;
logic [19:0] addr_record;
logic [20:0] play_addr;
logic [15:0] data_record, play_data, dac_data;

logic i2c_init, i2c_init_stat;
logic recd_start, recd_pause, recd_stop;

// relate to Player Controller module
logic [20:0] play_speed;
logic [20:0] end_addr_r, end_addr_w;
/////////////////////////////////////

// relate to Demodulate module
logic start_demodulate, demodulateValid;
logic [7:0] IValue;
logic [7:0] QValue;
logic [8:0] demodulateValue;
//////////////////////////////

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : play_addr[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign play_data   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_ledg = {i_AUD_DACLRCK, 5'b0, play_start,  play_pause, play_stop}; // [DEBUG] This is for testing

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

// relate to Player Controller module
assign play_speed 	= 21'd44;
assign playing     = (state_r == S_PLAY) ? 1'b1 : 1'b0;
assign recd_pause  = (state_r == S_RECD_PAUSE) ? 1'b1 : 1'b0;
assign recd_stop   = (state_r == S_IDLE) ? 1'b1 : 1'b0;
assign play_pause  = (state_r == S_PLAY_PAUSE) ? 1'b1 : 1'b0;
assign play_stop   = (state_r == S_IDLE) ? 1'b1 : 1'b0;
assign play_start  = (state_r == S_PLAY) ? 1'b1 : 1'b0;

// hex display
// timer
logic [5:0] recd_sec_r, recd_sec_w;
logic [23:0] recd_counter_r, recd_counter_w;
assign o_record_time = recd_sec_r;
assign o_play_time =  { 1'b0, play_addr[19:15] }; // to adjust with quick and slow play, so set by play_addr

// state
assign o_state = state_r;

// logic [2:0] dsp_state; // debug
// assign o_state_dsp = dsp_state; // [debug]

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
logic [1:0] i2c_state;

I2CInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_init),
	.o_finished(i2c_init_stat),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen),// you are outputing (you are not outputing only when you are "ack"ing.)
	.o_state(i2c_state)
);

// === AudPlayerController ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudPlayerController controller(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(play_start),
	.i_speed(play_speed),
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(play_data),
	.i_end_addr(end_addr_w),
	.o_dac_data(dac_data),
	.o_sram_addr(play_addr),
);

// [DEBUG]
// logic [15:0] dac_data_tmp;
// assign dac_data_tmp = {play_addr[16],15'b0};

// === Demodulator ===
// input 8bit unsigned IValue and QValue, output 9 bit unsigned Value
Demodulator demodulator(
	.clk(i_clk),
	.start(start_demodulate),
	.I_value(IValue),
	.Q_value(QValue),
	.magnitude_out(demodulateValue),
	.valid(demodulateValid)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(playing), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
// AudRecorder recorder0(
// 	.i_rst_n(i_rst_n), 
// 	.i_clk(i_AUD_BCLK),
// 	.i_lrc(i_AUD_ADCLRCK),
// 	.i_start(recd_start),
// 	.i_pause(recd_pause),
// 	.i_stop(recd_stop),
// 	.i_data(i_AUD_ADCDAT),
// 	.o_address(addr_record),
// 	.o_data(data_record)
// );


// FSM
always_comb begin
	state_w = state_r;
	end_addr_w = end_addr_r;
	recd_counter_w = recd_counter_r;
	recd_sec_w = recd_sec_r;
	recd_start = 1'b0;
	i2c_init = 1'b0;
	case (state_r)
		S_I2C_INIT: begin
			i2c_init = 1'b1;
			if (i2c_init_stat) begin // init done
				i2c_init = 1'b0;
				state_w = S_IDLE;
			end
		end
		S_IDLE: begin		
			recd_sec_w = 6'b0;
			// TODO
		end
		S_CONNECT: begin	
			// TODO
		end
		S_PLAY: begin
			// TODO
		end
		default: 
			state_w = state_r;
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_I2C_INIT;
		end_addr_r <= 21'b0;
		recd_sec_r <= 6'b0;
		recd_counter_r <= 24'b0;
	end
	else begin
        state_r <= state_w;
		end_addr_r <= end_addr_w;
		recd_sec_r <= recd_sec_w;
		recd_counter_r <= recd_counter_w;
	end
end

endmodule