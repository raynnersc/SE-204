module MED
#(
    parameter DATA_WIDTH = 8,
    parameter DATA_QTDE = 9
)
(
    input DSI,
    input BYP,
    input CLK,
    input  [DATA_WIDTH-1:0] DI,
    output [DATA_WIDTH-1:0] DO
);

logic [DATA_WIDTH-1:0] R [0:DATA_QTDE-1];

//wire [DATA_WIDTH-1:0] A;
wire [DATA_WIDTH-1:0] B;
wire [DATA_WIDTH-1:0] MAX;
wire [DATA_WIDTH-1:0] MIN;

MCE #(.DATA_WIDTH(DATA_WIDTH)) I_MCE (.A(DO), .B(B), .MAX(MAX), .MIN(MIN));

always_ff @(posedge CLK)
begin
    if(DSI)
        R[0] <= DI;
    else
        R[0] <= MIN;
    
    for (int i = 1; i < DATA_QTDE - 1; i++) begin
        R[i] <= R[i-1];
    end

    if(BYP)
        R[DATA_QTDE-1] <= R[DATA_QTDE-2];
    else
        R[DATA_QTDE-1] <= MAX;
end

assign DO = R[DATA_QTDE-1];
assign B = R[DATA_QTDE-2];

endmodule