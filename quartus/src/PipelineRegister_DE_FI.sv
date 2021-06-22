module PipelineRegister_DE_FI(
    input   i_rst_n,
	input   i_clk,
	input   i_stall,
    input   [7:0] i_signal, 
    output  [7:0] o_signal
);

logic [7:0] signal_w, signal_r;

assign o_signal = signal_r;

always_comb begin
    signal_w = signal_r;
    if (!i_stall) begin
        signal_w = i_signal;
    end
end

always_ff @(negedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        signal_r <= 16'b0;
	end
	else begin
		signal_r <= signal_w;
	end
end
endmodule 