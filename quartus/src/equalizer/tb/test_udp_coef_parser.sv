`timescale 1ns/10ps

module tb;

	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst_n, clk;
	initial clk = 1;
	always #HCLK clk = ~clk;

    logic i_start;

    logic udp_rx_valid;
    logic udp_rx_last;
    logic [7:0] udp_rx_data;

    logic o_set_coef;
    logic [7:0] o_set_filt;
    logic [31:0] o_b0, o_b1, o_b2, o_a1, o_a2;

    integer i;

udp_coef_parser inst (
    .i_rst_n(rst_n),
    .i_clk(clk),

    .i_start(i_start),

    .udp_rx_valid(udp_rx_valid),
    .udp_rx_last(udp_rx_last),
    .udp_rx_data(udp_rx_data),

    .o_set_coef(o_set_coef),
    .o_set_filt(o_set_filt),
    .o_b0(o_b0),
    .o_b1(o_b1),
    .o_b2(o_b2),
    .o_a1(o_a1),
    .o_a2(o_a2)
);


initial begin
    $fsdbDumpfile("udp_coef_parser.fsdb");
    $fsdbDumpvars;
    $display("reset udp_coef_parser");
    rst_n = 1;
    #CLK;
    rst_n = 0;
    #CLK;
    rst_n = 1;
    #CLK;
    i_start = 1;
    udp_rx_valid = 1;
    udp_rx_last = 0;
    for (i = 1; i < 21; i = i + 1) begin
        udp_rx_data = i;
        #CLK;
    end
    udp_rx_data = i;
    udp_rx_last = 1;
    #CLK
    i_start = 0;
    udp_rx_valid = 0;
    #(CLK * 10);

    // second time, data > 168
    i_start = 1;
    udp_rx_valid = 1;
    udp_rx_last = 0;
    udp_rx_data = 5; // filter index
    for (i = 20; i < 39; i = i + 1) begin // 19 byte
        #CLK;
        udp_rx_data = i;
    end
    #CLK
    udp_rx_data = i; // 20 byte
    #(CLK)         
    i_start = 0;
    #(CLK * 5) // over 20 byte
    udp_rx_last = 1; // the end
    #CLK
    udp_rx_valid = 0;
    udp_rx_last = 0;
    #(CLK * 10);

    // third time, data < 168
    i_start = 1;
    udp_rx_valid = 1;
    udp_rx_data = 3; // filter index
     for (i = 50; i < 60; i = i + 1) begin // 10 byte
        #CLK;
        udp_rx_data = i;
    end
    #CLK
    udp_rx_last = 1;
    #CLK
    udp_rx_valid = 0;
    udp_rx_last = 0;
    #CLK
    i_start = 0; // simulate fpga_core go out of S_SET
    #(CLK * 10)


    $finish;

end



endmodule