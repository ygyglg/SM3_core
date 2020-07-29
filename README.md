# SM3_core

国密 SM3 杂凑算法的硬件 IP，RTL 采用 Verilog 开发，测试平台使用 SystemVerilog 语言。

### 算法与标准

SM3 是中国的杂凑密码算法国家标准，SM3 算法与 SHA、MD5 等算法同属于杂凑算法，又称哈希算法，散列算法等。

SM3杂凑算法是我国自主开发的密码算法，并于2016年上升为国家标准。

SM3算法采用Merkle-Damgård结构，消息分组长度512比特，摘要结果长度256比特。SM3 算法包括消息填充分组，消息扩展以及消息压缩三个步骤。

整体结构与 SHA-256 算法结构接近，但增加了多种新设计技术以提高安全性。

[SM3标准文本](http://www.gmbz.org.cn/main/viewfile/20180108023812835219.html)

### 功能

- 输入任意长度的消息
- 运算完成消息的杂凑值输出

### 特性

- 输入消息长度按字节对齐；消息长度支持标准规定的最长消息长度：(2^64-1) 比特
- 输入与内部运算位宽可为 32/64 比特 （64 bit 特性将于 v1.0 支持）
- 单个消息块运算时钟周期为 65 (32 bit) / 33 (64 bit)
- 最大吞吐(FPGA : //TODO ASIC: //TODO)

### 接口

目前采用简单接口设计，将在未来版本支持 AXI 等总线接口。

#### 输入

- 时钟与异步复位 clk ,rst_n
- 消息数据 msg_inpt_d
- 消息数据有效
- 消息数据末尾（表示当前数据为消息的最后一块） msg_inpt_lst
- 消息数据字节有效 msg_inpt_vld_byte

#### 输出

- 消息输入就绪
- 杂凑结果
- 杂凑结果输出有效

| 信号              | 方向 | 位宽  | 描述                                                   |
| ----------------- | ---- | ----- | ------------------------------------------------------ |
| clk ,rst_n        | I    | 1     | 时钟与异步复位                                         |
| msg_inpt_d        | I    | 32/64 | 消息数据                                               |
| msg_inpt_vld      | I    | 1     | 消息数据有效                                           |
| msg_inpt_lst      | I    | 1     | 消息数据末尾（表示当前数据为消息的最后一块）           |
| msg_inpt_vld_byte | I    | 4/8   | 消息数据字节有效（一般在非对齐的消息末尾标识有效字节） |
| msg_inpt_rdy      | O    | 1     | 消息输入就绪                                           |
| cmprss_otpt_res   | O    | 256   | 杂凑结果输出                                           |
| cmprss_otpt_vld   | O    | 1     | 杂凑结果输出有效                                       |

#### 波形示例

下图是一个例子，输入数据共 9 个字节，分为 3 个周期输入，其中前两个周期为完整的 32 bit 字，第三个周期输入字不对称，仅高字节有效，因此 msg_inpt_vld_byte 信号为  4'b1000。

![image-20200729185602230](/doc/example_img.png)

### 实现与测试

SM3_core 虽然最初为 FPGA 平台设计，但由于其本身不包括任何 FPGA IP 与原语，因此同样适用于 ASIC 平台。

#### 测试

SM3_core 目前提供了一个基于 Modelsim 与 Windows 10 的测试平台，以及相应的运行脚本，其中测试平台：

- 生成长度与内容随机的消息激励
- 将消息激励分别输入 C 语言参考模型（通过 DPI）与逻辑模块顶层
  - C 语言参考模型修改自 GMSSL 项目
- 判断两者输出是否一致

#### 运行测试（How to run）

运行 sim/run/run_sim.bat 脚本启动测试平台，该脚本

- 通过环境变量获取 Modelsim 路径（实际通过 License 变量：LM_LICENSE_FILE）
- 目前已经测试的 Modelsim 版本与环境：10.5 on Win10

#### 实现

- FPGA：Virtex-7 with Vivado 18.3 //TODO
- ASIC:  //TODO

### 未来演进

- 在 FPGA/ASIC 平台上对实现的性能进行分析
- 实际支持 64 位总线与内部运算位宽
- 支持更多的仿真工具，如 VCS
- 支持 AXI-stream 总线接口
- 提供更完善的文档支持



### 





