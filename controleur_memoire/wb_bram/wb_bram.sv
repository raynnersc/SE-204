//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre 
// de mots de la mémoire : (2048 pour mem_adr_width=11)

module wb_bram #(parameter mem_adr_width = 11) (
      // Wishbone interface
      wshb_if.slave wb_s
      );
      
      logic[7:0] mem0 [0 : 2**mem_adr_width - 1];
      logic[7:0] mem1 [0 : 2**mem_adr_width - 1];
      logic[7:0] mem2 [0 : 2**mem_adr_width - 1];
      logic[7:0] mem3 [0 : 2**mem_adr_width - 1];

      wire we0, we1, we2, we3;
      wire[mem_adr_width - 1 : 0] adr;
      
      logic[4:0] bte;
      logic ack_r, ack_w;
      logic counter;

      assign adr = bte ? ((wb_s.adr >> 2) + counter) % bte : ((wb_s.adr >> 2) + counter);
      assign ack_w = wb_s.stb && wb_s.we;
      assign wb_s.ack = ack_w || ack_r;

      assign we0 = wb_s.we && wb_s.sel[0];
      assign we1 = wb_s.we && wb_s.sel[1];
      assign we2 = wb_s.we && wb_s.sel[2];
      assign we3 = wb_s.we && wb_s.sel[3];

      assign wb_s.rty = 1'b0;
      assign wb_s.err = 1'b0;

      always_comb
      begin
            case (wb_s.bte)
                  2'b00:
                        bte = 0;
                  2'b01:
                        bte = 4;
                  2'b10:
                        bte = 8;
                  2'b11:
                        bte = 16;
            endcase
      end

      always_ff @(posedge wb_s.clk)
      begin
            if(!wb_s.rst && wb_s.stb)
            begin
                  if(ack_w) begin
                        if(we0)
                              mem0[adr] <= wb_s.dat_ms[7:0];
                        if(we1)
                              mem1[adr] <= wb_s.dat_ms[15:8];
                        if(we2)
                              mem2[adr] <= wb_s.dat_ms[23:16];
                        if(we3)
                              mem3[adr] <= wb_s.dat_ms[31:24];
                  end
                  else begin
                        if(ack_r && ((wb_s.cti == 3'b111) || (wb_s.cti == 3'b000)))
                              ack_r <= 1'b0;
                        else
                              ack_r <= 1'b1;
                              
                        if(wb_s.cti == 3'b010)
                              counter <= 1;
                        else
                              counter <= 0;
                  end
                  
                  wb_s.dat_sm <= {mem3[adr], mem2[adr], mem1[adr], mem0[adr]}; 
            end
      end

     /*
      always_ff @(posedge wb_s.clk)
      begin
            if(ack_r || (wb_s.cti == 3))
                  ack_r <= 1'b0;
            else
                  ack_r <= !wb_s.we && wb_s.stb;           
      end
      */ 

endmodule