`timescale 1ns/10ps

module tb;

	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start;
	initial clk = 1;
	always #HCLK clk = ~clk;

    logic i_start, i_set_coef;
    logic [2:0] i_set_filt;
    logic [31:0] i_data, i_b0, i_b1, i_b2, i_a1, i_a2;

    logic [31:0] o_data;
    logic o_valid;

    equalizer eq(
        .i_rst(rst),
        .i_clk(clk),

        .i_start(i_start),
        .i_data(i_data),

        .i_set_coef(i_set_coef),
        .i_set_filt(i_set_filt),
        .i_b0(i_b0),
        .i_b1(i_b1),
        .i_b2(i_b2),
        .i_a1(i_a1),
        .i_a2(i_a2),

        .o_data(o_data),
        .o_valid(o_valid)
    );

    initial begin
        $fsdbDumpfile("equalizer.fsdb");
        $fsdbDumpvars;
        $display("reset equalizer ...");
        rst = 0;
        #(CLK)
        rst = 1;
        #(CLK)
        $display("start equalizer ...");
        rst = 0;
        // setup filter parameter
        /////// set filter1 //////
        #(CLK);
        i_set_coef = 1;
        i_set_filt = 3'd1;
        i_b0 = 32'b00111111010111111010101110010010;
        i_b1 = 32'b00111111100011101111101001011001;
        i_b2 = 32'b00111111001010111000010011001110;
        i_a1 = 32'b00111111011011111110111110110000;
        i_a2 = 32'b00111111001110010011010101100001;
        #(CLK);
        i_set_coef = 0;
        /////// set filter2 //////
        #(CLK);
        i_set_coef = 1;
        i_set_filt = 3'd2;
        i_b0 = 32'b00111111100001101000000011110011;
        i_b1 = 32'b10111111111111001010000000110000;
        i_b2 = 32'b00111111011011001100110110010001;
        i_a1 = 32'b10111111111111001010000000110000;
        i_a2 = 32'b00111111011110011100111101111000;
        #(CLK);
        i_set_coef = 0;
        /////// set filter3 //////
        #(CLK);
        i_set_coef = 1;
        i_set_filt = 3'd3;
        i_b0 = 32'b00111110111011100011001101110111;
        i_b1 = 32'b10111111011001111100111100110011;
        i_b2 = 32'b00111110111010010010000110001000;
        i_a1 = 32'b10111111111111000011010011000100;
        i_a2 = 32'b00111111011111000100010011010101;
        #(CLK);
        i_set_coef = 0;
        /////// set filter4 //////
        #(CLK);
        i_set_coef = 1;
        i_set_filt = 3'd4;
        i_b0 = 32'b00111111110101000001000101110010;
        i_b1 = 32'b10111110011110110100100010001000;
        i_b2 = 32'b00111111101111110101011110100110;
        i_a1 = 32'b00111111011111011010000010111110;
        i_a2 = 32'b00111111011010100101111101010000;
        #(CLK);
        i_set_coef = 0;
        /////// set filter5 //////
        #(CLK);
        i_set_coef = 1;
        i_set_filt = 3'd5;
        i_b0 = 32'b00111110101110011011110001100100;
        i_b1 = 32'b10111110110010101010111001101110;
        i_b2 = 32'b00111110101010100000000010001010;
        i_a1 = 32'b10111111110100101001100110010101;
        i_a2 = 32'b00111111011100011011101001101010;
        #(CLK);
        i_set_coef = 0;
        ///////////////////////
        /////////// set data ////////////
        i_start = 1;
        i_data = 32'b01000110011100111000100000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b11000110100000010100111000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b01000110101000001010001000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b11000110111111110101101000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b11000110101111101100111000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b11000110011001111011100000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b11000110101001111000011000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b11000110111001100001000000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b01000101111111000101000000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        i_start = 1;
        i_data = 32'b11000110100001110101000000000000;
        #(CLK);
        i_start = 0;
        #(CLK*6);
        ///////////////////////
        $finish;
    end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule