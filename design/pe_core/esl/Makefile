# Makefile for PE Core ESL (SystemC) Model
# Compile and run SystemC simulation

# Compiler settings - C++17 required for SystemC 3.0+
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
LDFLAGS = -L/usr/lib -lsystemc -lm

# Include path
INCLUDES = -I/usr/include

# Source files
SRC = tb_pe_sc.cpp
OBJ = $(SRC:.cpp=.o)
TARGET = tb_pe_sc

# Default target
all: $(TARGET)

# Compile executable
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ $< $(LDFLAGS)

# Run simulation
run: $(TARGET)
	@echo "Running PE Core SystemC simulation..."
	@echo "========================================"
	./$(TARGET)
	@echo "========================================"

# Debug build
debug: CXXFLAGS += -g -DDEBUG
debug: $(TARGET)

# Clean
clean:
	rm -f $(OBJ) $(TARGET) *.vcd *.dat

# Help
help:
	@echo "PE Core ESL Model - Makefile Targets"
	@echo "========================================"
	@echo "  all      - Build the simulation executable"
	@echo "  run      - Build and run simulation"
	@echo "  debug    - Build with debug symbols"
	@echo "  clean    - Remove generated files"
	@echo "  help     - Show this help"
	@echo "========================================"

.PHONY: all run debug clean help
