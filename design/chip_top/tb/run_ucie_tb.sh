#!/bin/bash

# Chip Top UCIe Integration Testbench Run Script
# Usage: ./run_ucie_tb.sh

set -e

SIMULATOR=${SIMULATOR:-vcs}  # vcs, xcelium, questasim

echo "================================================"
echo " Chip Top UCIe Integration Testbench"
echo " Simulator: ${SIMULATOR}"
echo "================================================"

# Create work directory
WORK_DIR="work_ucie"
mkdir -p ${WORK_DIR}

# Source directories
DESIGN_DIR="/home/alan/.openclaw/workspace/apache_hw/design"

# Compile with all required files
case ${SIMULATOR} in
    vcs)
        echo "Compiling with VCS..."
        
        # Compile order: core -> ucsie modules -> top -> tb
        vcs -full64 \
            -sverilog \
            -debug_access+all \
            -l compile.log \
            -y ${DESIGN_DIR}/core/rtl \
            -y ${DESIGN_DIR}/ucsie/rtl \
            -y ${DESIGN_DIR}/chip_top/rtl \
            ${DESIGN_DIR}/chip_top/tb/tb_chip_top_ucie_integrated.v
        
        if [ $? -ne 0 ]; then
            echo "ERROR: Compilation failed"
            cat compile.log
            exit 1
        fi
        
        echo "Running simulation..."
        timeout 120 ./simv -l run.log || echo "Simulation completed or timeout"
        
        # Show results
        if [ -f run.log ]; then
            tail -50 run.log
        fi
        ;;
        
    xcelium)
        echo "Compiling with Xcelium..."
        xmvlog -sverilog -work work \
            -y ${DESIGN_DIR}/core/rtl \
            -y ${DESIGN_DIR}/ucsie/rtl \
            -y ${DESIGN_DIR}/chip_top/rtl \
            -l xmvlog.log \
            ${DESIGN_DIR}/chip_top/tb/tb_chip_top_ucie_integrated.v
        
        xmelab -work work -l xmelab.log
        
        echo "Running simulation..."
        xmsim -work work -l xmsim.log +nostdio
        ;;
        
    questasim)
        echo "Compiling with Questa..."
        vlib work
        vlog -sv -work work \
            -y ${DESIGN_DIR}/core/rtl \
            -y ${DESIGN_DIR}/ucsie/rtl \
            -y ${DESIGN_DIR}/chip_top/rtl \
            -l vlog.log \
            ${DESIGN_DIR}/chip_top/tb/tb_chip_top_ucie_integrated.v
        
        echo "Running simulation..."
        vsim -c -l vsim.log \
            -do "run -all; quit" \
            work.tb_chip_top_ucie_integrated
        ;;
        
    *)
        echo "Unknown simulator: ${SIMULATOR}"
        echo "Supported: vcs, xcelium, questasim"
        exit 1
        ;;
esac

echo "================================================"
echo " Done!"
echo "================================================"
