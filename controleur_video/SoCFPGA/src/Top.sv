`default_nettype none

module Top #(
    parameter HDISP = 800,  // Largeur de l'image affichée
    parameter VDISP = 480   // Hauteur de l'image affichée
) 
(
    // Les signaux externes de la partie FPGA
	input  wire         FPGA_CLK1_50,
	input  wire  [1:0]	KEY,
	output logic [7:0]	LED,
	input  wire	 [3:0]	SW,
    // Les signaux du support matériel son regroupés dans une interface
    hws_if.master       hws_ifm,
    video_if.master     video_ifm
);

//====================================
//  Déclarations des signaux internes
//====================================
  wire        sys_rst;   // Le signal de reset du système
  wire        sys_clk;   // L'horloge système a 100Mhz
  wire        pixel_clk; // L'horloge de la video 32 Mhz

//=======================================================
//  La PLL pour la génération des horloges
//=======================================================

sys_pll  sys_pll_inst(
		   .refclk(FPGA_CLK1_50),   // refclk.clk
		   .rst(1'b0),              // pas de reset
		   .outclk_0(pixel_clk),    // horloge pixels a 32 Mhz
		   .outclk_1(sys_clk)       // horloge systeme a 100MHz
);

//=============================
//  Les bus Wishbone internes
//=============================
wshb_if #( .DATA_BYTES(4)) wshb_if_sdram  (sys_clk, sys_rst);
wshb_if #( .DATA_BYTES(4)) wshb_if_stream (sys_clk, sys_rst);

//=============================
//  Le support matériel
//=============================
hw_support hw_support_inst (
    .wshb_ifs (wshb_if_sdram),
    .wshb_ifm (wshb_if_stream),
    .hws_ifm  (hws_ifm),
	.sys_rst  (sys_rst), // output
    .SW_0     ( SW[0] ),
    .KEY      ( KEY )
 );

//=============================
// On neutralise l'interface
// du flux video pour l'instant
// A SUPPRIMER PLUS TARD
//=============================
/*
NEUTRALISATION DE L'INTERFACE wshb_if_stream
assign wshb_if_stream.ack = 1'b1;
assign wshb_if_stream.dat_sm = '0 ;
assign wshb_if_stream.err =  1'b0 ;
assign wshb_if_stream.rty =  1'b0 ;
*/
//=============================
// On neutralise l'interface SDRAM
// pour l'instant
// A SUPPRIMER PLUS TARD
//=============================
/*-------------------------------
NEUTRALISATION DE L'INTERFACE wshb_if_sdram

assign wshb_if_sdram.stb  = 1'b0;
assign wshb_if_sdram.cyc  = 1'b0;
assign wshb_if_sdram.we   = 1'b0;
assign wshb_if_sdram.adr  = '0  ;
assign wshb_if_sdram.dat_ms = '0 ;
assign wshb_if_sdram.sel = '0 ;
assign wshb_if_sdram.cti = '0 ;
assign wshb_if_sdram.bte = '0 ;
---------------------------------*/


//--------------------------
//------- Code Eleves ------
//--------------------------

// Paramètres conditionelles
`ifdef SIMULATION
  localparam hcmpt=50 ;
  localparam hcmpt_pixel=16 ;
`else
  localparam hcmpt=50000000 ;
  localparam hcmpt_pixel=16000000 ;
`endif

// Signaux pour les compteurs
localparam CPT1_WIDTH = $clog2(hcmpt);
localparam CPT2_WIDTH = $clog2(hcmpt_pixel);

logic[CPT1_WIDTH - 1 : 0] counter_1;
logic[CPT2_WIDTH - 1 : 0] counter_2;
logic pixel_rst, pixel_rst_intern;

// Assigns
assign LED[0] = KEY[0];

// Compteur 1Hz - CLK = 100MHz
always_ff @(posedge sys_clk)
begin
    if (sys_rst) begin
        counter_1 <= 0;
        LED[1] <= 1'b0;
    end
    else begin
        if (counter_1 == hcmpt - 1) begin
            LED[1] <= ~LED[1];
            counter_1 <= 0;
        end
        else begin
            counter_1 <= counter_1 + 1;
        end
    end
end

// Compteur 1Hz - CLK = 32MHz
always_ff @(posedge pixel_clk)
begin
    if (pixel_rst) begin
        counter_2 <= 0;
        LED[2] <= 1'b0;
    end
    else begin
        if (counter_2 == hcmpt_pixel - 1) begin
            LED[2] <= ~LED[2];
            counter_2 <= 0;
        end
        else begin
            counter_2 <= counter_2 + 1;
        end
    end
end

// Synchronisation du RESET
always_ff @(posedge pixel_clk or posedge sys_rst)
begin
    if (sys_rst) begin
        pixel_rst <= 1'b1;
        pixel_rst_intern <= 1'b1;
    end
    else begin
        pixel_rst_intern <= 1'b0;
        pixel_rst <= pixel_rst_intern;
    end
end

// Instance des sous-module
wshb_if #( .DATA_BYTES(4)) wshb_if_vga  (sys_clk, sys_rst);
//wshb_if #( .DATA_BYTES(4)) wshb_if_mire  (sys_clk, sys_rst);

vga #(
    .HDISP (HDISP),
    .VDISP (VDISP)
)
vga_inst (
    .pixel_clk (pixel_clk),
    .pixel_rst (pixel_rst),
    .video_ifm (video_ifm),
    .wshb_ifm  (wshb_if_vga)
);

/* NEUTRALISATION DU MODULE MIRE
mire #(
    .HDISP (HDISP),
    .VDISP (VDISP)
)
mire_inst (
    .wshb_ifm(wshb_if_mire)
);
*/

wshb_intercon wshb_intercon_inst (
    .wshb_ifm(wshb_if_sdram),
    .wshb_ifs_mire(wshb_if_stream),
    .wshb_ifs_vga(wshb_if_vga)
);

endmodule
