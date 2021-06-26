`timescale 1ns/100ps
module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	logic clk;
    logic signed [15:0] intvalue, int_res;
    logic signed [31:0] floatvalue;
	integer i;
	initial clk = 0;

	always #HCLK clk = ~clk;
    
    Int16toFloat32 i2f(
        .intdata(intvalue),
        .floatdata(floatvalue)
    );
    
    Float32toInt16 f2i(
        .floatdata(floatvalue),
        .intdata(int_res)
    );

    initial begin
        $fsdbDumpfile( "test.fsdb" );
        $fsdbDumpvars(0, tb, "+mda");
    end
	initial begin
		#(2*CLK)
		for ( i = 1; i < 256; i = i * 2) begin
			$display("=========");
			$display("int input :%3d", i);
			intvalue <= i;
            @(posedge clk)
			$display("float res :%1b %8b %23b", floatvalue[31], floatvalue[30:23], floatvalue[22:0]);
			$display("int res :%3d", $signed(int_res));
			$display("=========");
			$display("int input :%3d", -1 * i);
            intvalue <= (-1 * i);
            @(posedge clk)
			$display("float res :%1b %8b %23b", floatvalue[31], floatvalue[30:23], floatvalue[22:0]);
			$display("int res :%3d", $signed(int_res));
			$display("=========");
		end
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
