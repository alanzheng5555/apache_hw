# Makefile for PE Core Design Verification

# Compiler
IVERILOG = iverilog
VVP = vvp

# Source directories
RTL_DIR = .
TEST_DIR = .

# RTL source files
RTL_FILES = $(RTL_DIR)/pe_top_simple.v \
           $(RTL_DIR)/mac_array.v \
           $(RTL_DIR)/activation_unit_simple.v \
           $(RTL_DIR)/normalization_unit_simple.v \
           $(RTL_DIR)/register_file.v \
           $(RTL_DIR)/local_cache.v \
           $(RTL_DIR)/pe_core_complete.v

# Testbench files
TB_FILES = $(TEST_DIR)/tb_pe_core.v \
           $(TEST_DIR)/tb_pe_complete.v

# Targets
TB_CORE = tb_pe_core
TB_COMPLETE = tb_pe_complete

# Default target
all: $(TB_CORE) $(TB_COMPLETE)

# Compile basic PE core testbench
$(TB_CORE): $(RTL_FILES) $(TB_FILES)
	$(IVERILOG) -o $(TB_CORE) $(RTL_FILES) $(TEST_DIR)/tb_pe_core.v

# Compile complete PE core testbench
$(TB_COMPLETE): $(RTL_FILES) $(TB_FILES)
	$(IVERILOG) -o $(TB_COMPLETE) $(RTL_FILES) $(TEST_DIR)/tb_pe_complete.v

# Run basic PE core test
test_core: $(TB_CORE)
	@echo "Running basic PE core test..."
	$(VVP) $(TB_CORE)

# Run complete PE core test
test_complete: $(TB_COMPLETE)
	@echo "Running complete PE core test..."
	$(VVP) $(TB_COMPLETE)

# Run all tests
test_all: test_core test_complete

# Run specific tests with waveform generation
debug_core: $(TB_CORE)
	@echo "Running PE core test with waveform..."
	$(VVP) $(TB_CORE)

debug_complete: $(TB_COMPLETE)
	@echo "Running complete PE core test with waveform..."
	$(VVP) $(TB_COMPLETE)

# Clean generated files
clean:
	rm -f *.vcd $(TB_CORE) $(TB_COMPLETE) *.log

# Clean waveforms only
clean_waves:
	rm -f *.vcd

# View waveforms (requires gtkwave)
view_core_wave:
	gtkwave tb_pe_core.vcd &

view_complete_wave:
	gtkwave tb_pe_complete.vcd &

# Help target
help:
	@echo "PE Core Makefile Targets:"
	@echo "  all           - Compile all testbenches"
	@echo "  test_core     - Run basic PE core test"
	@echo "  test_complete - Run complete PE core test"
	@echo "  test_all      - Run all tests"
	@echo "  debug_core    - Run core test with waveform"
	@echo "  debug_complete - Run complete test with waveform"
	@echo "  clean         - Remove generated files"
	@echo "  clean_waves   - Remove waveform files only"
	@echo "  view_core_wave - View core test waveform"
	@echo "  view_complete_wave - View complete test waveform"
	@echo "  help          - Show this help"

.PHONY: all clean clean_waves test_core test_complete test_all debug_core debug_complete help view_core_wave view_complete_wave