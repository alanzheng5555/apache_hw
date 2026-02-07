# Makefile for PE Core Design Verification

# Compiler
IVERILOG = iverilog -g2012
VVP = vvp

# Source directories
RTL_DIR = ../rtl
TEST_DIR = ../rtl

# RTL source files (simplified - only essential modules)
RTL_FILES = $(RTL_DIR)/pe_top_simple.v \
           $(RTL_DIR)/mac_array.v \
           $(RTL_DIR)/activation_unit_simple.v \
           $(RTL_DIR)/normalization_unit_simple.v

# Testbench files
TB_FILES = $(TEST_DIR)/tb_pe_core.v

# Targets
TB_CORE = tb_pe_core

# Default target
all: $(TB_CORE)

# Compile basic PE core testbench
$(TB_CORE): $(RTL_FILES) $(TB_FILES)
	$(IVERILOG) -o $(TB_CORE) $(RTL_FILES) $(TEST_DIR)/tb_pe_core.v

# Run basic PE core test
test_core: $(TB_CORE)
	@echo "Running basic PE core test..."
	$(VVP) $(TB_CORE)

# Run all tests
test_all: test_core

# Clean generated files
clean:
	rm -f *.vcd $(TB_CORE) *.log

# Clean waveforms only
clean_waves:
	rm -f *.vcd

# View waveforms (requires gtkwave)
view_core_wave:
	gtkwave tb_pe_core.vcd &

# Help target
help:
	@echo "PE Core Makefile Targets:"
	@echo "  all           - Compile all testbenches"
	@echo "  test_core     - Run basic PE core test"
	@echo "  test_all      - Run all tests"
	@echo "  clean         - Remove generated files"
	@echo "  clean_waves   - Remove waveform files only"
	@echo "  view_core_wave - View core test waveform"
	@echo "  help          - Show this help"

.PHONY: all clean clean_waves test_core test_all help view_core_wave
