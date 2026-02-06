# CUDA GPU指令集支持汇总

## 概述

CUDA GPU指令集是指NVIDIA GPU硬件支持的机器指令集合。这些指令被PTX (Parallel Thread Execution)中间语言编译成SASS (Shader ASSembler)机器码。不同GPU架构支持的指令集有所不同，但核心指令保持向前兼容。

## 指令分类

### 1. 算术运算指令

#### 整数运算指令
- **加法**: `add`, `add.cc`, `addc`, `addc.cc`
- **减法**: `sub`, `sub.cc`, `subc`, `subc.cc`
- **乘法**: `mul`, `mul.wide`, `mul24`, `mulhi`
- **除法**: `div`, `rem`, `mad`, `mad24`
- **位运算**: `and`, `or`, `xor`, `not`, `shr`, `shl`, `bfe`, `bfi`
- **比较**: `setp`, `set`, `slct`, `min`, `max`

#### 浮点运算指令
- **基本运算**: `add`, `sub`, `mul`, `fma`, `neg`, `abs`
- **超越函数**: `sin`, `cos`, `exp`, `log`, `sqrt`, `rsqrt`
- **比较**: `setp`, `set`, `min`, `max`, `copysign`
- **转换**: `cvt`, `ftoi`, `itof`, `ftoh`, `htof`

#### 双精度浮点指令
- `add`, `sub`, `mul`, `div`, `fma`, `sqrt`, `rsqrt`
- `sin`, `cos`, `exp`, `log`
- 类型转换指令

#### 半精度浮点指令
- `add`, `sub`, `mul`, `fma`
- 类型转换指令

### 2. 控制流指令
- **分支**: `bra`, `brx`, `brkpt`
- **循环**: `loop`, `join`
- **预测**: `pred`, `pset`, `p2r`, `r2p`

### 3. 内存访问指令
- **全局内存**: `ld.global`, `st.global`
- **共享内存**: `ld.shared`, `st.shared`
- **常量内存**: `ld.const`, `st.const`
- **纹理内存**: `tex`, `tld`, `tld4`, `tproj`
- **本地内存**: `ld.local`, `st.local`
- **参数内存**: `ld.param`

### 4. 同步指令
- **线程束同步**: `bar.sync`, `bar.arrive`, `bar.red`
- **内存栅栏**: `membar`, `atom`, `red`
- **线程组操作**: `activemask`, `match`, `ballot`

### 5. 专用单元指令

#### Tensor Core指令 (Volta+)
- `mma` (Matrix Multiply-Accumulate)
- 适用于半精度、单精度、整数矩阵运算
- 支持多种数据布局和精度组合

#### 光线追踪指令 (Turing+)
- `trace`
- `intersect`
- `report_intersection`

### 6. 特殊功能指令
- **时钟**: `mov.u64 %rd, %clock`
- **线程ID**: `mov.u32 %r, %tid`, `mov.u32 %r, %ctaid`
- **网格尺寸**: `mov.u32 %r, %nctaid`, `mov.u32 %r, %ntid`
- **屏障**: `bar.sync`, `bar.arrive`

## 架构特定指令

### Fermi架构指令
- 基础CUDA指令集
- 支持ECC内存访问
- 原子操作指令

### Kepler架构指令
- 动态并行
- 改进的原子操作
- L2缓存指令

### Maxwell架构指令
- 图像指令 (纹理采样)
- 改进的分支预测

### Pascal架构指令
- 原生16位浮点支持
- NVLink相关指令

### Volta架构指令
- Tensor Core指令 (`mma`)
- 独立线程调度支持
- 新的原子操作类型

### Turing架构指令
- RT Core指令
- 改进的半精度运算

### Ampere架构指令
- 第二代Tensor Core指令
- 稀疏矩阵运算支持
- 改进的并发性

### Ada Lovelace架构指令
- DLSS相关指令
- 改进的光追指令

### Hopper架构指令
- 第四代Tensor Core指令
- 大型模型支持指令
- 多实例GPU支持

## PTX指令与SASS映射

PTX是CUDA的虚拟ISA (Instruction Set Architecture)，提供了对不同GPU架构的抽象。实际的SASS指令根据目标架构生成：

```
PTX指令 -> 编译器 -> SASS指令
```

### 常见PTX指令示例
```
// 算术运算
add.s32 %r1, %r2, %r3;      // 32位整数加法
add.s64 %rd1, %rd2, %rd3;    // 64位整数加法
add.f32 %f1, %f2, %f3;       // 32位浮点加法
mul.f32 %f1, %f2, %f3;       // 32位浮点乘法

// 内存访问
ld.global.f32 %f1, [%rd1];    // 全局内存加载
st.global.f32 [%rd1], %f2;    // 全局内存存储
ld.shared.f32 %f1, [%r1];     // 共享内存加载

// 控制流
@p1 bra BB0;                  // 条件分支
setp.lt.s32 p1, %r1, %r2;    // 设置条件标志
```

## 性能考虑因素

### 指令级并行
- Warp内线程的指令执行并行性
- 指令调度和依赖关系
- 隐藏内存延迟的技巧

### 内存访问模式
- 合并访问模式
- 缓存利用效率
- 共享内存bank冲突

### 分支发散
- Warp内线程的分支同步
- 预测和优化策略

## 编程接口

### CUDA C/C++ -> PTX -> SASS
```
CUDA Kernel Code
     ↓ (nvcc编译)
PTX Assembly Code
     ↓ (驱动程序编译)
SASS Machine Code
```

### 内联汇编支持
CUDA允许使用PTX内联汇编：
```cpp
asm("add.cc.u32 %0, %1, %2;" : "=r"(result) : "r"(a), "r"(b));
```

## 总结

CUDA GPU指令集是NVIDIA GPU硬件功能的直接体现。从基础的算术运算到高级的Tensor Core和RT Core指令，不同的架构提供了不同的功能集合。开发者通常通过CUDA C/C++或PTX编程，而不需要直接编写SASS代码，但了解底层指令有助于性能优化和理解硬件限制。