`timescale 1ns/1ps

/*
    module name : uart_tx
    Father module name : UART
    Author: Chris Wang
    Company: MTK-HF
    Date: 2021-04-25
*/

module uart_tx#(
    parameter   CLK_FREQ    =   50_000_000, //hz
                BAUD_RATE   =   9600,       //9600,19200,38400,57600,115200,230400,460800,921600
                PARITY      =   "None",     // None, Even, Odd
                FRAME_WD    =   8           //5,6,7,8
    )
(
    input                       clk,
    input                       bps_clk,
    input                       send,
    input   [FRAME_WD-1 : 0]    din,
    output                      tx_done,
    output                      busy,
    output                      tx
    );

reg busy;
reg tx_done;
reg tx;

localparam  IDLE    =   6'b00_0000,
            READY   =   6'b00_0001,
            START   =   6'b00_0010,
            SHIFT   =   6'b00_0100,
            PARITY  =   6'b00_1000,
            STOP    =   6'b01_0000,
            DONE    =   6'b10_0000;

wire    [1:0]   parity_mode;

generate 
    if(PARITY == "None") assign parity_mode = 2'b00;
    else if (PARITY == "Even") assign parity_mode = 2'b01;
    else  assign parity_mode = 2'b10;
endgenerate 

reg     [FRAME_WD-1 : 0]            data_reg;
reg     [clogb2(FRAME_WD-1)-1 : 0]  cnt;
reg                                 parity_even;
reg     [5:0]                       cstate;
reg     [5:0]                       nstate;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        cnt <= 'd0;        
    end
    else if (cstate == SHIFT && bps_clk == 1'b1) begin
        if(cnt == FRAME_WD -1) cnt <= 'd0;
        else cnt <= cnt + 'd1;
    end
    else cnt <= cnt;
end

//FSM-1
always @(posedge clk or posedge rst)
    if (rst)
        // reset
        cstate <= IDLE;
    else 
       cstate <= nstate; 

//FSM-2
always @(*) 
    case(cstate)
        IDLE    :       nstate = send           ? READY : IDLE;
        READY   :       nstate = (bps_clk == 1) ? START : READY;
        START   :       nstate = (bps_clk == 1) ? SHIFT : START;
        SHIFT   :       nstate = (bps_clk == 1 && cnt == FRAME_WD -1) PARITY : SHIFT;
        PARITY  :       nstate = (bps_clk == 1) ? STOP  : PARITY;
        STOP    :       nstate = (bps_clk == 1) ? DONE  : STOP;
        DONE    :       nstate = IDLE;
        default :       nstate = IDLE;
    endcase

always @(posedge clk or posedge rst)
    if(rst)begin
        data_reg    <= 'd0;
        tx          <=  1'b1;
        tx_done     <=  1'b0;
        busy        <=  1'b0;
        parity_even <=  1'b0;
    end
    else begin
        case(cstate)
            IDLE    :   begin
                            data_reg    <=  'd0;
                            tx_done     <=  1'b0;
                            busy        <=  1'b0;
                            tx          <=  1'b1;
                        end
            READY   :   begin
                            data_reg    <=  'd0;
                            tx_done     <=  1'b0;
                            tx          <=  1'b1;
                            busy        <=  1'b1;
                        end
            START   :   begin
                            data_reg    <=  din;
                            tx_done     <=  1'b0;
                            parity_even <=  ^din; //d[0]^d[1]----^d[7]
                            tx          <=  1'b1;
                            busy        <=  1'b1;
                        end
            SHIFT   :   begin
                            if(bps_clk == 1) begin
                            //LSB first. we can use generate command so that we can use MSB first
                                data_reg    <=  {1'b0, data_reg{FRAME_WD-1:1}};
                                tx          <=  data_reg[0];
                            end
                                data_reg    <=  data_reg;
                                tx          <=  tx;
                                tx_done     <=  1'b0;
                                busy        <=  1'b1;
                        end
            PARITY  :   begin
                            data_reg    <=  data_reg;
                            case(parity_mode)
                                2'b00 : tx <= 1'b1;
                                2'b01 : tx <= parity_even;
                                2'b10 : tx <= !parity_even;
                                default : tx <= 1'b1;
                            endcase
                            tx_done     <=  1'b0;
                            busy        <=  1'b1;
                        end
            STOP    :   begin
                            tx_done     <=  1'b0;
                            tx          <=  1'b1;
                            busy        <=  1'b1;                        
                        end
            DONE    :   begin
                            tx_done     <=  1'b1;
                            tx          <=  1'b1;
                            busy        <=  1'b0;                        
                        end
            default :   begin
                            data_reg    <=  'd0;
                            tx_done     <=  1'b0;
                            tx          <=  1'b1;
                            parity_even <=  1'b0;
                            busy        <=  1'b0; 
                        end
        endcase
    end
//function: calcute log2 N
function integer clogb2 (input integer bit_depth);
    begin
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
            bit_depth = bit_depth>>1;
    end
endfunction
endmodule
