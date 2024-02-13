module mire
#(
    parameter HDISP = 800,  // Largeur de l'image affichée
    parameter VDISP = 480   // Hauteur de l'image affichée
) 
(
    wshb_if.master  wshb_ifm
);

// Variables
logic[5 : 0] num_request;

// Assigns pour une requête d'écriture
assign wshb_ifm.cyc = wshb_ifm.stb;
assign wshb_ifm.we = 1'b1;
assign wshb_ifm.sel = 4'hF;
assign wshb_ifm.bte = 1'b0;
assign wshb_ifm.cti = 1'b0;
assign wshb_ifm.dat_ms = (num_request % 16) ? 32'hFFFF00 : 32'h00FF00; // Afficher des couleurs différentes

// Compteur de requêtes d'écriture
always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst || (num_request == 63)) begin
        num_request <= 0;
        wshb_ifm.stb <= 1'b0;
    end
    else begin
        wshb_ifm.stb <= 1'b1;
        if (wshb_ifm.ack) begin
            num_request <= num_request + 1;
        end
    end
end

// Compteur d'addresse
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

endmodule
