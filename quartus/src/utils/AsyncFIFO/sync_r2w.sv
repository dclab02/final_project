module sync_r2w   
#(parameter ADDRSIZE = 8)  
(
    output reg [ADDRSIZE:0] wq2_rptr,
    input      [ADDRSIZE:0] rptr,
    input                   wclk, 
    input                   wrst_n
);

logic [ADDRSIZE:0] wq1_rptr;

always @(posedge wclk or negedge wrst_n)
if(!wrst_n) begin
    {wq2_rptr,wq1_rptr} <= 0;
end
else begin
    {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
end

endmodule