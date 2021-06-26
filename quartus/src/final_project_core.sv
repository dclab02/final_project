module final_project_core (
    input i_rst_n,
	input i_clk,
    input i_clk12M,
    input i_clk100k,

    input i_key_0,
	input i_key_1,
	input i_key_2,

    input udp_rx_valid,
    output udp_rx_ready,
    input udp_rx_last,
    input udp_rx_data,
    input udp_tx_data,

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

    // AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

    output [8:0] led_g,
    output [17:0] led_r,

    output [6:0] hex0,
    output [6:0] hex1
);


logic [2:0] state_r, state_w;

logic [19:0] addr_record;
logic [19:0] addr_read;

logic [7:0] led_g_r, led_g_w;
logic [17:0] led_r_r, led_r_w;

logic [15:0] data_record;
logic [15:0] audio_data;
logic playing;

logic filter_set_reg;

localparam S_IDLE = 3'd0;
localparam S_INIT = 3'd1;
localparam S_RX_START = 3'd2;
localparam S_RECV = 3'd3;
localparam S_READ = 3'd4;
localparam S_SET  = 3'd5;
localparam S_TMP  = 3'd6;
localparam S_PLAY = 3'd7;

logic i2c_init, i2c_init_stat;

assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_ADDR = (state_r == S_RECV) ? addr_record : addr_read[19:0];
assign io_SRAM_DQ  = (state_r == S_RECV) ? sram_write_data : 16'dz; // sram_dq as output
assign sram_read_data = (state_r != S_RECV) ? io_SRAM_DQ : 16'd0; // sram_dq as input
assign o_SRAM_WE_N = (state_r == S_RECV) ? 1'b0 : 1'b1;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign led_g = led_g_r;
assign led_r = led_r_r;
// SRAM
logic [19:0] sram_addr_write_w, sram_addr_write_r, sram_addr_last;
logic [19:0] sram_addr_read_w, sram_addr_read_r;
logic sram_reverse = 0;
logic [15:0] sram_write_data, sram_read_data; // data buffer

logic iq_alter = 0;
// relate to Demodulate module
logic start_demodulate;
logic [7:0] IValue;
logic [7:0] QValue;
logic [8:0] demodulateValue;
//////////////////////////////

// relate to Hardware DataPath
logic datapath_rst_n;
logic [7:0] IValue_RE, QValue_RE, IValue_DE, QValue_DE;
logic [15:0] signalDE, signalFI_in, signalFI_out, signalAS_in, signalPL_in;
logic stall, stall_pre;
logic ReceiverValid, DemodulatorValid, FilterValid, PlayerValid;
logic FIFOEmpty, FIFOFull;
logic FIFOWrite, FIFORead;
logic start, receiverReady;

assign FIFOWrite = stall_falling_edge? 1'b1 : 1'b0;
assign FIFORead = 1'b1;

// datapath stall
assign stall = ~ReceiverValid | ~DemodulatorValid | ~FilterValid | ~PlayerValid | ~datapath_rst_n;
assign start = ~stall & receiverReady;
assign stall_falling_edge = stall_pre & ~stall;

///////////////////////////////


I2CInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_init),
	.o_finished(i2c_init_stat),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_state(i2c_state)
);

// === Demodulator ===
// input 8bit unsigned IValue and QValue, output 9 bit unsigned Value
// need output valid bit
// need output signal (16 bits)
assign usigned_QValue = QValue_DE[7] ? ~QValue_DE + 8'd1 : QValue_DE;
assign usigned_IValue = IValue_DE[7] ? ~IValue_DE + 8'd1 : IValue_DE;
Demodulator demodulator(
	.clk(i_clk),
	.start(start),
	.I_value(usigned_IValue),
	.Q_value(usigned_QValue),
	.magnitude_out(signalDE),
	.valid(DemodulatorValid)
);

AsyncFIFO audio_async_fifo(
    .wdata(signalAS_in),
    .winc(FIFOwrite),
    .wclk(i_clk),
    .wrst_n(datapath_rst_n),
    .rinc(FIFOread),
    .rclk(i_AUD_ADCLRCK),
    .rrst_n(datapath_rst_n),
    .rdata(signalPL_in),
    .wfull(FIFOFull),
    .rempty(FIFOEmpty)
);

AudioPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_clk12M),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(playing),
	.i_dac_data(signalPL_in), // dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === Pipeline Registers ===
// receiver to demodulator
PipelineRegister_RE_DE RE_DE_reg(
    .i_rst_n(datapath_rst_n),
	.i_clk(i_clk),
	.i_stall(stall),
	.i_D_value(IValue_RE),
    .i_Q_value(QValue_RE), 
    .o_D_value(IValue_DE),
    .o_Q_value(QValue_DE)
);

// demodulator to filter
PipelineRegister_DE_FI DE_FI_reg(
    .i_rst_n(datapath_rst_n),
	.i_clk(i_clk),
	.i_stall(stall),
    .i_signal(signalDE),
    .o_signal(signalFI_in)
);

// filter to AsyncFIFO
PipelineRegister_FI_AS FI_PL_reg(
    .i_rst_n(datapath_rst_n),
	.i_clk(i_clk),
	.i_stall(stall),
    .i_signal(signalFI_out),
    .o_signal(signalAS_in)
);

always_comb begin
    state_w = state_r;
    led_g_w = led_g_r;
    led_r_w = led_r_r;
    i2c_init = 1'b0;
    i2c_init_stat = 1'b0;
    iq_alter = 1'b0;
    sram_addr_write_w = sram_addr_write_r;
    sram_addr_read_w = sram_addr_read_r;
    sram_addr_last = 20'b0;
    sram_reverse = 1'b0;
    sram_write_data = 16'b0;
    sram_read_data = 16'b0;
    datapath_rst_n = 1'b0;
    IValue_RE = 8'b0;
    QValue_RE = 8'b0;
    udp_rx_ready = 1'b0;

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
            led_g_w[0] = 1'b1;
            // 一旦收到UDP就放
            if (udp_rx_valid) begin
                state_w = S_RX_START;
            end
            else if ((sram_reverse && sram_addr_read_r < sram_addr_write_w) || (!sram_reverse && sram_addr_read_r > sram_addr_write_w)) begin
                state_w = S_READ;
            end
            else begin
                state_w = S_IDLE;
            end
        end
        S_RX_START: begin
            // 判斷傳進來的封包指令
            // sram 位置歸零
            led_g_w[1] = 1'b1;
            udp_rx_ready = 1'b1;
            led_r_w = udp_rx_data;
            if (udp_rx_data == 8'b11111111) begin
                led_g_w[2] = 1'b1;
                state_w = S_SET;
            end
            else if (udp_rx_data == 8'b10101010) begin
                led_g_w[3] = 1'b1;
                state_w = S_RECV;
                sram_addr_write_w = 20'b0;
            end
            else begin
                led_g_w[4] = 1'b1;
                state_w = S_RX_START;
            end
        end

        S_RECV: begin
            // 先收進SRAM 每
            if (udp_rx_last) begin
                state_w = S_IDLE;
            end
            else begin
                // save I/Q data alternately
                if (iq_alter) begin
                    sram_write_data[15:8] = udp_rx_data;
                end
                else begin
                    sram_write_data[7:0] = udp_rx_data;
                    
                    // if SRAM is full
                    if (sram_addr_write_r == 20'b11111111111111111111) begin // OVF
                        sram_addr_write_w = 20'b0;
                        sram_reverse = 1'b1;
                    end
                    else begin
                        sram_addr_write_w = sram_addr_write_r + 1'b1;
                        sram_addr_last = sram_addr_write_w;
                    end
                end

                iq_alter = ~iq_alter;
            end
        end

        S_READ: begin
            if (sram_addr_read_r == 20'b11111111111111111111) begin
                sram_addr_read_w = 20'b0;
                sram_reverse = 1'b0;
            end
            else begin
                IValue_RE = sram_read_data[15:8];
                QValue_RE = sram_read_data[7:0];
                sram_addr_read_w = sram_addr_read_r + 1'b1;
            end
        end

        S_SET: begin
            led_g_w[5] = 1'b1;
            // decode filter conefficients
            if (udp_rx_last) begin
                state_w = S_IDLE;
            end
            else begin
                state_w = S_SET;
            end
        end

        S_PLAY: begin
            if (udp_rx_last) begin
                state_w = S_IDLE;
                datapath_rst_n = 1'b0;
            end
            else begin
                led_g_w = udp_rx_data;
                datapath_rst_n = 1'b1;
            end
        end

    
        default: begin
            state_w = state_r;
        end
    endcase
end

always_ff @(negedge stall) begin
    FIFOwrite <= 1'b1;
end

always_ff @( posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        led_g_r <= 8'b0;
        stall_pre <= 1'b0;
        sram_addr_write_r <= 20'b0;
        sram_addr_read_r <= 20'b0;
        led_r_r <= 18'b0;
        
    end
    else begin
        state_r <= state_w;
        led_g_r <= led_g_w;
        led_r_r <= led_r_w;

        // FIFOwrite <=1'b0;
        stall_pre <= stall;
        
        sram_addr_write_r <= sram_addr_write_w;
        sram_addr_read_r <= sram_addr_read_w;
    end
    
end


    
endmodule