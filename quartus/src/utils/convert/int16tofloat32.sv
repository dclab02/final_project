`define CLOG2(x) ((x <= 16'd1) || (x > 16384)) ? 8'd0 : \
(x < 16'd2) ? 8'd0 : \
(x < 16'd4) ? 8'd1 : \
(x < 16'd8) ? 8'd2 : \
(x < 16'd16) ? 8'd3 : \
(x < 16'd32) ? 8'd4 : \
(x < 16'd64) ? 8'd5 : \
(x < 16'd128) ? 8'd6: \
(x < 16'd256) ? 8'd7: \
(x < 16'd512) ? 8'd8 : \
(x < 16'd1024) ? 8'd9 : \
(x < 16'd2048) ? 8'd10 : \
(x < 16'd4096) ? 8'd11 : \
(x < 16'd8192) ? 8'd12 : \
(x < 16'd16384) ? 8'd13 : 0



module Int16toFloat32(
    input  [15:0]      intdata,
    output [31:0]      floatdata
);
    logic sign;
    logic [7:0] clog_data;
    logic [7:0] exponent;
    logic [22:0] fraction;
    logic inv_intdata;
    logic [15:0] unsigned_data;
    logic [15:0] fraction_data;
    assign floatdata = {sign, exponent, fraction};
    assign sign = intdata[15];
    assign unsigned_data = intdata[15] ? ~intdata + 16'd1 : intdata;
    assign clog_data =`CLOG2(unsigned_data);
    assign exponent =  clog_data + 8'd127;
    assign fraction_data = unsigned_data << (16 - clog_data);
    assign fraction = {fraction_data, 7'b0};
endmodule