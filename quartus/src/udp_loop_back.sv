module udp_loop_back (
    input i_rst_n,
    input i_clk,

    input i_stall,

    input [15:0] i_data,

    input  udp_tx_ready,
    output logic udp_tx_valid,
    output logic udp_tx_last,
    output [7:0] udp_tx_data
);

localparam S_IDLE = 2'd0;
localparam S_FIRST = 2'd1;
localparam S_SECOND = 2'd2;

logic [1:0] state_r, state_w;

logic [15:0] data_r, data_w;
logic [3:0] counter;

// [15:8], [7:0]
assign udp_tx_data = data_r[counter -: 8];

always_comb begin
    state_w = state_r;
    data_w = data_r;
    udp_tx_last = 0;
    udp_tx_valid = 0;
    counter = 0;
    case (state_r)
        S_IDLE: begin
            if (!i_stall) begin
                state_w = S_FIRST;
                data_w = i_data;
            end
        end
        S_FIRST: begin
            counter = 4'd15;
            udp_tx_valid = 1;
            state_w = S_SECOND;
        end
        S_SECOND: begin
            counter = 4'd7;
            udp_tx_valid = 1;
            udp_tx_last = 1;
            state_w = S_IDLE;

        end
        default:
            state_w = state_r;
    endcase

end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= 0;
        data_r <= 0;
    end
    else begin
        state_r <= state_w;
        data_r <= data_w;
    end
end

endmodule;