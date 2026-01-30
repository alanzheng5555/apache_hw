# Git 提交摘要 - Utils 模块开发

## 提交信息
- 提交ID: 075371b
- 提交消息: "Add utils modules: clock buffer, divider, mux, switch, gating, sync cell, edge detector with testbenches and Makefile"
- 文件变更: 19个文件新增，837行插入

## 已提交的文件

### RTL 模块 (design/utils/rtl/)
- clock_buffer.v - 时钟缓冲器
- clock_divider.v - 时钟分频器
- clock_gating.v - 时钟门控单元
- clock_mux.v - 时钟多路选择器
- clock_switch.v - 时钟切换器
- edge_detector.v - 边沿检测器
- sync_cell.v - 二级同步器

### 测试台文件 (design/utils/sim/)
- tb_clock_buffer.v - 时钟缓冲器测试台
- tb_clock_divider.v - 时钟分频器测试台
- tb_clock_gating.v - 时钟门控单元测试台
- tb_clock_mux.v - 时钟多路选择器测试台
- tb_clock_switch.v - 时钟切换器测试台
- tb_edge_detector.v - 边沿检测器测试台
- tb_sync_cell.v - 同步器测试台

### 其他文件
- Makefile - 仿真管理文件
- readme.md - 需求说明文件
- 开发总结报告.md - 开发总结报告
- 使用指南.txt - 使用指南
- .gitignore - Git 忽略规则

## .gitignore 规则
- 忽略仿真输出文件 (*.vcd, *.fst, *.log, *.out)
- 忽略编译后的二进制文件 (sim 目录中无扩展名的文件)
- 不忽略源文件 (*.v)
- 忽略操作系统临时文件

## 验证状态
- ✓ 所有开发的源文件已提交
- ✓ 所有测试台文件已提交
- ✓ Makefile 已提交
- ✓ .gitignore 正确配置，忽略生成的文件
- ✓ 生成的二进制文件和波形文件未被提交