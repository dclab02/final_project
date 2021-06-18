`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	logic clk, start_cal, busy, valid;
	initial clk = 0;
	always #HCLK clk = ~clk;
    logic [7:0] a, b;
    logic [8:0] result;
    calc_magnitude test(
        .clk(clk),
        .start(start_cal),
        .I_value(a),
        .Q_value(b),
        .magnitude_out(result),
        .valid(valid)
    );
    initial begin
        $fsdbDumpfile( "test.fsdb" );
        $fsdbDumpvars(0, tb, "+mda");
    end
	initial begin
		#(2*CLK)
		for (int i = 1; i < 256; i = i * 2) begin
			$display("=========");
			$display("q %2d", i);
			start_cal <= 1;
            a <= i;
            b <= i;
			@(posedge clk)
			start_cal <= 0;
			@(posedge valid)
			$display("res  %3d", result);
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
