`timescale 1ns / 1ps
`include "sm3_cfg.v"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/26 
// Design Name: sm3
// Module Name: tb_sm3_cmprss_top
// Description:
//      SM3 填充-扩展-迭代压缩模块 testbench
//          测试 sm3_cmprss_core 
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Pass two SM3 example (32bit)
// Revision 0.03 - Pass two SM3 example (64bit)
//////////////////////////////////////////////////////////////////////////////////
module tb_sm3_cmprss_top (                 
);

`ifdef SM3_INPT_DW_32
    localparam [1:0]            INPT_WORD_NUM               =   2'd1;
    localparam [31:0]           DATA_INIT_PTTRN             =   32'h01020304;
`elsif SM3_INPT_DW_64
    localparam [1:0]            INPT_WORD_NUM               =   2'd2;
    localparam [63:0]           DATA_INIT_PTTRN             =   64'h0102030401020304;
`endif

//golden pattern
bit [31:0]  gldn_pttrn[15:0];

bit [60:0]  sm3_inpt_byte_num;

//interface
sm3_if sm3if();

//sm3_pad with bus wrapper
sm3_pad_core_wrapper U_sm3_pad_core_wrapper(
    sm3if
);

//sm3_expand with bus wrapper
sm3_expnd_core_wrapper U_sm3_expnd_core_wrapper(
    sm3if
);

//sm3_cmprss with bus wrapper
sm3_cmprss_core_wrapper U_sm3_cmprss_core_wrapper(
    sm3if
);

//pad monitor
sm3_pad_mntr U_sm3_pad_mntr(
    sm3if,
    gldn_pttrn
);

initial begin
    sm3if.clk                     = 0;
    sm3if.rst_n                   = 0;
    sm3if.msg_inpt_d            = DATA_INIT_PTTRN;
    sm3if.msg_inpt_vld_byte     = 0;
    sm3if.msg_inpt_vld          = 0;
    sm3if.msg_inpt_lst          = 0;
    // sm3if.pad_otpt_ena          = 1;//填充模块使能由扩展模块给出

    #100;
    sm3if.rst_n                   =1;

    repeat (1) begin
        //complete random
        //sm3_inpt_byte_num = $urandom % (61'h1fff_ffff_ffff_ffff) + 1;
        //medium random
        // sm3_inpt_byte_num = $urandom % (64*100) + 1;

        @(posedge sm3if.clk);
        task_pad_inpt_gntr_exmpl1_64();
        @(posedge sm3if.clk);
    end
    

end

always #5 sm3if.clk = ~sm3if.clk; 

//产生填充模块输入
task automatic task_pad_inpt_gntr(
    input bit [60:0] byte_num
    );

    bit [2:0]   unalign_byte_num;
    bit [55:0]  data_inpt_clk_num;

    //根据总线位宽计算数据输入时钟数与非对齐的数据数量
    `ifdef SM3_INPT_DW_32
        unalign_byte_num    =   byte_num[1:0];
        data_inpt_clk_num   =   unalign_byte_num == 0 ? byte_num[60:2] : byte_num[60:2] + 1'b1;
    `elsif SM3_INPT_DW_64
        unalign_byte_num    =   byte_num[2:0];
        data_inpt_clk_num   =   unalign_byte_num == 0 ? byte_num[60:3] : byte_num[60:3] + 1'b1;
    `endif


    //前 N-1 个周期的数据
    sm3if.msg_inpt_vld = 1'b1;
    repeat(data_inpt_clk_num - 1'b1)begin
        @(posedge sm3if.clk);   
    end
    sm3if.msg_inpt_lst    = 1'b1;

    //准备最后一个周期的数据
    `ifdef SM3_INPT_DW_32
        lst_data_gntr_32(sm3if.msg_inpt_d,sm3if.msg_inpt_vld_byte,unalign_byte_num);
    `elsif SM3_INPT_DW_64
        lst_data_gntr_64(sm3if.msg_inpt_d,sm3if.msg_inpt_vld_byte,unalign_byte_num);
    `endif
    
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld    = 1'b0;
    sm3if.msg_inpt_lst    = 1'b0;
    sm3if.msg_inpt_d      = DATA_INIT_PTTRN;
    
endtask //automatic

//产生填充模块输入，采用示例输入 'abc'
task automatic task_pad_inpt_gntr_exmpl0_32();

    
    sm3if.msg_inpt_vld      = 1'b1;
    sm3if.msg_inpt_lst      = 1'b1;
    sm3if.msg_inpt_d        = 32'h6162_6300;
    sm3if.msg_inpt_vld_byte = 4'b1110;
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld    = 1'b0;
    sm3if.msg_inpt_lst    = 1'b0;
    sm3if.msg_inpt_d      = DATA_INIT_PTTRN;
    
endtask //automatic

//产生填充模块输入，采用示例输入 'abc'
task automatic task_pad_inpt_gntr_exmpl0_64();

    
    sm3if.msg_inpt_vld      = 1'b1;
    sm3if.msg_inpt_lst      = 1'b1;
    sm3if.msg_inpt_d        = 64'h6162_6300_0000_0000;
    sm3if.msg_inpt_vld_byte = 8'b1110_0000;
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld    = 1'b0;
    sm3if.msg_inpt_lst    = 1'b0;
    sm3if.msg_inpt_d      = DATA_INIT_PTTRN;
    
endtask //automatic

//产生填充模块输入，采用示例输入 512bit 重复的 'abcd'
task automatic task_pad_inpt_gntr_exmpl1_32();

    sm3if.msg_inpt_vld      = 1'b1;
    sm3if.msg_inpt_d        = 32'h6162_6364;
    sm3if.msg_inpt_vld_byte = 4'b1111;
    repeat(15)begin
        @(posedge sm3if.clk);   
    end
    sm3if.msg_inpt_lst      = 1'b1;
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld    = 1'b0;
    sm3if.msg_inpt_lst    = 1'b0;
    sm3if.msg_inpt_d      = DATA_INIT_PTTRN;
    
endtask //automatic
    
//产生填充模块输入，采用示例输入 512bit 重复的 'abcd'
task automatic task_pad_inpt_gntr_exmpl1_64();

    sm3if.msg_inpt_vld      = 1'b1;
    sm3if.msg_inpt_d        = 64'h6162_6364_6162_6364;
    sm3if.msg_inpt_vld_byte = 8'b1111_1111;
    repeat(7)begin
        @(posedge sm3if.clk);   
    end
    sm3if.msg_inpt_lst      = 1'b1;
    @(posedge sm3if.clk);   
    sm3if.msg_inpt_vld    = 1'b0;
    sm3if.msg_inpt_lst    = 1'b0;
    sm3if.msg_inpt_d      = DATA_INIT_PTTRN;
    
endtask //automatic

//32bit 生成最后一个周期数据
`ifdef SM3_INPT_DW_32
function automatic void lst_data_gntr_32(
    ref logic [31:0]  lst_data, 
    ref logic [ 3:0]  lst_vld_byte,
    input bit [2:0]   unalign_byte_num
    );
        lst_vld_byte                =   unalign_byte_num == 2'd0 ? 4'b1111
                                    :   unalign_byte_num == 2'd1 ? 4'b1000
                                    :   unalign_byte_num == 2'd2 ? 4'b1100
                                    :   unalign_byte_num == 2'd3 ? 4'b1110
                                    :   4'b1111;
        lst_data                    =   unalign_byte_num == 2'd0 ? {DATA_INIT_PTTRN}
                                    :   unalign_byte_num == 2'd1 ? {DATA_INIT_PTTRN[31-: 8], 24'd0}
                                    :   unalign_byte_num == 2'd2 ? {DATA_INIT_PTTRN[31-:16], 16'd0}
                                    :   unalign_byte_num == 2'd3 ? {DATA_INIT_PTTRN[31-:24],  8'd0}
                                    :   DATA_INIT_PTTRN;
    
endfunction
`elsif SM3_INPT_DW_64
//64bit 生成最后一个周期数据
function automatic void lst_data_gntr_64(
    ref logic [63:0]  lst_data, 
    ref logic [ 7:0]  lst_vld_byte,
    input bit [3:0]   unalign_byte_num
    );
        lst_vld_byte =                  unalign_byte_num == 3'd0 ? 8'b1111_1111
                                    :   unalign_byte_num == 3'd1 ? 8'b1000_0000
                                    :   unalign_byte_num == 3'd2 ? 8'b1100_0000
                                    :   unalign_byte_num == 3'd3 ? 8'b1110_0000
                                    :   unalign_byte_num == 3'd4 ? 8'b1111_0000
                                    :   unalign_byte_num == 3'd5 ? 8'b1111_1000
                                    :   unalign_byte_num == 3'd6 ? 8'b1111_1100
                                    :   unalign_byte_num == 3'd7 ? 8'b1111_1110
                                    :   8'b1111_1111;
        lst_data =                      unalign_byte_num == 3'd0 ? {DATA_INIT_PTTRN}
                                    :   unalign_byte_num == 3'd1 ? {DATA_INIT_PTTRN[63-: 8], 56'd0}
                                    :   unalign_byte_num == 3'd2 ? {DATA_INIT_PTTRN[63-:16], 48'd0}
                                    :   unalign_byte_num == 3'd3 ? {DATA_INIT_PTTRN[63-:24], 40'd0}
                                    :   unalign_byte_num == 3'd4 ? {DATA_INIT_PTTRN[63-:32], 32'd0}
                                    :   unalign_byte_num == 3'd5 ? {DATA_INIT_PTTRN[63-:40], 24'd0}
                                    :   unalign_byte_num == 3'd6 ? {DATA_INIT_PTTRN[63-:48], 16'd0}
                                    :   unalign_byte_num == 3'd7 ? {DATA_INIT_PTTRN[63-:56],  8'd0}
                                    :   DATA_INIT_PTTRN;
    
endfunction
`endif
endmodule