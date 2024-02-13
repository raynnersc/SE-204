
module wrapper(
    input wire clk,
    input wire rst,
    output wire [31:0] dat_sm,
    input  wire [31:0] dat_ms,
    input wire [31:0] adr,
    input wire cyc,
    input wire [3:0] sel,
    input wire stb,
    input wire we,
    output wire ack,
    output wire err,
    output wire rty,
    input wire [2:0] cti,
    input wire [1:0] bte) ;


wshb_if #(.DATA_BYTES(4)) wshb_if0(clk,rst) ;

assign dat_sm = wshb_if0.dat_sm ;
assign ack = wshb_if0.ack ;
assign err = wshb_if0.err ;
assign rty = wshb_if0.rty ;
assign wshb_if0.dat_ms = dat_ms;
assign wshb_if0.adr =  adr;
assign wshb_if0.cyc =  cyc;
assign wshb_if0.sel =  sel;
assign wshb_if0.stb =  stb;
assign wshb_if0.we = we;
assign wshb_if0.cti =  cti;

wb_bram u_ctrl
  (
   .wb_s(wshb_if0.slave)
  );

endmodule


