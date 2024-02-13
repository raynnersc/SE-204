module wshb_intercon 
(
    wshb_if.master  wshb_ifm,
    wshb_if.slave   wshb_ifs_mire,
    wshb_if.slave   wshb_ifs_vga
);

// Token = 1 -> VGA 
// Token = 0 -> MIRE 
logic token;

// Assigns
assign wshb_ifs_vga.err = 1'b0;
assign wshb_ifs_vga.rty = 1'b0;

assign wshb_ifs_mire.err = 1'b0;
assign wshb_ifs_mire.rty = 1'b0;

// En mettant en correspondance les signaux
always_comb
begin
    if (token) begin
        // Le module VGA a été élu
        wshb_ifs_vga.ack    = wshb_ifm.ack;
        wshb_ifs_vga.dat_sm = wshb_ifm.dat_sm;

        // En neutralisant les signaux du maître non élu
        wshb_ifs_mire.ack = 1'b0;
        wshb_ifs_mire.dat_sm = '0;

        // En mettant en correspondance les signaux du maître élu
        wshb_ifm.cyc    = wshb_ifs_vga.cyc;
        wshb_ifm.stb    = wshb_ifs_vga.stb;
        wshb_ifm.we     = wshb_ifs_vga.we;
        wshb_ifm.adr    = wshb_ifs_vga.adr;
        wshb_ifm.sel    = wshb_ifs_vga.sel;
        wshb_ifm.dat_ms = wshb_ifs_vga.dat_ms;
        wshb_ifm.cti    = wshb_ifs_vga.cti;
        wshb_ifm.bte    = wshb_ifs_vga.bte;
    end
    else begin
        // Le module MIRE a été élu
        wshb_ifs_mire.ack    = wshb_ifm.ack;
        wshb_ifs_mire.dat_sm = wshb_ifm.dat_sm;

        // En neutralisant les signaux du maître non élu
        wshb_ifs_vga.ack = 1'b0;
        wshb_ifs_vga.dat_sm = '0;

        // En mettant en correspondance les signaux du maître élu
        wshb_ifm.cyc    = wshb_ifs_mire.cyc;
        wshb_ifm.stb    = wshb_ifs_mire.stb;
        wshb_ifm.we     = wshb_ifs_mire.we;
        wshb_ifm.adr    = wshb_ifs_mire.adr;
        wshb_ifm.sel    = wshb_ifs_mire.sel;
        wshb_ifm.dat_ms = wshb_ifs_mire.dat_ms;
        wshb_ifm.cti    = wshb_ifs_mire.cti;
        wshb_ifm.bte    = wshb_ifs_mire.bte;
    end
end

// L'arbitre
always_ff @(posedge wshb_ifm.clk)
begin
    if (wshb_ifm.rst) begin
        token <= 1'b0;
    end
    else begin
        // Si le module mire a le jeton et si son signal cyc est à 0, alors l'arbitre donnera le jeton au module vga
        if (!token && !wshb_ifs_mire.cyc)
            token <= 1'b1;
        // Si le module vga a le jeton et si son signal cyc est à 0, alors l'arbitre donnera le jeton au module mire
        else if (token && !wshb_ifs_vga.cyc)
            token <= 1'b0;
        // Sinon le module ayant le jeton continue avec lui
        else
            token <= token;
    end
end

endmodule
