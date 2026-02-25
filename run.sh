#!/bin/bash
# Apache_HW Compiler + Simulation Makefile Alternative
# Usage: ./run.sh [clean]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ "$1" = "clean" ]; then
    echo "Cleaning..."
    rm -f compiler/compiler
    rm -f design/pe_core/rtl/simple.hex
    rm -f design/pe_core/rtl/tb_pe_compiler
    rm -f design/pe_core/rtl/*.vcd
    echo "Cleaned!"
    exit 0
fi

echo "=========================================="
echo "Apache_HW: Compiler -> Simulation"
echo "=========================================="

# Step 1: Build compiler
echo ""
echo "[1/4] Building compiler..."
cd compiler
gcc -o compiler compiler.c
cd ..

# Step 2: Generate HEX
echo ""
echo "[2/4] Generating instruction HEX..."
cd compiler
./compiler examples/simple_test.c -h ../design/pe_core/rtl/simple.hex 2>&1 | tail -6
cd ..

# Step 3: Build simulation
echo ""
echo "[3/4] Building simulation..."
cd design/pe_core/rtl
iverilog -o tb_pe_compiler mac_array.v pe_top_simple.v tb_pe_compiler.v

# Step 4: Run simulation
echo ""
echo "[4/4] Running simulation..."
echo ""
./tb_pe_compiler

echo ""
echo "=========================================="
echo "Done! Waveform: tb_pe_compiler.vcd"
echo "View: gtkwave tb_pe_compiler.vcd"
echo "=========================================="
