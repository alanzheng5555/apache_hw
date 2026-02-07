#!/bin/bash
# PE Core Regression Test Suite

set -e

SRC_DIR="src/pe_core/rtl"
TB_DIR="src/pe_core/tb"
OUT_DIR="sim/reports"
BUILD_DIR="build"

mkdir -p $OUT_DIR $BUILD_DIR

echo "========================================"
echo "PE Core Regression Test Suite"
echo "========================================"

# Clean
rm -f $BUILD_DIR/*.out $OUT_DIR/*.log

# Compile
echo "Compiling PE Core RTL and Testbench..."
iverilog -g2012 -o $BUILD_DIR/pe_regression.out \
    $SRC_DIR/pe_core_complete_v2.v $TB_DIR/tb_pe_core_regression.v

# Run
echo "Running regression tests..."
vvp $BUILD_DIR/pe_regression.out | tee $OUT_DIR/regression.log

# Results
echo ""
echo "========================================"
if grep -q "SUCCESS: All tests passed!" $OUT_DIR/regression.log; then
    echo "ALL TESTS PASSED ✓"
else
    echo "SOME TESTS FAILED ✗"
fi