`timescale 1ns/100ps
module tb;
	localparam WCLK = 10;
    localparam RCLK = 42;
	localparam WHCLK = WCLK/2;
    localparam RHCLK = WCLK/2;
	logic wclk, rclk;
    // data
    logic [15:0] datain, datai_nxt, dataout;
    logic FIFOFull, FIFOEmpty;

    // control signal
    logic FIFOwrite, FIFOread, rst_n;
    
    initial wclk = 0;
    initial rclk = 0;
	always #WHCLK wclk = ~wclk;
    always #RHCLK rclk = ~rclk;
    

    AsyncFIFO audio_async_fifo(
    .wdata(datain),
    .winc(FIFOwrite),
    .wclk(wclk),
    .wrst_n(rst_n),
    .rinc(FIFOread),
    .rclk(rclk),
    .rrst_n(rst_n),
    .rdata(dataout)),
    .wfull(FIFOFull),
    .rempty(FIFOEmpty)
    );

    initial begin
        $fsdbDumpfile( "test.fsdb" );
        $fsdbDumpvars(0, tb, "+mda");
    end
	initial begin
		#(2*RCLK)
        rst_n = 1'b0;
        #(2*RCLK)
        rst_n = 1'b0;
		for (int i = 1; i < 256; i = i * 2) begin
            $display("=========");
            $display("q %2d", i);
            
			@(posedge clk)
			@(posedge valid)
			$display("res  %3d", result);
			$display("=========");
		end
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too long, abort.");
		$finish;
	end
always_comb begin
    datain_nxt = datain + 1;
end
always_ff @( posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        datain <= 5'b0;
    end
    else if (FIFOFull) begin
        $display("FIFO is Full!!!!! Abort...");
        $finish;
    end
    else begin
        $display("write value: %3d", datain);
        datain <= datain_nxt;
        FIFOWrite <= 1'b1;
        datain <= i;
    end
end

always_ff @( posedge rclk ) begin
    if (FIFOEmpty) begin
        $display("FIFO IS EMPTY!!!!!");
    end
    else begin
        $display("read value: %3d", dataout);   
    end
end

endmodule
