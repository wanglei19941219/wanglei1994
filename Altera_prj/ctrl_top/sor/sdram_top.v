`timescale 1 ns /1 ns
module sdram_top(
    //System signal
    input               s_clk                   ,
    input               s_rst_n                 ,
    //sdram signal
    output  wire        sdram_clk               ,
    output  wire        sdram_cke               ,
    output  wire        sdram_cs_n              ,
    output  reg [11:0]  sdram_addr              ,
    output  reg [ 1:0]  sdram_baddr             ,
    output  wire        sdram_ras_n             ,
    output  wire        sdram_cas_n             ,
    output  wire        sdram_we_n              ,
    output  wire[ 1:0]  sdram_dqm               ,
    inout       [15:0]  sdram_data              ,
    input               wr_tring                ,
    input               rd_tring                ,
    input       [ 7:0]  wfifo_rd_data           ,
    output  wire        wfifo_rd_en             ,
    output  wire[ 7:0]  rfifo_wr_data           ,
    output  wire        rfifo_wr_en             ,
    input               wfifo_empty 
);
/*==========================================================
* ************define parameter and internal signal**********
* =========================================================*/
//仲裁模块状态parammeter
parameter       IDLE  =  5'b00001               ;
parameter       ARB   =  5'b00010               ;
parameter       AREF  =  5'b00100               ;
parameter       WR    =  5'b01000               ;
parameter       RD    =  5'b10000               ; 
//命令parameter
parameter       NOP   =  4'b0111                ;
//init signal
wire                    flag_init_end           ;
wire      [ 3:0]        init_cmd                ;
wire      [11:0]        init_addr               ;
wire      [ 1:0]        init_bank               ;
reg       [ 3:0]        sdram_cmd               ;
//仲裁信号
reg       [ 5:0]        state                   ;
wire                    req_aref                ;
reg                     en_aref                 ;
wire                    end_aref                ;
wire                    req_wr                  ;
reg                     en_wr                   ;
wire                    wr_end                  ;
wire      [ 3:0]        wr_cmd                  ;
wire      [11:0]        wr_addr                 ;
wire      [ 1:0]        wr_bank                 ;
wire                    req_rd                  ;
reg                     en_rd                   ;
wire                    rd_end                  ;
wire      [ 3:0]        rd_cmd                  ;          
wire      [11:0]        rd_addr                 ;
wire      [ 1:0]        rd_bank                 ;



wire      [ 3:0]        aref_cmd                 ;
wire      [11:0]        aref_addr               ;
wire      [ 1:0]        aref_bank               ;
wire      [15:0]        wr_data                 ;


/*==========================================================
* ************************main code*************************
* ==========================================================*/

//arbitration
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            state <= IDLE                       ;
        end
        else case (state)
                    IDLE :
                            if(flag_init_end)
                                state <= ARB    ;
                            else 
                                state <= IDLE   ;
                    ARB  :  
                            if(en_aref)
                               
                                state <= AREF   ;
                            else if(en_wr)
                                state <= WR     ;
                            else if(en_wr)
                                state <= WR     ;
                            else if(en_rd)
                                state <= RD     ;
                            else 
                                state <= ARB    ;
                    AREF  :
                            if(end_aref)
                                state <= ARB    ;                           
                            else
                                state <= AREF   ;
                    WR    : 
                            if(wr_end)
                                state <= ARB   ;
                            else
                                state <= WR    ;
                    RD    :
                            if(rd_end)
                                state <= ARB    ;
                            else
                                state <= RD     ;
                    default  :  state <= IDLE   ;        
        endcase
end

always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            en_aref <= 1'b0                     ;           
        end
        else if(end_aref == 1'b1)begin
            en_aref <= 1'b0                     ;
        end
        else if(state == ARB && req_aref == 1'b1)begin
            en_aref <= 1'b1                     ;
        end
        else begin
            en_aref <= en_aref                  ;
        end
end 

//写使能
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            en_wr <= 1'b0                       ;
        end
        else if(state == ARB && req_aref == 1'b0 && req_wr == 1'b1)begin
            en_wr <= 1'b1                       ;
        end
        else begin
            en_wr <= 1'b0                       ;
        end
end
//读使能
always @(posedge s_clk or negedge s_rst_n)begin
        if(!s_rst_n)begin
            en_rd <= 1'b0                       ;
        end
        else if(state == ARB && req_aref == 1'b0 && req_wr == 1'b0 && req_rd == 1'b1)begin
            en_rd <= 1'b1                       ;
        end
        else begin
            en_rd <= 1'b0                       ;
        end
end
//命令地址输出
always @(*)begin
             case(state)
                    IDLE : begin
                           sdram_cmd  = init_cmd ;
                           sdram_addr = init_addr;
                           sdram_baddr= init_bank;
                           end
                    ARB  : begin
                           sdram_cmd  = NOP      ;
                           sdram_addr = 12'd0    ;
                           sdram_baddr= 2'd0     ;
                           end

                    AREF : begin
                           sdram_cmd  = aref_cmd ;
                           sdram_addr = aref_addr;
                           sdram_baddr= aref_bank;
                           end
                
                    WR   : begin
                           sdram_cmd  = wr_cmd ;
                           sdram_addr = wr_addr;
                           sdram_baddr= wr_bank;
                           end

                    RD   : begin
                           sdram_cmd  = rd_cmd ;
                           sdram_addr = rd_addr;
                           sdram_baddr= rd_bank;
                           end
                         default : begin
                                   sdram_cmd  =  NOP  ;
                                   sdram_addr =  12'd0;
                                   sdram_baddr=  2'd0 ;
                                   end
                        endcase
end




assign     sdram_cke = 1'b1                 ;
/*assign     sdram_baddr = (state==IDLE)? init_bank:aref_bank              ;
assign     sdram_addr  = (state==IDLE)? init_addr:aref_addr              ;*/
assign     sdram_data  = (state == WR)? wr_data : {16{1'bz}} ;
assign     {sdram_cs_n,sdram_ras_n, sdram_cas_n,sdram_we_n}  = sdram_cmd ;
assign     sdram_dqm   = 2'b00                  ;
assign     sdram_clk   = ~s_clk                 ;

sdram_init sdram_init_inst(
.s_clk              (s_clk  ) ,
.s_rst_n            (s_rst_n) ,
.sdram_addr         (init_addr) ,
.bank_addr          (init_bank) ,
.cmd                (init_cmd) ,
.flag_init_end      (flag_init_end) 

);

sdram_aref sdram_aref_inst(
.s_clk                   (s_clk        ),
.s_rst_n                 (s_rst_n      ),
/*.sdram_clk               (sdram_clk    ),
.sdram_cke               (sdram_cke    ),*/
.en_aref                 (en_aref      ),
.flag_init_end           (flag_init_end),
.req_aref                (req_aref     ),
.end_aref                (end_aref     ),
.aref_cmd                (aref_cmd     ),
.sdram_addr              (aref_addr    ),
.sdram_bank              (aref_bank    )

);

sdram_write sdram_write_inst( 
.s_clk                       (s_clk        ),
.s_rst_n                     (s_rst_n      ),
/*.sdram_clk                   (sdram_clk    ),
.sdram_cke                   (sdram_cke    ),*/
.en_wr                       (en_wr        ),
.req_wr                      (req_wr       ),
.wr_end                      (wr_end       ),
.req_aref                    (req_aref     ),
.wr_tring                    (wr_tring     ),
.wr_cmd                      (wr_cmd       ),
.wr_addr                     (wr_addr      ),
.wr_bank                     (wr_bank      ),
.wr_data                     (wr_data      ),
.wfifo_rd_data               (wfifo_rd_data),
.wfifo_rd_en                 (wfifo_rd_en  ),
.wfifo_empty                 (wfifo_empty  )

);
sdram_rd sdram_rd_inst(
.s_clk                       (s_clk        ),
.s_rst_n                     (s_rst_n      ),                        
/*.sdram_clk                   (sdram_clk    ),
.sdram_cke                   (sdram_cke    ),*/                        
.rd_tring                    (rd_tring     ),
.req_aref                    (req_aref     ),
.en_rd                       (en_rd        ),
.req_rd                      (req_rd       ),
.rd_end                      (rd_end       ),
.rd_cmd                      (rd_cmd       ),
.rd_addr                     (rd_addr      ),
.rd_bank                     (rd_bank      ),         
.rfifo_wr_data               (rfifo_wr_data),               
.rfifo_wr_en                 (rfifo_wr_en  ),
.sdram_data                  (sdram_data   )
);






endmodule              
