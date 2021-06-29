`timescale 1ns/10ps

module tb;
    localparam CLK = 10;
    // localparam CLK = 20000;
    localparam HCLK = CLK/2;


    logic rst, clk, clk_12M, clk_100k, clk_375k;
    logic [19:0] SRAM_ADDR;
    wire [15:0] SRAM_DQ;
    logic SRAM_WE_N, SRAM_CE_N, SRAM_OE_N, SRAM_UB_N;

    logic I2C_SCLK;
	wire  I2C_SDAT;
    wire AUD_ADCDAT, AUD_ADCLRCK, AUD_BCLK, AUD_DACLRCK, AUD_DACDAT;
    logic [17:0] SW;

	logic udp_rx_valid, udp_rx_ready, udp_rx_last;
	logic [7:0] udp_rx_data;

	integer  i;

    initial begin
		clk = 1;
		clk_12M = 1;
		clk_100k = 1;
		clk_375k = 1;
	end
	always #HCLK clk = ~clk;
	always #(HCLK*500) clk_100k = ~clk_100k;
	always #(HCLK*25/6) clk_12M = ~clk_12M;
	always #(HCLK*32*25/6) clk_375k = ~clk_375k;

	logic [15:0] data_in;
	assign SRAM_DQ = (SRAM_WE_N == 1) ? data_in : 16'bz;

	assign AUD_BCLK = clk_12M;
	assign AUD_DACLRCK = clk_375k;
	

	// assign SW[17:17] = 1'b1;

	final_project_core top0(
		.i_rst_n(rst),
		.i_clk(clk),

		.i_clk12M(clk_12M),
		.i_clk100k(clk_100k),

		.i_key_0(),
		.i_key_1(),
		.i_key_2(),
		.i_sw(SW),

		// UDP data
		// receive
		.udp_rx_valid(udp_rx_valid),
		.udp_rx_ready(udp_rx_ready),
		.udp_rx_last(udp_rx_last),
		.udp_rx_data(udp_rx_data),

		// transmit
		.udp_tx_data(),
		.udp_tx_ready(),
		.udp_tx_valid(),
		.udp_tx_last(),

		// SRAM
		.o_SRAM_ADDR(SRAM_ADDR), // [19:0]
		.io_SRAM_DQ(SRAM_DQ),    // [15:0]
		.o_SRAM_WE_N(SRAM_WE_N),
		.o_SRAM_CE_N(SRAM_CE_N),
		.o_SRAM_OE_N(SRAM_OE_N),
		.o_SRAM_LB_N(SRAM_LB_N),
		.o_SRAM_UB_N(SRAM_UB_N),

		// I2C
		.o_I2C_SCLK(I2C_SCLK),
		.io_I2C_SDAT(I2C_SDAT),

		// AudPlayer
		.i_AUD_ADCDAT(AUD_ADCDAT),
		.i_AUD_ADCLRCK(AUD_ADCLRCK),
		.i_AUD_BCLK(AUD_BCLK),
		.i_AUD_DACLRCK(AUD_DACLRCK),
		.o_AUD_DACDAT(AUD_DACDAT),

		/*
		* GPIO
		*/
		.led_g(),
		.led_r()
	);

    initial begin
		$display("Reset...");

        #(CLK);
        rst = 1;
		#(CLK);
        rst = 0;
		#(CLK);
        rst = 1;
		#(CLK*180000);

		$display("Finish I2C ...");

		$fsdbDumpfile("final_project_core.fsdb");
        $fsdbDumpvars;

		$display("Start dump");


		// write udp packet
		udp_rx_valid = 1;
		udp_rx_data = 8'b10101010;
		#(CLK * 2);
		for (i = 0 ; i < 200000; i = i+1) begin
			#(CLK)
			if (udp_rx_ready) begin
				udp_rx_data = 8'b01010101;
			end
		end
		#(CLK);
		udp_rx_last = 1; // last byte
		if (udp_rx_ready) begin
			udp_rx_data = 8'b01010101;
		end
		#(CLK)
		udp_rx_valid = 0;
		udp_rx_last = 0;
		#(CLK) // state = 1
		data_in = 16'h12_13; // 18, 19, state = 5
		#(CLK * 3) // state 7, state 1
		data_in = 16'h14_15; // state 5
		// #(CLK * 11)
		// data_in = 16'h19_20;
		// #(CLK * 11)
		// data_in = 16'h21_22;
		// #(CLK * 11)
		// data_in = 16'h23_24;
		// #(CLK * 11)
		// data_in = 16'h25_26;
		for (i = 0; i < 65536; i = i + 1) begin
			#(CLK * 11)
			data_in = i;
		end
		for (i = 0; i < 65536; i = i + 1) begin
			#(CLK * 11)
			data_in = i;
		end
		#(CLK * 80)

		$display("Done.");
	    $finish;
    end

endmodule