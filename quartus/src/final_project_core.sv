module final_project_core (
    input i_rst_n,
	input i_clk,
    input i_clk12M,
    input i_clk100k,

    input i_key_0,
	input i_key_1,
	input i_key_2,
    input [17:0] i_sw,

    output      udp_rx_ready,
    input       udp_rx_valid,
    input       udp_rx_last,
    input [7:0] udp_rx_data,

    input      udp_tx_hdr_ready,
    output     udp_tx_hdr_valid,
    input      udp_tx_ready,
    output       udp_tx_valid,
    output       udp_tx_last,
    output [7:0] udp_tx_data,

    // SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,

    // I2C
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,

    // AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

    output [8:0] led_g,
    output [17:0] led_r

    // output [6:0] hex0,
    // output [6:0] hex1
);

logic [2:0] state_r, state_w;

logic [19:0] addr_record;
logic [19:0] addr_read;

logic [7:0] led_g_r, led_g_w;
logic [17:0] led_r_r, led_r_w;

logic [15:0] audio_data;

logic filter_set_reg;

localparam S_INIT = 3'd0;
localparam S_IDLE = 3'd1;
localparam S_RX_START = 3'd2;
localparam S_SET  = 3'd3;
localparam S_RECV = 3'd4;
localparam S_READ = 3'd5;
localparam S_PLAY = 3'd6;
localparam S_WAIT = 3'd7;

logic i2c_init, i2c_init_stat;
logic [1:0] i2c_o_state;

// SRAM
logic [19:0] sram_addr_write_w, sram_addr_write_r, sram_addr_last;
logic [19:0] sram_addr_read_w, sram_addr_read_r;
logic [15:0] sram_write_data, sram_read_data; // data buffer
logic sram_reverse_r, sram_reverse_w;
logic iq_alter_r, iq_alter_w;

// relate to Hardware DataPath
logic [7:0] IValue_RE_r, QValue_RE_r, IValue_RE_w, QValue_RE_w;
logic [7:0] IValue_DE, QValue_DE;
logic [15:0] signalDE, signalFI_in, signalFI_out, signalAS_in, signalPL_in, fifo_in;
logic [7:0] usigned_QValue, usigned_IValue;
logic stall, stall_pre;
logic ReceiverValid_r, ReceiverValid_w;
logic DemodulatorValid, EqValid, PlayerValid;
logic FIFOEmpty, FIFOFull;
logic FIFOWrite, FIFORead;
logic start;
logic stall_falling_edge;

assign FIFOWrite = stall_falling_edge? 1'b1 : 1'b0;
assign FIFORead = 1'b1;

// datapath stall
// assign stall = ~ReceiverValid_r | ~DemodulatorValid | ~EqValid | FIFOFull;
assign stall = ~ReceiverValid_r | ~DemodulatorValid | ~EqValid | FIFOFull;

assign start = ~stall;
assign stall_falling_edge = stall_pre & ~stall;
///////////////////////////////

// udp output
logic ready_r, ready_w;
logic [7:0] data_r, data_w;
assign udp_rx_ready = ready_r;

// SRAM
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_ADDR = (state_r == S_RECV) ? sram_addr_write_r : sram_addr_read_r;
assign io_SRAM_DQ  = (state_r == S_RECV) ? sram_write_data : 16'dz; // sram_dq as output
assign sram_read_data = (state_r != S_RECV) ? io_SRAM_DQ : 16'd0; // sram_dq as input
assign o_SRAM_WE_N = (state_r == S_RECV) ? 1'b0 : 1'b1;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

logic [7:0] upper_data_r, upper_data_w; // upper of udp data

// assign audio_data = (state_r == S_PLAY) ? sram_read_data : signalPL_in;
assign audio_data = signalPL_in;
assign fifo_in = (state_r == S_PLAY) ? sram_read_data : signalAS_in;


// led
assign led_g[7:0] = led_g_r;
assign led_r = led_r_r;

I2CInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk100k),
	.i_start(i2c_init),
	.o_finished(i2c_init_stat),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(io_I2C_SDAT),
	.o_state(i2c_o_state),
    .o_oen()
);

// === Demodulator ===
// input 8bit unsigned IValue and QValue, output 16 bit unsigned Value
// need output valid bit
// need output signal (16 bits)
assign usigned_QValue = QValue_RE_r[7] ? ~QValue_RE_r + 8'd1 : QValue_RE_r;
assign usigned_IValue = IValue_RE_r[7] ? ~IValue_RE_r + 8'd1 : IValue_RE_r;

Demodulator demodulator(
	.clk(i_clk),
	.i_rst_n(i_rst_n),
	.start(start),
	.I_value(usigned_IValue),
	.Q_value(usigned_QValue),
	.magnitude_out(signalDE),
	.o_valid(DemodulatorValid)
);

AsyncFIFO audio_async_fifo(
    .wdata(fifo_in),
    .winc(FIFOWrite),
    .wclk(i_clk),
    .wrst_n(i_rst_n),
    .rinc(FIFORead),
    .rclk(~i_AUD_DACLRCK),
    .rrst_n(i_rst_n),
    .rdata(signalPL_in),
    .wfull(FIFOFull),
    .rempty(FIFOEmpty)
);

// === Player ===
AudioPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(1'b1), 
	.i_dac_data(audio_data), // dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === Equalizer ===
// call start for start reading data 
// pull valid for run finished
logic [31:0] floatdata_in, floatdata_out;
logic [7:0] set_filt;
logic [31:0] b0, b1, b2, a1, a2;
logic set_coef; // 1 for to set coefficent
logic parse_start;
assign parse_start = (state_r == S_SET);

Equalizer eq (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_start(start),
    .i_data(floatdata_in),

    .i_set_coef(set_coef),
    .i_set_filt(set_filt),
    .i_b0(b0),
    .i_b1(b1),
    .i_b2(b2),
    .i_a1(a1),
    .i_a2(a2),
    
    .o_data(floatdata_out),
    .o_valid(EqValid)
);

// when at S_SET state, this will read udp data and parse for set coefficient of eq filter
udp_coef_parser parser (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_start(parse_start),

    .udp_rx_valid(udp_rx_valid),
    .udp_rx_last(udp_rx_last),
    .udp_rx_data(udp_rx_data),

    .o_set_coef(set_coef),
    .o_set_filt(set_filt),
    .o_b0(b0),
    .o_b1(b1),
    .o_b2(b2),
    .o_a1(a1),
    .o_a2(a2)
);

Int16toFloat32 int16tofloat32 (
    .intdata(signalDE),
    .floatdata(floatdata_in)
);

Float32toInt16 float32toint16 (
    .floatdata(floatdata_out),
    .intdata(signalFI_out)
);

// === Pipeline Registers ===
// // receiver to demodulator
// PipelineRegister_RE_DE RE_DE_reg(
//     .i_rst_n(i_rst_n),
// 	.i_clk(i_clk),
// 	.i_stall(stall),
// 	.i_D_value(IValue_RE_r),
//     .i_Q_value(QValue_RE_r), 
//     .o_D_value(IValue_DE),
//     .o_Q_value(QValue_DE)
// );

// // demodulator to filter
// PipelineRegister_DE_FI DE_FI_reg(
//     .i_rst_n(i_rst_n),
// 	.i_clk(i_clk),
// 	.i_stall(stall),
//     .i_signal(signalDE),
//     .o_signal(signalFI_in)
// );

// filter to AsyncFIFO
PipelineRegister_FI_AS FI_PL_reg(
    .i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_stall(stall),
    .i_signal(signalFI_out),
    .o_signal(signalAS_in)
);

// udp send back
udp_loop_back inst (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_stall_falling(stall_falling_edge),
    .i_stall(),
    .i_eqvalid(),

    .i_data(signalDE),
    .udp_tx_hdr_ready(udp_tx_hdr_ready),
    .udp_tx_hdr_valid(udp_tx_hdr_valid),
    .udp_tx_ready(udp_tx_ready),
    .udp_tx_valid(udp_tx_valid),
    .udp_tx_last(udp_tx_last),
    .udp_tx_data(udp_tx_data)
);


assign led_g_r[2:0] = state_r;

assign led_g_r[3] = start;
assign led_g_r[4] = stall;


assign led_g_r[5] = DemodulatorValid;

assign led_g_r[6] = ReceiverValid_r;

// assign led_g_r[6] = i_sw[17];
// assign led_g_r[7] = FIFOFull;
assign led_g_r[7] = i_AUD_DACLRCK;

// assign led_g_r[4:3] = i2c_o_state;
// assign led_g_r[5] = i2c_init;
// assign led_g_r[6] = i2c_init_stat;

// assign led_g_r[5] = udp_rx_valid;
// assign led_g_r[6] = udp_rx_ready;
// assign led_g_r[7] = udp_rx_last;

always_comb begin
    state_w = state_r;
    led_r_w = led_r_r;
    i2c_init = 1'b0;
    iq_alter_w = iq_alter_r;
    sram_addr_write_w = sram_addr_write_r;
    sram_addr_read_w = sram_addr_read_r;
    // sram_addr_last = 20'b0;
    sram_reverse_w = sram_reverse_r;
    sram_write_data = 16'b0;
 
    IValue_RE_w = IValue_RE_r;
    QValue_RE_w = QValue_RE_r;
    ReceiverValid_w = ReceiverValid_r;

    upper_data_w = upper_data_r;
    // FIFOWrite = 1'b0;

    ready_w = ready_r;

    case (state_r)
        S_INIT: begin
            i2c_init = 1'b1;
			if (i2c_init_stat) begin // init done
				i2c_init = 1'b0;
				state_w = S_IDLE;
			end
            else begin
                state_w = S_INIT;
            end
        end
        S_IDLE: begin
            if (udp_rx_valid) begin
                state_w = S_RX_START;
                ready_w = 1'b1;
            end
            else if ((!sram_reverse_r && sram_addr_read_r < sram_addr_write_r) || (sram_reverse_r && sram_addr_read_r > sram_addr_write_r)) begin
                if (i_sw[17]) begin
                    state_w = S_PLAY; 
                end
                else begin
                    state_w = S_READ;
                end
            end
            else begin
                state_w = S_IDLE;
            end
        end
        S_RX_START: begin
            if (udp_rx_last) begin
                state_w = S_IDLE;
                ready_w = 1'b0;
            end
            else begin
                if (udp_rx_ready && udp_rx_valid) begin
                    if (udp_rx_data == 8'b11111111) begin
                        state_w = S_SET;
                    end
                    else if (udp_rx_data == 8'b10101010) begin
                        state_w = S_RECV;
                    end
                    else begin
                        state_w = S_RX_START;
                    end
                end
                else begin
                    state_w = S_RX_START;
                end
            end
        end

        S_SET: begin
            // decode filter conefficients
            if (set_coef) begin // udp_coef_parser read finish
                state_w = S_IDLE;
                ready_w = 1'b0;
            end
            else begin
                state_w = S_SET;
            end
        end

        S_RECV: begin
            // if SRAM is full
            if (udp_rx_valid && udp_rx_ready) begin

                // save I/Q data alternately
                iq_alter_w = ~iq_alter_r;
                if (!iq_alter_r) begin
                    upper_data_w = udp_rx_data;
                    // sram_write_data[15:8] = udp_rx_data;
                    // led_r_w[15:8] = sram_write_data[15:8];
                end
                else begin
                    // sram_write_data[7:0] = udp_rx_data;
                    sram_write_data = { upper_data_r, udp_rx_data };
                    

                    // next current address is the last
                    if (sram_addr_write_r == 20'b11111111111111111111) begin // OVF
                        sram_addr_write_w = 20'b0;
                        sram_reverse_w = 1'b1;
                    end
                    else begin
                    // update current write address 
                        sram_addr_write_w = sram_addr_write_r + 20'b1;
                    end
                end

                // last byte
                if (udp_rx_last) begin
                    iq_alter_w = 0;
                    state_w = S_IDLE;
                    ready_w = 1'b0;     // reset ready for udp
                end
            end
            else begin
                state_w = S_RECV;
            end

        end

        S_READ: begin
            if (sram_addr_read_r == 20'b11111111111111111111) begin
                sram_addr_read_w = 20'b0;
                sram_reverse_w = 1'b0;
            end
            else begin
                IValue_RE_w = sram_read_data[15:8];
                QValue_RE_w = sram_read_data[7:0];
                ReceiverValid_w = 1'b1;
                led_r_w[17:0] = sram_addr_read_r[17:0];
                sram_addr_read_w = sram_addr_read_r + 20'd1;
                state_w = S_WAIT;
            end
        end

        S_WAIT: begin
            if (start) begin
                state_w = S_IDLE;
                ReceiverValid_w = 1'b0;
            end
            else begin
                state_w = S_WAIT;
            end
        end

        S_PLAY: begin
            // FIFOWrite = 1'b1;
            if (sram_addr_read_r == 20'b11111111111111111111) begin
                sram_addr_read_w = 20'b0;
                sram_reverse_w = 1'b0;
            end
            else begin
                ReceiverValid_w = 1;
                led_r_w[17:0] = sram_addr_read_r[17:0];
                sram_addr_read_w = sram_addr_read_r + 20'd1;
            end

            state_w = S_IDLE;
        end
        default: begin
            state_w = state_r;
        end
    endcase
end

// always_ff @(negedge stall) begin
//     FIFOWrite <= 1'b1;
// end

always_ff @( posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_INIT;
        led_r_r <= 18'b0;
        ready_r <= 1'b0;

        iq_alter_r <= 1'b0;

        stall_pre <= 1'b0;
        sram_addr_write_r <= 20'b0;
        sram_addr_read_r <= 20'b0;
        sram_reverse_r <= 1'b0;

        IValue_RE_r <= 0;
        QValue_RE_r <= 0;

        ReceiverValid_r <= 0;

        upper_data_r <= 0;
        
    end
    else begin
        state_r <= state_w;
        led_r_r <= led_r_w;
        ready_r <= ready_w;

        iq_alter_r <= iq_alter_w;

        // FIFOwrite <=1'b0;
        stall_pre <= stall;
        
        sram_addr_write_r <= sram_addr_write_w;
        sram_addr_read_r <= sram_addr_read_w;
        sram_reverse_r <= sram_reverse_w;

        IValue_RE_r <= IValue_RE_w;
        QValue_RE_r <= QValue_RE_w;

        ReceiverValid_r <= ReceiverValid_w;

        upper_data_r <= upper_data_w;

    end
    
end


    
endmodule