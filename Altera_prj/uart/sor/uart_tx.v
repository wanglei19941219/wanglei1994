module uart_tx(
    input                        s_clk                    ,//50M系统时钟
    input                        s_rst_n                  ,//系统复位
    input        [ 7: 0]         rfifo_rd_data            ,//数据输入
    input                        rfifo_empty              ,
    output reg                   data_tx                  ,//并转串数据输出
    output reg                   end_flag                 ,//信号输出完成信号标志
    output reg                   rfifo_rd_en                
);
parameter        BAND_TIME      =      5207               ;//一波特时钟数

           reg   [ 7: 0]         shift_data               ;//移位寄存器
           reg   [12: 0]         band_cnt                 ;//波特计数器
           reg   [ 3: 0]         bit_cnt                  ;//数据位数计数器
           reg                   data_tx_flag             ;//数据tx标志信号
           reg   [ 7: 0]         data_in_1                ;//输入数据打一拍
           reg   [ 7: 0]         data_in_2                ;//输入数据打两拍
           reg   [ 7: 0]         data_in_3                ;//输入数据打三拍
           reg                   band_flag                ;
           reg                   tx_flag                  ;
//rfifo_rd_en
always @(posedge s_clk negedge s_rst_n)begin
        if(!s_rst_n)begin
            rfifo_rd_en <= 1'b0              ;
        end
        else if(rfifo_empty == 1'b0 && tx_flag == 1'b0)begin
            rfifo_rd_en <= 1'b1              ;
        end
        else begin
            rfifo_rd_en <= 1'b0              ;
        end
end
//tx_flag
always @(posedge s_clk or s_rst_n)begin
        if(!s_rst_n)begin
            tx_flag <= 1'b0                 ;
        end
        else begin
            tx_flag <= rfifo_rd_en          ;
        end
end
//波特计数器
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            band_cnt <= 13'd0                             ;
        end
        else if(band_cnt == BAND_TIME||data_tx_flag == 1'b0)begin
            band_cnt <= 13'd0                             ;
        end
        else begin
            band_cnt <= band_cnt + 1'b1                   ; 
        end

end

//比特计数器
always @(posedge s_clk or negedge s_rst_n )begin
        if(!s_rst_n)begin
            bit_cnt <= 4'd0                               ;
        end
        else if(bit_cnt == 4'd8 && band_cnt == BAND_TIME || data_tx_flag == 1'b0 )begin
            bit_cnt <= 4'd0                               ;
        end
        else if(band_cnt == BAND_TIME )begin
            bit_cnt <= bit_cnt + 1'b1                     ;
        end
        else begin
            bit_cnt <= bit_cnt                            ; 
        end
end
//波特标志信号
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            band_flag <= 1'b0                             ;
        end
        else if(band_cnt == BAND_TIME)begin
            band_flag <= 1'b1                             ;
        end
        else begin
            band_flag <=1'b0                              ;
        end
end

//数据tx标志信号
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            data_tx_flag <= 1'b0                          ;
        end
        else if(bit_cnt == 4'd8 && band_cnt == BAND_TIME )begin
            data_tx_flag <= 1'b0                          ;
        end
        else if(tx_flag == 1'b1)begin
            data_tx_flag <= 1'b1                          ;
        end
        else begin
            data_tx_flag <= data_tx_flag                  ;
        end
end

//数据打拍
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            data_in_1 <= 8'd0                             ;
        end
        else begin
            data_in_1 <= rfifo_rd_data                    ;
        end
end

always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            data_in_2 <= 8'd0                             ;
        end
        else begin
            data_in_2 <= data_in_1                        ;
        end
end
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            data_in_3 <= 8'd0                             ;
        end
        else begin
            data_in_3 <= data_in_2                        ;
        end
end


//tx结束标志信号
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            end_flag <= 1'b0                              ; 
        end
        else if(bit_cnt == 4'd8 && band_flag == 1'b1)begin
            end_flag <= 1'b1                              ; 
        end
        else begin
            end_flag <= 1'b0                              ;
        end
end

//并转串数据输出
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            shift_data <= 8'd0                            ;
        end
        else if(bit_cnt == 4'd0)begin
            shift_data <= data_in_3                       ; 
        end
        else if(band_cnt == BAND_TIME && bit_cnt >= 4'd1)begin
            shift_data <= {shift_data[0],shift_data[7:1]} ;
        end
        else begin
            shift_data <= shift_data                      ;
        end
end
//数据串行输出
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            data_tx <= 1'b0                               ;
        end
        else if(band_flag == 1'b1 && bit_cnt >= 4'd1)begin
            data_tx <= shift_data[0]                      ;
        end
        else begin
            data_tx <= data_tx                            ;
        end
end


endmodule
