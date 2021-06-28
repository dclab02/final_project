module PipelineRegister_FI_AS(
    input   i_rst_n,
    input   i_clk,
    input   i_stall,
    input   [15:0] i_signal, 
    output  [15:0] o_signal
);

logic [15:0] signal_r;

assign o_signal = signal_r;


always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        signal_r <= 16'b0;
    end
    else if (!i_stall) begin
        signal_r <= i_signal;
    end
end
endmodule