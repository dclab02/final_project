// biquad filter
// y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
module Filter (
    input i_clk,
    input i_rst_n,
    input i_start,

    // filter coefficient, type: floating point
    input [31:0] i_b0,
    input [31:0] i_b1,
    input [31:0] i_b2,
    input [31:0] i_a1,
    input [31:0] i_a2,

    // data input, type: floating point
    input [31:0] i_x0,
    input [31:0] i_x1,
    input [31:0] i_x2,

    // data output, type: floating point
    output [31:0] o_y0,
    output [31:0] o_y1,
    output [31:0] o_y2
);

// intermediate
// y2 = y1, y1 = y0, and cacluate new y0, output this three
logic [31:0] y0_w, y1_w, y2_w;
logic [31:0] y0_r, y1_r, y2_r;

logic [31:0] b0x0, b1x1, b2x2, a1y1, a2y2;  // mult
logic [31:0] b0x0_b1x1, a1y1_a2y2;          // add
logic [31:0] b0x0_b1x1_b2x2;                // add
logic [31:0] b0x0_b1x1_b2x2__a1y1_a2y2;     // sub

// output
assign o_y0 = y0_r;
assign o_y1 = y1_r;
assign o_y2 = y2_r;

fpu mult_b0_x0 (
    .clk(i_clk),
    .A(i_b0),
    .B(i_x0),
    .opcode(2'b11),
    .O(b0x0)
);

fpu mult_b1_x1 (
    .clk(i_clk),
    .A(i_b1),
    .B(i_x1),
    .opcode(2'b11),
    .O(b1x1)
);

fpu mult_b2_x2 (
    .clk(i_clk),
    .A(i_b2),
    .B(i_x2),
    .opcode(2'b11),
    .O(b2x2)
);

fpu mult_a1_y1 (
    .clk(i_clk),
    .A(i_a1),
    .B(y1_w),
    .opcode(2'b11),
    .O(a1y1)
);

fpu mult_a2_y2 (
    .clk(i_clk),
    .A(i_a2),
    .B(y2_w),
    .opcode(2'b11),
    .O(a2y2)
);

fpu add_b0x0_b1x1 (
    .clk(i_clk),
    .A(b0x0),
    .B(b1x1),
    .opcode(2'b00),
    .O(b0x0_b1x1)
);

fpu add_b0x0_b1x1_b2x2 (
    .clk(i_clk),
    .A(b0x0_b1x1),
    .B(b2x2),
    .opcode(2'b00),
    .O(b0x0_b1x1_b2x2)
);

fpu add_a1y1_a2y2 (
    .clk(i_clk),
    .A(a1y1),
    .B(a2y2),
    .opcode(2'b00),
    .O(a1y1_a2y2)
);

fpu sub_b0x0_b1x1_b2x2__a1y1_a2y2 (
    .clk(i_clk),
    .A(b0x0_b1x1_b2x2),
    .B(a1y1_a2y2),
    .opcode(2'b01),
    .O(b0x0_b1x1_b2x2__a1y1_a2y2)
);

always_comb begin
    y0_w = y0_r;
    y1_w = y1_r;
    y2_w = y2_r;
    if (i_start == 1) begin
        y2_w = y1_r;
        y1_w = y0_r;
        y0_w = b0x0_b1x1_b2x2__a1y1_a2y2;
    end  
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        y0_r <= 0;
        y1_r <= 0;
        y2_r <= 0;
    end
    else begin
        y0_r <= y0_w;
        y1_r <= y1_w;
        y2_r <= y2_w;
    end
end

endmodule