#!/bin/bash
# PE Core Regression Test Script

echo "Running PE Core Regression Tests..."

# Create build directory if it doesn't exist
mkdir -p build

# Compile and run the regression test
if iverilog -o build/pe_regression.out src/pe_core/rtl/pe_core_v3.v src/pe_core/tb/tb_pe_v3.v; then
    echo "Compilation successful!"
    echo "Running tests..."
    vvp build/pe_regression.out
    echo "Regression test completed!"
else
    echo "Compilation failed!"
    exit 1
fi