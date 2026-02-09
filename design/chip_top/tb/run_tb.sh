#!/bin/bash

# Matrix Multiplication Testbench Run Script
# Usage: ./run_tb.sh [size]
#   size: 8 (default), 64, 256 (requires long simulation time)

set -e

SIZE=${1:-8}
SIMULATOR=${SIMULATOR:-vcs}  # vcs, xcelium, questasim

echo "================================================"
echo " Matrix Multiplication Testbench"
echo " Matrix Size: ${SIZE}x${SIZE}"
echo " Simulator: ${SIMULATOR}"
echo "================================================"

# Create work directory
WORK_DIR="work_${SIZE}x${SIZE}"
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

# Copy source files
cd ..
cp ../rtl/*.v .
cp ../tb/tb_matrix_mult_simple.v .

# Compile and run
case ${SIMULATOR} in
    vcs)
        echo "Compiling with VCS..."
        vcs -full64 \
            -sverilog \
            -debug_access+all \
            -l compile.log \
            tb_matrix_mult_simple.v
        
        echo "Running simulation..."
        ./simv -l run.log +test_size=${SIZE}
        ;;
        
    xcelium)
        echo "Compiling with Xcelium..."
        xmvlog -sverilog -work work \
            -l xmvlog.log \
            tb_matrix_mult_simple.v
        
        echo "Elaborating..."
        xmelab -work work -l xmelab.log
        
        echo "Running simulation..."
        xmsim -work work -l xmsim.log +test_size=${SIZE}
        ;;
        
    questasim)
        echo "Compiling with Questa..."
        vlib work
        vlog -sv -work work \
            -l vlog.log \
            tb_matrix_mult_simple.v
        
        echo "Running simulation..."
        vsim -c -l vsim.log \
            -do "run -all; quit" \
            work.tb_matrix_mult_simple
        ;;
        
    *)
        echo "Unknown simulator: ${SIMULATOR}"
        echo "Supported: vcs, xcelium, questasim"
        exit 1
        ;;
esac

echo "================================================"
echo " Simulation Complete!"
echo " Check results in:"
echo "   - run.log"
echo "   - transcript"
echo "================================================"
