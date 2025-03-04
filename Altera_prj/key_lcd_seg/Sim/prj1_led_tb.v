`timescale 1 ns/1 ns

module prj1_led_tb();

//时钟和复位
reg         clk  ;
reg         rst_n;
wire [7:0]  led  ; 
parameter CYCLE    = 20;
//复位时间，此时表示复位3个时钟周期的时间。
parameter RST_TIME = 3 ;

 //待测试的模块例化
 prj1_led  uut(
     .clk          (clk     ), 
     .rst_n        (rst_n   ),
     .led          (led    )
    
     );


 //生成本地时钟50M
 initial begin
     clk = 0;
     forever
     #(CYCLE/2)
     clk=~clk;
 end

 //产生复位信号
 initial begin
     rst_n = 1;
     #2;
     rst_n = 0;
     #(CYCLE*RST_TIME);
     rst_n = 1;
     #5000;
     $stop;
 end


 endmodule
 
