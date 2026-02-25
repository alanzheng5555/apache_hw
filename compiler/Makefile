# Apache_HW Compiler Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -g
TARGET = compiler
SRCS = compiler.c
OBJS = $(SRCS:.c=.o)

.PHONY: all clean test examples

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET) *.o *.bin *.asm *.hex

test: $(TARGET)
	@echo "========================================"
	@echo "Running Compiler Tests"
	@echo "========================================"
	@echo ""
	@echo "Test 1: Matrix multiply + ReLU"
	./$(TARGET) examples/matrix_test.c -o test.bin -a test.asm -h test.hex
	@echo ""
	@echo "Generated files:"
	@ls -la test.* 2>/dev/null || echo "(no files generated)"
	@echo ""
	@echo "Assembly output (test.asm):"
	@cat test.asm 2>/dev/null || echo "(no assembly)"
	@echo ""
	@echo "========================================"

examples:
	@echo "Example programs available:"
	@ls -la examples/

# Build example with specific output
build-example:
	./$(TARGET) examples/matrix_test.c -o matrix.bin -a matrix.asm

# Default target for quick testing
run: $(TARGET)
	./$(TARGET) examples/matrix_test.c
