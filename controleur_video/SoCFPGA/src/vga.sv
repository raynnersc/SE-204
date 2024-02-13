module vga
#(
    parameter HDISP = 800,  // Largeur de l'image affichée
    parameter VDISP = 480   // Hauteur de l'image affichée
) 
(
    // Entrées
    input wire pixel_clk,
    input wire pixel_rst,
    // Interface
    video_if.master video_ifm,
    wshb_if.master  wshb_ifm
);

// ---------------------------------------------------------
// Paramètres temporels
localparam Fpix     = 32000000;     // Fréquence pixel
localparam Fdisp    = 66;           // Fréquence image
localparam HFP      = 40;           // Horizontal Front Porch40
localparam HPULSE   = 48;           // Largeur de la synchro ligne
localparam HBP      = 40;           // Horizontal Back Porch
localparam VFP      = 13;           // Vertical Front Porch
localparam VPULSE   = 3;            // Largeur de la sync image
localparam VBP      = 29;           // Vertical Back Porch

// ---------------------------------------------------------
// Signaux pour les compteurs
localparam pix_max_value = HFP + HPULSE + HBP + HDISP;
localparam row_max_value = VFP + VPULSE + VBP + VDISP;
localparam PIX_MAX = $clog2(pix_max_value);
localparam ROW_MAX = $clog2(row_max_value);

localparam zone_aff_begin_hoz = HFP + HPULSE + HBP;
localparam zone_aff_begin_ver = VFP + VPULSE + VBP;

logic[ROW_MAX - 1 : 0] num_row;     // Lignes dans une image
logic[PIX_MAX - 1 : 0] num_pixel;   // Pixels dans une ligne

// ---------------------------------------------------------
// Signaux pour la FIFO
logic full_once_OK;

wire fifo_wfull;
wire fifo_walmost_full;
wire fifo_rempty;

// ---------------------------------------------------------
// Assigns
assign video_ifm.CLK = pixel_clk;

// ---------------------------------------------------------
// Compteurs
always_ff @(posedge pixel_clk)
begin
    if (pixel_rst) begin
        num_row <= 0;
        num_pixel <= 0;
    end
    else begin
        if (num_pixel == pix_max_value - 1) begin
            num_pixel <= 0;
            if (num_row == row_max_value - 1)
                num_row <= 0;
            else
                num_row <= num_row + 1;
        end
        else begin
            num_pixel <= num_pixel + 1;
        end
    end
end

// ---------------------------------------------------------
// Génération des signaux de synchro
always_ff @(posedge pixel_clk)
begin
    if (pixel_rst) begin
        video_ifm.HS <= 1'b1;
        video_ifm.VS <= 1'b1;
        video_ifm.BLANK <= 1'b1;
    end
    else begin
        // Signal HS (Horizontal Synchro)
        if (num_pixel < HFP)
            video_ifm.HS <= 1'b1;
        else if ((num_pixel >= HFP) && (num_pixel < HFP + HPULSE))
            video_ifm.HS <= 1'b0;
        else
            video_ifm.HS <= 1'b1;

        // Signal VS (Vertical Synchro)
        if (num_row < VFP)
            video_ifm.VS <= 1'b1;
        else if ((num_row >= VFP) && (num_row < VFP + VPULSE))
            video_ifm.VS <= 1'b0;
        else
            video_ifm.VS <= 1'b1;
        
        // Signal BLANK (resync.)
            if ((num_pixel < zone_aff_begin_hoz) || (num_row < zone_aff_begin_ver))
            video_ifm.BLANK <= 1'b0;
        else
            video_ifm.BLANK <= 1'b1;
    end
end

// ---------------------------------------------------------
// Génération des requètes de lecture

assign wshb_ifm.stb     = !fifo_wfull;
assign wshb_ifm.sel     = 4'b1111;
assign wshb_ifm.we      = 1'b0;
assign wshb_ifm.cti     = '0;
assign wshb_ifm.bte     = 1'b0;
assign wshb_ifm.dat_ms  = 32'hc01dcafe;

always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst) begin
        wshb_ifm.adr <= '0;
    end
    else begin
        if (wshb_ifm.ack) begin
            if ((wshb_ifm.adr >> 2) == VDISP * HDISP - 1)
                wshb_ifm.adr <= '0;
            else
                wshb_ifm.adr <= wshb_ifm.adr + 4; 
        end
    end
end

// ---------------------------------------------------------
// FIFO

wire read_from_fifo = video_ifm.BLANK & full_once_OK;

async_fifo #(.DATA_WIDTH(24), .DEPTH_WIDTH(8), .ALMOST_FULL_THRESHOLD(224)) fifo_inst (
    .rst(wshb_ifm.rst), 
    .rclk(pixel_clk), 
    .read(read_from_fifo), 
    .rdata(video_ifm.RGB),
    .rempty(fifo_rempty), 
    .wclk(wshb_ifm.clk), 
    .wdata(wshb_ifm.dat_sm[23:0]), 
    .write(wshb_ifm.ack), 
    .wfull(fifo_wfull),
    .walmost_full(fifo_walmost_full)
);

logic fifo_wfull_reg_sys;

always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst)
        fifo_wfull_reg_sys <= 1'b0;
    else
        fifo_wfull_reg_sys <= fifo_wfull;
end

logic [1:0] fifo_wfull_regs_pix;

always_ff @(posedge pixel_clk)
begin
    if (pixel_rst) begin
        fifo_wfull_regs_pix <= '0;
    end
    else begin
        fifo_wfull_regs_pix <= {fifo_wfull_regs_pix[0],fifo_wfull_reg_sys};
    end
end

wire fifo_wfull_pixelclk = fifo_wfull_regs_pix[1];

always @(posedge pixel_clk) begin
    if (pixel_rst)
        full_once_OK <= 1'b0;
    else
        if (fifo_wfull_pixelclk)
            full_once_OK <= 1'b1;
end

// Dispositif à hysteresis
always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst)
        wshb_ifm.cyc <= 1'b0;
    else if (fifo_wfull)
        wshb_ifm.cyc <= 1'b0;
    else if (!fifo_walmost_full)
        wshb_ifm.cyc <= 1'b1;
end

endmodule
