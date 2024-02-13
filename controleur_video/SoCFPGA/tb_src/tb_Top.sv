`timescale 1ns/1ps

`default_nettype none

module tb_Top;

// Entrées sorties extérieures
bit   FPGA_CLK1_50;
logic [1:0]	KEY;
wire  [7:0]	LED;
logic [3:0]	SW;

// Interface vers le support matériel
hws_if      hws_ifm();

// Interface de video
video_if    video_if0();

// Instance du module Top et du module Screen
Top #(.HDISP (160), .VDISP (90)) Top0 (.*, .video_ifm(video_if0)) ;
screen #(.mode(13),.X(160),.Y(90)) screen0(.video_ifs(video_if0))  ;

///////////////////////////////
//  Code élèves
//////////////////////////////

always #10ns FPGA_CLK1_50 = ~FPGA_CLK1_50;

initial begin
    KEY[0] = 1'b1; #128ns
    KEY[0] = 1'b0; #128ns
    KEY[0] = 1'b1;
end

always #4ms $stop;

endmodule
