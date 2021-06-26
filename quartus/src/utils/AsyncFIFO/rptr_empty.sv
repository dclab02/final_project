module rptr_empty   
#(parameter ADDRSIZE = 4)  
(
    output reg                rempty,
    output     [ADDRSIZE-1:0] raddr,
    output reg [ADDRSIZE:0]   rptr,
    input       [ADDRSIZE:0]  rq2_wptr,
    input                     rinc,
    input                     rclk,
    input                     rrst_n
      
);  

  
logic   [ADDRSIZE:0] rbin;  
logic   [ADDRSIZE:0] rgraynext, rbinnext;  
logic   rempty_val;  
 
always @(posedge rclk or negedge rrst_n)  
if(!rrst_n) begin   
    rbin <= 0;
    rptr <= 0;
end
else begin
    rbin <= rbinnext; 
    rptr <= rgraynext;
end  
          
//gray code counting logic
  
assign rbinnext = !rempty ? (rbin + rinc) : rbin;
assign rgraynext = (rbinnext>>1) ^ rbinnext;  //binary to gray code
assign raddr = rbin[ADDRSIZE-1:0];

//---------------------  
// FIFO empty when the next rptr == synchronized wptr or on reset  
//---------------------
  
assign rempty_val = (rgraynext == rq2_wptr);  
  
always @(posedge rclk or negedge rrst_n)  
if(!rrst_n) begin  
    rempty <= 1'b1;
end
else begin  
    rempty <= rempty_val;
end
      
endmodule 