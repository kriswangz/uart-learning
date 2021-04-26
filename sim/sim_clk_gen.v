`timescale  1ps / 1ps

module tb_clk_gen;

// clk_gen Parameters
parameter PERIOD    = 10        ;
parameter CLK_FREQ  = 50_000_0;
parameter BAUD_RATE = 119200;
// clk_gen Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 1 ;
reg   uart_en                              = 0 ;

// clk_gen Outputs
wire  bps_clk                              ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  0;
end

clk_gen #(
    .CLK_FREQ ( CLK_FREQ ),
    .BAUD_RATE ( BAUD_RATE )
    )
 u_clk_gen (
    .clk                     ( clk       ),
    .rst                     ( rst       ),
    .uart_en                 ( uart_en   ),

    .bps_clk                 ( bps_clk   )
);

initial begin
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, tb_clk_gen);    //tb模块名称 
end


initial
begin
    uart_en = 1;
    #2000 $finish;
end

endmodule