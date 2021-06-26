// equalizer, will chain five filter
module equalizer (
    input i_clk,
    input i_rst,

    input i_start,            // start  
    input [31:0] i_data,      // x[0], floating point

    input i_set_coef,         // 1 for set coefficient
    input [2:0] i_set_filt,   // 1 for set which filter, 1 ~ 5
    input [31:0] i_b0,
    input [31:0] i_b1,
    input [31:0] i_b2,
    input [31:0] i_a1,
    input [31:0] i_a2,

    output[31:0] o_data,
    output o_valid
);

// 1 filter
logic [31:0] b0_1_r, b0_1_w;
logic [31:0] b1_1_r, b1_1_w;
logic [31:0] b2_1_r, b2_1_w;
logic [31:0] a1_1_r, a1_1_w;
logic [31:0] a2_1_r, a2_1_w;

// 2 filter
logic [31:0] b0_2_r, b0_2_w;
logic [31:0] b1_2_r, b1_2_w;
logic [31:0] b2_2_r, b2_2_w;
logic [31:0] a1_2_r, a1_2_w;
logic [31:0] a2_2_r, a2_2_w;

// 3 filter
logic [31:0] b0_3_r, b0_3_w;
logic [31:0] b1_3_r, b1_3_w;
logic [31:0] b2_3_r, b2_3_w;
logic [31:0] a1_3_r, a1_3_w;
logic [31:0] a2_3_r, a2_3_w;

// 4 filter
logic [31:0] b0_4_r, b0_4_w;
logic [31:0] b1_4_r, b1_4_w;
logic [31:0] b2_4_r, b2_4_w;
logic [31:0] a1_4_r, a1_4_w;
logic [31:0] a2_4_r, a2_4_w;

// 5 filter
logic [31:0] b0_5_r, b0_5_w;
logic [31:0] b1_5_r, b1_5_w;
logic [31:0] b2_5_r, b2_5_w;
logic [31:0] a1_5_r, a1_5_w;
logic [31:0] a2_5_r, a2_5_w;

// state
logic [2:0] state_r, state_w;

// x
logic [31:0] x0_01_w, x0_01_r, x1_01_w, x1_01_r, x2_01_w, x2_01_r;
logic [31:0] x0_12, x1_12, x2_12;
logic [31:0] x0_23, x1_23, x2_23;
logic [31:0] x0_34, x1_34, x2_34;
logic [31:0] x0_45, x1_45, x2_45;

// start line
logic [4:0] filt_start;

// output
logic valid;
assign o_valid = valid;


filter filt1 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_start(filt_start[0]),

    .i_b0(b0_1_r),
    .i_b1(b1_1_r),
    .i_b2(b2_1_r),
    .i_a1(a1_1_r),
    .i_a2(a2_1_r),

    .i_x0(x0_01_r),
    .i_x1(x1_01_r),
    .i_x2(x2_01_r),

    .o_y0(x0_12),
    .o_y1(x1_12),
    .o_y2(x2_12)
);

filter filt2 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_start(filt_start[1]),

    .i_b0(b0_2_r),
    .i_b1(b1_2_r),
    .i_b2(b2_2_r),
    .i_a1(a1_2_r),
    .i_a2(a2_2_r),

    .i_x0(x0_12),
    .i_x1(x1_12),
    .i_x2(x2_12),

    .o_y0(x0_23),
    .o_y1(x1_23),
    .o_y2(x2_23)
);

filter filt3 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_start(filt_start[2]),

    .i_b0(b0_3_r),
    .i_b1(b1_3_r),
    .i_b2(b2_3_r),
    .i_a1(a1_3_r),
    .i_a2(a2_3_r),

    .i_x0(x0_23),
    .i_x1(x1_23),
    .i_x2(x2_23),

    .o_y0(x0_34),
    .o_y1(x1_34),
    .o_y2(x2_34)
);

filter filt4 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_start(filt_start[3]),

    .i_b0(b0_4_r),
    .i_b1(b1_4_r),
    .i_b2(b2_4_r),
    .i_a1(a1_4_r),
    .i_a2(a2_4_r),

    .i_x0(x0_34),
    .i_x1(x1_34),
    .i_x2(x2_34),

    .o_y0(x0_45),
    .o_y1(x1_45),
    .o_y2(x2_45)
);


filter filt5 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_start(filt_start[4]),

    .i_b0(b0_5_r),
    .i_b1(b1_5_r),
    .i_b2(b2_5_r),
    .i_a1(a1_5_r),
    .i_a2(a2_5_r),

    .i_x0(x0_45),
    .i_x1(x1_45),
    .i_x2(x2_45),

    .o_y0(o_data),
    .o_y1(),
    .o_y2()
);

// equalizer filter run
always_comb begin
    state_w = state_r;
    filt_start  = 5'b00000;
    valid = 1'b0;
    case (state_r)
        // IDLE
        3'd0: begin
            filt_start = 5'b00000;
            state_w = 3'd0;
            valid = 1'b1;
            if (i_start) begin
                valid = 1'b0;
                state_w = 3'd1;
            end
        end
        // filter 1
        3'd1: begin
            filt_start = 5'b00001;
            state_w = 3'd2;
        end
        3'd2: begin
            filt_start = 5'b00010;
            state_w = 3'd3;
        end
        3'd3: begin
            filt_start = 5'b00100;
            state_w = 3'd4;
        end
        3'd4: begin
            filt_start = 5'b01000;
            state_w = 3'd5;
        end
        3'd5: begin
            filt_start = 5'b10000;
            state_w = 3'd0;
        end
        default: begin
            state_w = state_r;
            filt_start = 5'b00000;
        end
    endcase
end

// set filter coefficient
// i_set_coef: set to 1 for telling equalizer to read coefficient
// i_set_filt: set to 1 ~ 5 for which filter to be set
always_comb begin
    // 1 filter
    b0_1_w = b0_1_r;
    b1_1_w = b1_1_r;
    b2_1_w = b2_1_r;
    a1_1_w = a1_1_r;
    a2_1_w = a2_1_r;
    // 2 filter coef
    b0_2_w = b0_2_r;
    b1_2_w = b1_2_r;
    b2_2_w = b2_2_r;
    a1_2_w = a1_2_r;
    a2_2_w = a2_2_r;
    // 3 filter coef
    b0_3_w = b0_3_r;
    b1_3_w = b1_3_r;
    b2_3_w = b2_3_r;
    a1_3_w = a1_3_r;
    a2_3_w = a2_3_r;
    // 4 filter coef
    b0_4_w = b0_4_r;
    b1_4_w = b1_4_r;
    b2_4_w = b2_4_r;
    a1_4_w = a1_4_r;
    a2_4_w = a2_4_r;
    // 5 filter coef
    b0_5_w = b0_5_r;
    b1_5_w = b1_5_r;
    b2_5_w = b2_5_r;
    a1_5_w = a1_5_r;
    a2_5_w = a2_5_r;

    if (i_set_coef) begin
        case (i_set_filt)
            3'd1: begin
                b0_1_w = i_b0;
                b1_1_w = i_b1;
                b2_1_w = i_b2;
                a1_1_w = i_a1;
                a2_1_w = i_a2;
            end
            3'd2: begin
                b0_2_w = i_b0;
                b1_2_w = i_b1;
                b2_2_w = i_b2;
                a1_2_w = i_a1;
                a2_2_w = i_a2;
            end
            3'd3: begin
                b0_3_w = i_b0;
                b1_3_w = i_b1;
                b2_3_w = i_b2;
                a1_3_w = i_a1;
                a2_3_w = i_a2;
            end
            3'd4: begin
                b0_4_w = i_b0;
                b1_4_w = i_b1;
                b2_4_w = i_b2;
                a1_4_w = i_a1;
                a2_4_w = i_a2;
            end
            3'd5: begin
                b0_5_w = i_b0;
                b1_5_w = i_b1;
                b2_5_w = i_b2;
                a1_5_w = i_a1;
                a2_5_w = i_a2;
            end
            default: begin
                
            end
        endcase
    end
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r <= 0;
        // 1filter coef
        b0_1_r <= 32'd1;
        b1_1_r <= 0;
        b2_1_r <= 0;
        a1_1_r <= 0;
        a2_1_r <= 0;
        // 2filter coef
        b0_2_r <= 32'd1;
        b1_2_r <= 0;
        b2_2_r <= 0;
        a1_2_r <= 0;
        a2_2_r <= 0;
        // 3filter coef
        b0_3_r <= 32'd1;
        b1_3_r <= 0;
        b2_3_r <= 0;
        a1_3_r <= 0;
        a2_3_r <= 0;
        // 4 filter coef
        b0_4_r <= 32'd1;
        b1_4_r <= 0;
        b2_4_r <= 0;
        a1_4_r <= 0;
        a2_4_r <= 0;
        // 5 filter coef
        b0_5_r <= 32'd1;
        b1_5_r <= 0;
        b2_5_r <= 0;
        a1_5_r <= 0;
        a2_5_r <= 0;
    end

    else begin
        // 1 filter coef
        b0_1_r <= b0_1_w;
        b1_1_r <= b1_1_w;
        b2_1_r <= b2_1_w;
        a1_1_r <= a1_1_w;
        a2_1_r <= a2_1_w;
        // 2 filter coef
        b0_2_r <= b0_2_w;
        b1_2_r <= b1_2_w;
        b2_2_r <= b2_2_w;
        a1_2_r <= a1_2_w;
        a2_2_r <= a2_2_w;
        // 3 filter coef
        b0_3_r <= b0_3_w;
        b1_3_r <= b1_3_w;
        b2_3_r <= b2_3_w;
        a1_3_r <= a1_3_w;
        a2_3_r <= a2_3_w;
        // 4 filter coef
        b0_4_r <= b0_4_w;
        b1_4_r <= b1_4_w;
        b2_4_r <= b2_4_w;
        a1_4_r <= a1_4_w;
        a2_4_r <= a2_4_w;
        // 5 filter coef
        b0_5_r <= b0_5_w;
        b1_5_r <= b1_5_w;
        b2_5_r <= b2_5_w;
        a1_5_r <= a1_5_w;
        a2_5_r <= a2_5_w;
        // state
        state_r <= state_w;

    end
end

endmodule