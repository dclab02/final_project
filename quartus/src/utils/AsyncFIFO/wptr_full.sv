module wptr_full
#( parameter ADDRSIZE = 4)
(
    output reg                wfull,
    output     [ADDRSIZE-1:0] waddr,
    output reg [ADDRSIZE :0]  wptr,
    input      [ADDRSIZE :0]  wq2_rptr,
    input                     winc, 
    input                     wclk, 
    input                     wrst_n
);

logic   [ADDRSIZE:0] wbin;
logic   [ADDRSIZE:0] wgraynext, wbinnext;
logic                wfull_val;


always @(posedge wclk or negedge wrst_n)  
if(!wrst_n) begin
    wbin <= 0;
    wptr <= 0;
end  
else begin  
    wbin <= wbinnext;
    wptr <= wgraynext;
end  

//gray code counting logic
assign wbinnext  = !wfull ? wbin + winc : wbin;
assign wgraynext = (wbinnext>>1) ^ wbinnext;
assign waddr = wbin[ADDRSIZE-1:0];

//-------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] != wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]== wq2_rptr[ADDRSIZE-2:0]))
//-------------------------------

assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});
                      
always @(posedge wclk or negedge wrst_n)
if(!wrst_n) begin
    wfull <= 1'b0;
end
else begin
    wfull <= wfull_val;
end
endmodule