# Makefile for Utils Module Simulation

# Compiler
IVERILOG = iverilog
VVP = vvp

# Source directories
RTL_DIR = ../rtl
SIM_DIR = .

# All source files
RTL_FILES = $(RTL_DIR)/clock_buffer.v \
            $(RTL_DIR)/clock_divider.v \
            $(RTL_DIR)/clock_mux.v \
            $(RTL_DIR)/clock_switch.v \
            $(RTL_DIR)/clock_gating.v \
            $(RTL_DIR)/sync_cell.v \
            $(RTL_DIR)/edge_detector.v

# Testbench files
TB_FILES = $(SIM_DIR)/tb_clock_buffer.v \
           $(SIM_DIR)/tb_clock_divider.v \
           $(SIM_DIR)/tb_clock_mux.v \
           $(SIM_DIR)/tb_clock_switch.v \
           $(SIM_DIR)/tb_clock_gating.v \
           $(SIM_DIR)/tb_sync_cell.v \
           $(SIM_DIR)/tb_edge_detector.v

# Targets
TARGETS = tb_clock_buffer \
          tb_clock_divider \
          tb_clock_mux \
          tb_clock_switch \
          tb_clock_gating \
          tb_sync_cell \
          tb_edge_detector

# Default target
all: $(TARGETS)

# Individual testbench compilation
tb_clock_buffer: $(RTL_DIR)/clock_buffer.v $(SIM_DIR)/tb_clock_buffer.v
	$(IVERILOG) -o $@ $^

tb_clock_divider: $(RTL_DIR)/clock_divider.v $(SIM_DIR)/tb_clock_divider.v
	$(IVERILOG) -o $@ $^

tb_clock_mux: $(RTL_DIR)/clock_mux.v $(SIM_DIR)/tb_clock_mux.v
	$(IVERILOG) -o $@ $^

tb_clock_switch: $(RTL_DIR)/clock_switch.v $(SIM_DIR)/tb_clock_switch.v
	$(IVERILOG) -o $@ $^

tb_clock_gating: $(RTL_DIR)/clock_gating.v $(SIM_DIR)/tb_clock_gating.v
	$(IVERILOG) -o $@ $^

tb_sync_cell: $(RTL_DIR)/sync_cell.v $(SIM_DIR)/tb_sync_cell.v
	$(IVERILOG) -o $@ $^

tb_edge_detector: $(RTL_DIR)/edge_detector.v $(SIM_DIR)/tb_edge_detector.v
	$(IVERILOG) -o $@ $^

# Run individual simulations
simulate_%: tb_%
	@echo "Running simulation for $*..."
	$(VVP) $<
	@echo "Simulation for $* completed."

# Run all simulations
simulate_all: $(TARGETS)
	@for target in $(TARGETS); do \
		echo "Running simulation for $$target..."; \
		$(VVP) $$target; \
	done

# Run specific simulations
simulate_clock_buffer: simulate_tb_clock_buffer
simulate_clock_divider: simulate_tb_clock_divider
simulate_clock_mux: simulate_tb_clock_mux
simulate_clock_switch: simulate_tb_clock_switch
simulate_clock_gating: simulate_tb_clock_gating
simulate_sync_cell: simulate_tb_sync_cell
simulate_edge_detector: simulate_tb_edge_detector

# Clean up generated files
clean:
	rm -f *.vcd tb_* a.out

# Clean waveforms only
clean_waves:
	rm -f *.vcd

# Help target
help:
	@echo "Available targets:"
	@echo "  all                   - Compile all testbenches"
	@echo "  simulate_all          - Run all simulations"
	@echo "  simulate_<module>     - Run simulation for specific module"
	@echo "  clean                 - Remove compiled files and waveforms"
	@echo "  clean_waves           - Remove only waveform files"
	@echo ""
	@echo "Supported modules:"
	@echo "  clock_buffer, clock_divider, clock_mux, clock_switch"
	@echo "  clock_gating, sync_cell, edge_detector"

.PHONY: all clean clean_waves help $(TARGETS)