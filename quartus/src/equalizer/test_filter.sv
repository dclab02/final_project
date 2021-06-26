`timescale 1ns/10ps

module tb;
    
    /////// for test_filter.sv //////
    localparam b0 = 32'b00111111100110001000001001000011; // 1.19147527217865
    localparam b1 = 32'b00111111110010111100011110110110; // 1.5920321941375732
    localparam b2 = 32'b00111110100111101110101000111000; // 0.3103806972503662
    localparam a1 = 32'b00111110101111101011000001110101; // 0.37244001030921936
    localparam a2 = 32'b10111111000010000110101101101011; // -0.5328890681266785
    localparam x0 = 32'b01000110000101101000100000000000; // 9634.0
    localparam x1 = 32'b01000110111101111100010000000000; // 31714.0
    localparam x2 = 32'b01000110111100001011000000000000; // 30808.0
    ///////////////////////////////


	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start;
    wire sdat;

	initial clk = 1;
	always #HCLK clk = ~clk;

    logic [31:0] y0, y1, y2;

    filter filt(
        .i_rst(rst),
        .i_clk(clk),
        .i_start(start),

        .i_b0(b0),
        .i_b1(b1),
        .i_b2(b2),
        .i_a1(a1),
        .i_a2(a2),

        .i_x0(x0),
        .i_x1(x1),
        .i_x2(x2),

        .o_y0(y0),
        .o_y1(y1),
        .o_y2(y2)
    );

	initial begin
        $fsdbDumpfile("filter.fsdb");
		$fsdbDumpvars;
        $display("reset filter ...");
        rst = 0;
		#(CLK)
        $display("start filter ...");
		rst = 1;
		#(CLK)
        $display("start filter ...");
        rst = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
		#(CLK)
        start = 1;
		#(CLK)
        start = 0;
		#(CLK)
        start = 1;
		#(CLK)
        start = 0;
		#(CLK)
        start = 1;
		#(CLK)
        start = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
        #(CLK)
        start = 1;
		#(CLK)
        start = 0;
        $finish;
	end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule