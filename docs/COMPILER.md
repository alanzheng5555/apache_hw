# Apache_HW 编译器设计与使用文档

## 1. 概述

Apache_HW 编译器是将高级语言（如 C 语言风格）转换为可在 PE Core 硬件上执行的二进制指令的工具。

### 1.1 编译流程

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  .c 源文件  │ -> │   编译器    │ -> │  .hex 二进制│ -> │  硬件仿真  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## 2. 指令集架构 (ISA)

### 2.1 指令格式 (32 位)

```
┌────────────────────────────────────────┐
│ 31   28 │ 27    16 │ 15     8 │ 7    0 │
├─────────┼──────────┼──────────┼────────┤
│  OPCODE │ Reserved │ Reserved │  TYPE  │
└─────────┴──────────┴──────────┴────────┘
```

| 字段 | 位宽 | 说明 |
|------|------|------|
| OPCODE | 4 | 操作码 (bits[31:28]) |
| TYPE | 8 | 类型参数 (bits[7:0]) |
| Reserved | 20 | 保留位 |

### 2.2 支持的指令

| 指令 | OPCODE | TYPE | 说明 |
|------|--------|------|------|
| MAC | 0x1 | 0x00 | 矩阵乘加运算 |
| ACT | 0x2 | 0x00-0x05 | 激活函数 |
| NORM | 0x3 | 0x00-0x02 | 归一化 |
| LOAD | 0x4 | 地址 | 内存加载 |
| STORE | 0x5 | 地址 | 内存存储 |
| MOVE | 0x6 | src,dst | 数据移动 |
| NOP | 0x7 | 0x00 | 空操作 |

### 2.3 激活函数类型 (ACT)

| 类型值 | 名称 | 说明 |
|--------|------|------|
| 0x00 | ReLU | Rectified Linear Unit |
| 0x01 | GELU | Gaussian Error Linear Unit |
| 0x02 | Sigmoid | Sigmoid 函数 |
| 0x03 | Tanh | 双曲正切 |
| 0x04 | LeakyReLU | Leaky ReLU |
| 0x05 | SiLU | Sigmoid Linear Unit |

### 2.4 归一化类型 (NORM)

| 类型值 | 名称 | 说明 |
|--------|------|------|
| 0x00 | LayerNorm | Layer Normalization |
| 0x01 | RMSNorm | RMS Normalization |
| 0x02 | GroupNorm | Group Normalization |

## 3. 编译器使用

### 3.1 编译安装

```bash
cd compiler
gcc -o compiler compiler.c
```

### 3.2 编译源代码

```bash
# 基本用法
./compiler <input.c> [-o output.bin] [-a output.asm] [-h output.hex]

# 选项说明
# -o output.bin  : 输出二进制文件
# -a output.asm  : 输出汇编文件
# -h output.hex  : 输出 HEX 文件

# 示例
./compiler examples/simple_test.c -o test.bin -a test.asm -h test.hex
```

### 3.3 源代码语法

```c
// 简单测试程序
mac();              // 矩阵乘加
act(relu);         // ReLU 激活
norm(layernorm);    // Layer 归一化
nop();              // 空操作
```

### 3.4 可用的函数

| 函数 | 说明 |
|------|------|
| `mac()` | 矩阵乘加运算 |
| `act(relu)` | ReLU 激活 |
| `act(gelu)` | GELU 激活 |
| `act(sigmoid)` | Sigmoid 激活 |
| `norm(layernorm)` | LayerNorm 归一化 |
| `norm(rmsnorm)` | RMSNorm 归一化 |
| `nop()` | 空操作 |

## 4. 仿真验证

### 4.1 快速运行

```bash
./run.sh
```

### 4.2 手动运行

```bash
# 1. 编译
cd compiler
gcc -o compiler compiler.c

# 2. 生成 HEX
./compiler examples/simple_test.c -h ../design/pe_core/rtl/simple.hex

# 3. 编译仿真
cd ../design/pe_core/rtl
iverilog -o tb_pe_compiler mac_array.v pe_top_simple.v tb_pe_compiler.v

# 4. 运行
./tb_pe_compiler
```

### 4.3 查看波形

```bash
gtkwave tb_pe_compiler.vcd
```

## 5. 输出格式

### 5.1 HEX 文件格式

每行一个 32 位十六进制数：

```
10000000
20000000
30000000
70000000
```

### 5.2 汇编输出

```
; Apache_HW Assembly Output
; Total Instructions: 4

0000: 10000000  // MAC
0001: 20000000  // ACT ReLU
0002: 30000000  // NORM LayerNorm
0003: 70000000  // NOP
```

## 6. 示例程序

### 6.1 简单推理

```c
// Transformer 推理
mac();              // 矩阵乘法
act(gelu);         // GELU 激活
norm(layernorm);    // LayerNorm
nop();
```

编译输出：
```
[0x00] OPCODE=0x1 TYPE=0x00 -> 0x10000000
[0x01] OPCODE=0x2 TYPE=0x01 -> 0x20000001
[0x02] OPCODE=0x3 TYPE=0x00 -> 0x30000000
[0x03] OPCODE=0x7 TYPE=0x00 -> 0x70000000
```

### 6.2 完整前向传播

```c
// 全连接层
mac();             // Linear 1
act(gelu);        // GELU
mac();             // Linear 2
nop();
```

## 7. 文件结构

```
compiler/
├── isa.h              # 指令集定义
├── compiler.c        # 编译器源码
├── Makefile          # 构建文件
└── examples/
    ├── simple_test.c  # 简单测试
    └── matrix_test.c  # 矩阵测试

design/pe_core/rtl/
├── tb_pe_compiler.v  # 仿真测试台
├── simple.hex        # 编译输出示例
└── ...
```

## 8. 扩展说明

### 8.1 添加新指令

1. 在 `isa.h` 中定义新的 OPCODE
2. 在编译器中添加对应的解析
3. 在硬件设计中实现对应功能

### 8.2 添加新的激活函数

1. 在 `isa.h` 中添加新的 ACT 类型
2. 扩展编译器解析
3. 在 `activation_unit` 模块中实现

## 9. 已知限制

- 当前编译器不支持变量定义
- 不支持算术表达式
- 仅支持固定顺序的指令序列

## 10. 联系方式

如有问题，请提交 Issue 或 Pull Request。
