module Demodulator #(parameter WIDTH=8)(
    input clk,
    input i_rst_n,
    input logic start,
    input [WIDTH-1:0] I_value,
    input [WIDTH-1:0] Q_value,
    output [15:0] magnitude_out,
    output o_valid
    );
    logic [2 * WIDTH:0] I_sqr_value_r, I_sqr_value_w;
    logic [2 * WIDTH:0] Q_sqr_value_r, Q_sqr_value_w;
    logic [2 * WIDTH + 1:0] sum_value_r, sum_value_w;
    logic busy_r, busy_w;
    logic sqrt_valid;
    logic [WIDTH:0] magnitude;
    assign magnitude_out = {7'b0, magnitude};

    logic valid_r, valid_w;
    assign o_valid = valid_r;


    sqrt_int sqrt(
        .clk    (clk),
        .i_rst_n (i_rst_n),
        .start  (start),            // start signal
        .valid  (sqrt_valid),            // root and rem are valid
        .rad    (sum_value_w),             // radicand
        .root_out   (magnitude)           // root
        // .rem    (remaind)           // remainder
    );
    always_comb begin
        I_sqr_value_w = I_sqr_value_r;
        Q_sqr_value_w = Q_sqr_value_r;
        sum_value_w = sum_value_r;
        if (!busy_r)
            I_sqr_value_w = I_value * I_value;
            Q_sqr_value_w = Q_value * Q_value;
            sum_value_w = I_sqr_value_w + Q_sqr_value_w; 
    end

    always_comb begin
        valid_w = valid_r;
        busy_w = busy_r;
        if (start || !sqrt_valid) begin
            valid_w = 0;
            busy_w = 1;
        end
        else begin
            valid_w = 1;
            busy_w = 0;
        end
    end 

    always_ff @(posedge clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            busy_r <= 1'b0;
            valid_r <= 1'b1;
            I_sqr_value_r <= 0;
            Q_sqr_value_r <= 0;
            sum_value_r <= 0;
        end

        else begin
            valid_r <= valid_w;
            busy_r  <= busy_w;
            I_sqr_value_r <= I_sqr_value_w;
            Q_sqr_value_r <= Q_sqr_value_w;
            sum_value_r <= sum_value_w;
        end
    end

endmodule

module sqrt_int #(parameter WIDTH=18)(
    input   logic clk,
    input   logic i_rst_n,
    input   logic start,             // start signal
    output  logic valid,             // root and rem are valid
    input   logic [WIDTH-1:0] rad,   // radicand
    output  logic [8:0] root_out  // root
    // output  logic [WIDTH-1:0] rem    // remainder
    );
    
    logic [WIDTH-1:0] x, x_next;    // radicand copy
    logic [WIDTH-1:0] q, q_next;    // intermediate root (quotient)
    logic [WIDTH+1:0] ac, ac_next;  // accumulator (2 bits wider)
    logic [WIDTH+1:0] test_res;     // sign test result (2 bits wider)
    logic busy;
    logic [WIDTH-1:0] root;
    localparam ITER = 4'd9;//WIDTH >> 1;   // iterations are half radicand width
    // logic [$clog2(ITER)-1:0] i;     // iteration counter
    logic [3:0] i;     // iteration counter
    assign root_out = root[8:0];
    always_comb begin
        test_res = ac - {q, 2'b01};
        if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
            {ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
            q_next = {q[WIDTH-2:0], 1'b1};
        end else begin
            {ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
            q_next = q << 1;
        end
    end

    always_ff @(posedge clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            busy <= 0;
            valid <= 1'b1;
            i <= 0;
            q <= 0;
            {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
            x <= 0;
            ac <= 0;
            q <= 0;
            root <= 0;
        end
        else begin
            if (start) begin
                busy <= 1;
                valid <= 0;
                i <= 0;
                q <= 0;
                {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
            end else if (busy) begin
                if (i == ITER-1) begin  // we're done
                    busy <= 0;
                    valid <= 1;
                    root <= q_next;
                    // rem <= ac_next[WIDTH+1:2];  // undo final shift
                end else begin  // next iteration
                    i <= i + 1'b1;
                    x <= x_next;
                    ac <= ac_next;
                    q <= q_next;
                end
            end
        end
    end
endmodule