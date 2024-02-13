module MEDIAN
#(
    parameter DATA_WIDTH = 8
)
(
    input DSI,
    input nRST,
    input CLK,
    input  [DATA_WIDTH-1:0] DI,
    
    output logic DSO,
    output [DATA_WIDTH-1:0] DO
);

enum logic[2:0] { IDLE, GET_PIXELS, BYP_OFF, BYP_ON, READY } state;

logic BYP;
logic[3:0] nCLKoff, nCLKon, counter;

MED #(.DATA_WIDTH(DATA_WIDTH), .DATA_QTDE(9)) I_MED(.DSI(DSI), .BYP(BYP), .CLK(CLK), .DI(DI), .DO(DO));

always_ff @(posedge CLK or negedge nRST)
begin
    if(!nRST)
        state <= IDLE;
    else
        case (state)
            IDLE:
                if (DSI)
                    state <= GET_PIXELS; 
            GET_PIXELS:
            begin
                nCLKoff <= 8;
                nCLKon <= 0;
                counter <= 1;
                if (!DSI)
                    state <= BYP_OFF;
            end
            BYP_OFF:
            begin
                if (counter == nCLKoff) begin
                    if (nCLKoff == 4)
                        state <= READY;
                    else
                        state <= BYP_ON;
                    nCLKon <= nCLKon + 1;
                    counter <= 1;
                end
                else begin
                    counter <= counter + 1;
                    state <= BYP_OFF;
                end
            end
            BYP_ON:
            begin
                if (counter == nCLKon) begin
                    state <= BYP_OFF;
                    nCLKoff <= nCLKoff - 1;
                    counter <= 1;
                end
                else begin
                    counter <= counter + 1;
                    state <= BYP_ON;
                end
            end
            READY:
                state <= IDLE;
            default:
                state <= IDLE;
        endcase
end

always_comb
begin
    DSO = 1'b0;
    BYP = 1'b0;
    case (state)
        GET_PIXELS:
            BYP = DSI;
        BYP_ON:
            BYP = 1'b1;
        READY:
            DSO = 1'b1;
        default:
        begin
            DSO = 1'b0;
            BYP = 1'b0;
        end
    endcase
end
            
endmodule