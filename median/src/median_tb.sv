/* L'environnement de simulation de MEDIAN est plus simple que celui de
   MED car nous n'avons pas générer le signal de contrôle BYP et car
   nous savons quand la sortie de MEDIAN est valide grâce au signal DSO.
   Le reste est très similaire ... */


`timescale 1ps/1ps

module MEDIAN_tb;

  bit   [7:0] DI;
  bit   CLK, nRST, DSI;
  wire  [7:0] DO;
  wire  DSO;

  MEDIAN I_MEDIAN(
    .DI   ( DI   ) , .DO  ( DO  ) ,
    .CLK  ( CLK  ) , .DSI ( DSI ) ,
    .nRST ( nRST ) , .DSO ( DSO )
  );

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

    repeat(2)
    begin
      @(negedge CLK);
      nRST = 1'b1;
      repeat(1000) begin
        @(negedge CLK);
        DSI = 1'b1;
        DI = 33;
        repeat($random%2) @(negedge CLK);
        for(int j = 0; j < 9; j = j + 1) begin
          V[j] = {$random} % 256 ;
          DI   = V[j];
          @(negedge CLK);
        end
        DSI = 1'b0;
        // On attend DSO
        while(DSO == 1'b0) @(posedge CLK);

        if(DO !== med_ref(V)) begin
          $display("************************************");
          $error("Erreur : DO = %0d au lieu de %0d", DO, med_ref(V));
          $display("************************************");
          $stop();
        end
        @(posedge CLK) ;
        if(DSO) begin
          $display("************************************");
          $error("Erreur : DSO devrait repasser 0...");
          $display("************************************");
          $stop();
        end
        repeat($random%4) @(negedge CLK);
      end
      repeat(2) @(negedge CLK);
      nRST = 1'b0;
      repeat(2) @(negedge CLK);
    end

    $display("************************************");
    $display("Fin de simulation sans aucune erreur");
    $display("************************************");
    $finish();
  end

  // SVA
  property DSO_DURATION;
    disable iff(!nRST)
    @(posedge CLK)
      DSO |=> !DSO;
  endproperty

  dso_duration: assert property(DSO_DURATION) else $fatal("DSO a 1 durant plus d'un cycle d'horloge");

  property DSO_ONCE;
    disable iff(!nRST)
    @(posedge CLK)
      $fell(DSO) |=> (!DSO until $fell(DSI));
  endproperty

  dso_once: assert property(DSO_ONCE) else $fatal("DSO ne devrait pas repasser à 1 avant le prochain calcul");

endmodule
