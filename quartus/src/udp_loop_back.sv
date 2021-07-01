module udp_loop_back (
    input i_rst_n,
    input i_clk,

    input i_stall_falling,
    input i_stall,
    input i_eqvalid,

    input [15:0] i_data,

    input udp_tx_hdr_ready,
    output logic udp_tx_hdr_valid,
    input  udp_tx_ready,
    output logic udp_tx_valid,
    output logic udp_tx_last,
    output [7:0] udp_tx_data
);

localparam S_IDLE = 2'd0;
localparam S_WAIT = 2'd1;
localparam S_FIRST = 2'd2;
localparam S_SECOND = 2'd3;


logic eqvalid_r, eqvalid_w;

logic [1:0] state_r, state_w;

logic valid_r, valid_w;
logic last_r, last_w;

logic [15:0] data_r, data_w;
logic [3:0] counter;

// [15:8], [7:0]
assign udp_tx_data = data_r[counter -: 8];
// assign udp_tx_last = last_r;
// assign udp_tx_valid = valid_r;

always_comb begin
    state_w = state_r;
    data_w = data_r;
    valid_w = valid_r;
    last_w = last_r;
    counter = 4'd15;

    udp_tx_last = 0;
    udp_tx_valid = 0;
    udp_tx_hdr_valid = 0;

    eqvalid_w = i_eqvalid;

    case (state_r)
        S_IDLE: begin
            // state_w = S_WAIT;
            if (i_stall_falling) begin
                data_w = i_data;
                state_w = S_WAIT;
            end
        end
        S_WAIT: begin // start for ip hdr ready, wait header ready
            if (udp_tx_hdr_ready) begin // output ready, store data
                udp_tx_hdr_valid = 1; // input ready
                udp_tx_valid = 1;
                state_w = S_FIRST;
            end
        end
        // send first byte
        S_FIRST: begin
            counter = 4'd15;
            if (udp_tx_ready) begin // wait for output ready
                udp_tx_valid = 1; // input ready
                state_w = S_SECOND; // store data
            end
        end
        S_SECOND: begin
            counter = 4'd7;
            if (udp_tx_ready) begin // wait for output ready
                udp_tx_valid = 1; // input ready
                udp_tx_last = 1;  // last byte ready
                state_w = S_IDLE;
            end
        end
        default:
            state_w = state_r;
    endcase

end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= 0;
        data_r <= 0;
        valid_r <= 0;
        last_r <= 0;
        eqvalid_r <= 0;
    end
    else begin
        state_r <= state_w;
        data_r <= data_w;
        valid_r <= valid_w;
        last_r <= last_w;
        eqvalid_r <= eqvalid_w;
    end
end

endmodule