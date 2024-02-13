module MCE
#(
    parameter DATA_WIDTH = 8
)
(
    input  [DATA_WIDTH-1:0] A,
    input  [DATA_WIDTH-1:0] B,
    output [DATA_WIDTH-1:0] MAX,
    output [DATA_WIDTH-1:0] MIN
);

assign {MAX,MIN} = A > B ? {A,B} : {B,A};

endmodule