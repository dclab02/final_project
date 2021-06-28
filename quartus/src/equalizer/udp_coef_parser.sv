module udp_coef_parser(
    input i_clk,
    input i_rst_n,

    input i_start, // set to 1 to tell start parsing

    input udp_rx_valid,
    input udp_rx_last,
    input [7:0] udp_rx_data,

    output o_set_coef, // set to 1 for finish parsing
    output [7:0] o_set_filt,
    output [31:0] o_b0,
    output [31:0] o_b1,
    output [31:0] o_b2,
    output [31:0] o_a1,
    output [31:0] o_a2
);

localparam S_IDLE   = 3'd0;
localparam S_PARSE  = 3'd1;
localparam S_FINISH = 3'd2;

logic [2:0] state_r, state_w;
logic [167:0] payload_r, payload_w;
logic finish;

logic [7:0] counter_r, counter_w; // need to read 168 bytes

assign o_set_coef = finish;
assign o_set_filt = payload_r[167:160];
assign o_b0 = payload_r[159:128];
assign o_b1 = payload_r[127:96];
assign o_b2 = payload_r[95:64];
assign o_a1 = payload_r[63:32];
assign o_a2 = payload_r[31:0];


always_comb begin
    state_w = state_r;
    counter_w = counter_r;
    payload_w = payload_r;
    finish = 0;

    case (state_r)
        S_IDLE: begin
            if (i_start) begin                
                if (udp_rx_valid) begin
                    payload_w[counter_r-8'd1 -: 8] = udp_rx_data;
                    counter_w = counter_r - 8'd8;
                    if (counter_r == 8'd8 || udp_rx_last) begin // read 168 bits or finish
                        state_w = S_FINISH;
                    end
                end
            end
            else begin
                state_w = S_IDLE;
            end
        end
        S_FINISH: begin
            if (counter_r == 8'd0) begin // have read 168
                finish = 1;
            end
            state_w = S_IDLE;
            counter_w = 8'd168;
        end
        default: begin
            state_w = state_r;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= 0;
        counter_r <= 8'd168;
        payload_r <= 0;
    end
    else begin
        state_r <= state_w;
        counter_r <= counter_w;
        payload_r <= payload_w;
    end
end

endmodule