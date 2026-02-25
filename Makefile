# Apache_HW Compiler + Simulation Makefile
# 
# Usage: 
#   make          - 编译 + 仿真完整流程
#   make compile  - 仅编译
#   make sim      - 仅仿真
#   make wave     - 查看波形
#   make clean    - 清理

# Paths
COMPILER_DIR = $(PWD)/compiler
RTL_DIR = $(PWD)/design/pe_core/rtl

# Files
COMPILER_SRC = $(COMPILER_DIR)/compiler.c
COMPILER_BIN = $(COMPILER_DIR)/compiler
HEX_FILE = $(RTL_DIR)/simple.hex
TB_SOURCES = $(RTL_DIR)/tb_pe_compiler.v $(RTL_DIR)/pe_top_simple.v $(RTL_DIR)/mac_array.v
TB_BIN = $(RTL_DIR)/tb_pe_compiler
WAVE_FILE = $(RTL_DIR)/tb_pe_compiler.vcd

# Default target
all: compile sim

# Step 1: Build compiler
compile:
	@echo "=========================================="
	@echo "Building Apache_HW Compiler"
	@echo "=========================================="
	cd $(COMPILER_DIR) && gcc -o compiler compiler.c
	@echo "Done!"

# Step 2: Generate HEX from source
hex: compile
	@echo ""
	@echo "Generating instruction HEX..."
	cd $(COMPILER_DIR) && ./compiler examples/simple_test.c -h $(HEX_FILE) 2>&1 | tail -8

# Step 3: Build simulation
sim: hex
	@echo ""
	@echo "=========================================="
	@echo "Building Simulation"
	@echo "=========================================="
	cd $(RTL_DIR) && iverilog -o tb_pe_compiler $(TB_SOURCES)
	@echo "Done!"

# Step 4: Run simulation
run: sim
	@echo ""
	@echo "=========================================="
	@echo "Running Simulation"
	@echo "=========================================="
	cd $(RTL_DIR) && ./tb_pe_compiler
	@echo ""
	@echo "=========================================="
	@echo "Waveform: $(WAVE_FILE)"
	@echo "View with: make wave"
	@echo "=========================================="

# View waveform
wave:
	@if [ -f $(WAVE_FILE) ]; then \
		gtkwave $(WAVE_FILE); \
	else \
		echo "No waveform file found. Run 'make' first."; \
	fi

# Clean build files
clean:
	rm -f $(RTL_DIR)/tb_pe_compiler
	rm -f $(RTL_DIR)/tb_pe_compiler.vcd
	rm -f $(RTL_DIR)/*.vcd
	rm -f $(COMPILER_DIR)/compiler
	rm -f $(HEX_FILE)
	rm -f $(RTL_DIR)/simple.hex

.PHONY: all compile hex sim run wave clean
