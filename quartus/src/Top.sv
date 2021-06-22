module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,  // Record/Pause
	input i_key_1,  // Play/Pause
	input i_key_2,  // Stop
	// input [3:0] i_speed, // design how user can decide mode on your own
	
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
logic start_demodulate;
logic [7:0] IValue;
logic [7:0] QValue;
logic [8:0] demodulateValue;
//////////////////////////////

// relate to Hardware DataPath
logic datapath_rst_n;
logic [7:0] DValue_RE, QValue_RE, DValue_DE, QValue_DE;
logic [15:0] signalDE, signalFI_in, signalFI_out, signalPL_in;
logic stall;
logic ReceiverValid, DemodulatorValid, FilterValid, PlayerValid;
assign stall = ~ReceiverValid & ~DemodulatorValid & ~FilterValid & ~PlayerValid & ~datapath_rst_n;
//////////////////////////////

assign play_data   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_ledg = {i_AUD_DACLRCK, 5'b0, play_start,  play_pause, play_stop}; // [DEBUG] This is for testing

// relate to Player Controller module
assign play_speed 	= 21'd44;
assign playing     = (state_r == S_PLAY) ? 1'b1 : 1'b0;
assign play_stop   = (state_r == S_IDLE) ? 1'b1 : 1'b0;

// hex display
// timer
// logic [5:0] recd_sec_r, recd_sec_w;
// logic [23:0] recd_counter_r, recd_counter_w;
// assign o_record_time = recd_sec_r;
// assign o_play_time =  { 1'b0, play_addr[19:15] };

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

// === Receiver ===
// TODO
// need output I, Q (8 bit)
// need output datapath rst signal
// need output valid bit

Receiver receiver();


// === Demodulator ===
// input 8bit unsigned IValue and QValue, output 9 bit unsigned Value
// need output valid bit
// need output signal (16 bits)
Demodulator demodulator(
	.clk(i_clk),
	.start(start_demodulate),
	.I_value(IValue),
	.Q_value(QValue),
	.magnitude_out(demodulateValue),
	.valid(DemodulatorValid)
);


// === Filter ===
// input signal (16 bits)
// need output valid bit
// need output signal (16 bits)
Filter filter();


// === AudPlayer ===
// receive signal data and sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(playing), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(signalPL_in), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === Pipeline Registers ===
PipelineRegister_RE_DE RE_DE_reg(
    .i_rst_n(i_AUD_ADCLRCK),
	.i_clk(i_clk),
	.i_stall(stall),
	.i_D_value(DValue_RE),
    .i_Q_value,(QValue_RE) 
    .o_D_value(DValue_DE),
    .o_Q_value(DValue_DE)
);

PipelineRegister_DE_FI　DE_FI_reg(
    .i_rst_n(i_AUD_ADCLRCK),
	.i_clk(i_clk),
	.i_stall(stall),
    .i_signal(signalDE),
    .o_signal(signalFI_in)
);

PipelineRegister_DE_FI　DE_FI_reg(
    .i_rst_n(i_AUD_ADCLRCK),
	.i_clk(i_clk),
	.i_stall(stall),
    .i_signal(signalFI_out),
    .o_signal(signalPL_in)
);


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
			// need to discuss how to trigger other state...
			if (i_key_1) begin
				state_w = S_CONNECT;
			end
			else if (i_key_2) begin
				state_w = S_PLAY;
			end
			
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