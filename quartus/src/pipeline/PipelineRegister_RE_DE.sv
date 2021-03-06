module PipelineRegister_RE_DE(
    input   i_rst_n,
    input   i_clk,
    input   i_stall,
    input   [7:0] i_D_value,
    input   [7:0] i_Q_value, 
    output  [7:0] o_D_value,
    output  [7:0] o_Q_value
);

logic [7:0] D_r, Q_r;

assign o_D_value = D_r;
assign o_Q_value = Q_r;



always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        D_r <= 8'b0;
        Q_r <= 8'b0;
    end
    else if (!i_stall) begin
        D_r <= i_D_value;
        Q_r <= i_Q_value;
    end
end

endmodule 