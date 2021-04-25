`timescale 1ns/1ps

/*
    module name : clk_gen
    Father module name : UART
    Author: Chris Wang
    Company: MTK-HF
    Date: 2021-04-25
*/

module clk_gen#(
    parameter   CLK_FREQ=50_000_000,
                BAUD_RATE=9600
    )
(
    input   clk,
    input   rst_n,
    input   uart_en,
    output  bps_clk
    );

reg     bps_clk;

localparam  BPS_CNT =    CLK_FREQ/BAUD_RATE-1;
localparam  BPS_WD  =    clogb2(BPS_CNT);

localparam  START = 1'b1;
localparam  STOP  = 1'b0;

//function: calcute log2 N
function integer clogb2 (input integer bit_depth);
    begin
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
            bit_depth = bit_depth>>1;
    end
endfunction

reg [BPS_WD-1 : 0] cnt;

reg cstate;
reg nstate;

//FSM-1
always @(posedge clk or posedge rst)
    if (rst)
        // reset
        cstate <= 'b0;
    else 
       cstate <= nstate; 

//FSM-2
always @(*) 
    case(cstate)
        START: nstate =  uart_en ? START: STOP;
        STOP : nstate = (!uart_en) STOP : START;
        default:  nstate = STOP;
    endcase


//FSM-3
always @(posedge clk or posedge rst)
    if (rst)
        // reset
        cnt <= {BPS_WD{1'b0}};
    else if (STOP) 
        cnt <= {BPS_WD{1'b0}};
    else if(cnt == BPS_CNT)
        cnt <= {BPS_WD{1'b0}};
    else
        cnt <=  cnt + 'd1;

//bps generate
always @(posedge clk or posedge rst)
    if (rst)
        // reset
        bps_clk <= 1'b0;
    else if (cnt == 'd1)
        bps_clk <= 1'b1;
    else 
        bps_clk <= 1'b0;

endmodule
