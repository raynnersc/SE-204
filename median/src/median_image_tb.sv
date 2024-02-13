/* L'environnement de simulation de MEDIAN est plus simple que celui de
   MED car nous n'avons pas generer le signal de controle BYP et car
   nous savons quand la sortie de MEDIAN est valide grace au signal DSO.
   Le reste est tres similaire ... */

`timescale 1ps/1ps

module MEDIAN_IMAGE_tb;

  bit [7:0] DI;
  bit CLK, nRST, DSI;
  wire [7:0] DO;
  wire DSO;

  MEDIAN I_MEDIAN(.DI(DI), .DSI(DSI), .nRST(nRST), .CLK(CLK), .DO(DO), .DSO(DSO));

  // Fonction calculant la valeur médiane en faisant un tri a bulle.
  // elle servira de référence
  function int unsigned med_ref (input int unsigned V [0:8]);
    int unsigned tmp;
    for(int j = 0; j < 8; j = j + 1)
      for(int k = j + 1; k < 9; k = k + 1)
        if(V[j] < V[k]) begin
          tmp = V[j];
          V[j] = V[k];
          V[k] = tmp;
        end
        return V[4];
  endfunction


  always #10ns CLK = ~CLK;

  initial begin: ENTREES

    int unsigned V[0:8];
    int of;
    logic [7:0] img[0:256*256-1];

    // image résultat au format pgm
    of = $fopen("bogart_filtre.pgm");
    $fdisplay(of, "P2 256 256 255");

    // image source
    $readmemh("bogart_bruite.hex", img);

    @(negedge CLK);
    nRST = 1'b1;

    for(int y = 0; y < 256; y = y + 1)
      for(int x = 0; x < 256; x = x + 1) begin
        for(int i = - 1; i < 2; i = i + 1)
          for(int j = - 1; j < 2; j = j + 1) begin
            int rx,ry;
            rx = x + j;
            ry = y + i;
            rx = (rx == -1) ? 0 : rx;
            rx = (rx == 256) ? 255 : rx;
            ry = (ry == -1) ? 0 : ry;
            ry = (ry == 256) ? 255 : ry;
            V[3 * (i + 1) + j + 1] = img[256 * ry + rx];
          end

        @(negedge CLK);
        DSI = 1'b1;
        for(int i = 0; i < 9; i = i + 1) begin
          DI = V[i];
          @(negedge CLK);
        end
        DSI = 1'b0;

        while(DSO == 1'b0)
          @(posedge CLK);

        if(DO !== med_ref(V)) begin
          $display("************************************");
          $error("Erreur : DO = %0d au lieu de %0d", DO,V[4]);
          $display("************************************");
          $stop();
        end
        $fdisplay(of, "%d", DO);
      end

    $display("************************************");
    $display("Fin de simulation sans aucune erreur");
    $display("************************************");

    $fclose(of);
    $finish();
  end

endmodule
