// IEEE 754 single precision floating point add
// ref: https://github.com/danshanley/FPU/blob/master/fpu.v
// 31: sign bit
// 30:23: exponent
// 22:0: mantissa

module fadd(
    input i_clk,

    input [31:0] i_a,
    input [31:0] i_b,

    output [31:0] o_c
);

// input a
logic a_sign;
logic a_exponent[7:0];
logic a_mantissa[23:0];
assign a_sign     = i_a[31];
assign a_exponent = i_a[30:23];
assign a_mantissa = {1'b1, i_a[22:0]};

// input b
logic b_sign;
logic b_exponent[7:0];
logic b_mantissa[23:0];
assign b_sign     = i_b[31];
assign b_exponent = i_b[30:23];
assign b_mantissa = {1'b1, i_b[22:0]};

// output c
logic c_sign;
logic c_exponent[7:0];
logic c_mantissa[24:0]; // one more bit for overflow
assign o_c[31]    = c_sign;
assign o_c[30:23] = c_exponent;
assign o_c[22:0]  = c_mantissa[22:0];

always_comb begin
    if ((a_exponent == 8'd255 && a_mantissa != 0) || (b_exponent == 0) && (b_mantissa == 0)) begin
        c_sign = a_sign;
        c_exponent = a_exponent;
        c_mantissa = a_mantissa;
    //If b is NaN or a is zero return b
    end else if ((b_exponent == 8'd255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) begin
        c_sign = b_sign;
        c_exponent = b_exponent;
        c_mantissa = b_mantissa;
    //if a or b is inf return inf
    end else if ((a_exponent == 8'd255) || (b_exponent == 8'd255)) begin
        c_sign = a_sign ^ b_sign;
        c_exponent = 8'd255;
        c_mantissa = 0;
    end else begin // Passed all corner cases
        
    end
end

always_ff @(posedge i_clk) begin
    if (i_clk) begin
        // TODO: let output reg assign to c_o
    end
end

endmodule