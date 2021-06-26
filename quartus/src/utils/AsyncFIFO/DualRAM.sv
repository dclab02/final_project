module DualRAM  
#(  
    parameter DATA_SIZE = 16,
    parameter ADDR_SIZE = 4
)  
(  
    input                       wclken,wclk,  
    input      [ADDR_SIZE-1:0]  raddr,     //RAM read address
    input      [ADDR_SIZE-1:0]  waddr,     //RAM write address
    input      [DATA_SIZE-1:0]  wdata,    //data input
    output     [DATA_SIZE-1:0]  rdata      //data output
);      
  
localparam RAM_DEPTH = 1 << ADDR_SIZE;   //RAM depth = 2^ADDR_WIDTH
logic [DATA_SIZE-1:0] Mem[RAM_DEPTH-1:0];

assign rdata =  Mem[raddr];
always@(posedge wclk)
begin  
    if(wclken)
        Mem[waddr] <= wdata;
end

endmodule