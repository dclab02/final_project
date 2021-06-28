module AsyncFIFO
#(parameter ASIZE = 8,
   parameter DSIZE = 16)
 (
    input  [DSIZE-1:0] wdata,
    input              winc, wclk, wrst_n,
    input              rinc, rclk, rrst_n,
    output [DSIZE-1:0] rdata,
    output             wfull,
    output             rempty
 );

logic [ASIZE-1:0] waddr, raddr;
logic [ASIZE:0]   wptr, rptr, wq2_rptr, rq2_wptr;        


sync_r2w I1_sync_r2w(
    .wq2_rptr(wq2_rptr), 
    .rptr(rptr),
    .wclk(wclk), 
    .wrst_n(wrst_n)
    );

sync_w2r I2_sync_w2r (
    .rq2_wptr(rq2_wptr), 
    .wptr(wptr),
    .rclk(rclk), 
    .rrst_n(rrst_n)
    );

/* DualRAM */

DualRAM #(DSIZE, ASIZE) I3_DualRAM(
    .rdata(rdata), 
    .wdata(wdata),
    .waddr(waddr), 
    .raddr(raddr),
    .wclken(winc), 
    .wclk(wclk)
    );

/* 空、滿比較邏輯 */

rptr_empty #(ASIZE) I4_rptr_empty(
    .rempty(rempty),
    .raddr(raddr),
    .rptr(rptr), 
    .rq2_wptr(rq2_wptr),
    .rinc(rinc), 
    .rclk(rclk),
    .rrst_n(rrst_n)
    );

wptr_full #(ASIZE) I5_wptr_full(
    .wfull(wfull), 
    .waddr(waddr),
    .wptr(wptr), 
    .wq2_rptr(wq2_rptr),
    .winc(winc), 
    .wclk(wclk),
    .wrst_n(wrst_n)
    );

endmodule