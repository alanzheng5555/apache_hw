#!/bin/bash
# UVM Regression Script

UVM_HOME=/home/autumn/uvm
DUT_DIR=/home/autumn/apache_hw/design
VERIFY_DIR=/home/autumn/apache_hw/verify

echo "========================================="
echo "Apache_HW UVM Regression"
echo "========================================="

# Check UVM
if [ ! -d "$UVM_HOME" ]; then
    echo "Downloading UVM..."
    cd /home/autumn
    git clone https://github.com/accellera-official/uvm.git uvm
fi

# Compile command
COMPILE_CMD="vcs -full64 -sverilog \\
    -debug_access+all \\
    +incdir+$UVM_HOME/src \\
    +incdir+$VERIFY_DIR/tb \\
    +incdir+$VERIFY_DIR/tb/uvm_components \\
    +incdir+$DUT_DIR/pe_core/rtl \\
    +incdir+$DUT_DIR/ucsie/rtl \\
    +incdir+$DUT_DIR/chip_top/rtl \\
    $VERIFY_DIR/tb/tb_top.sv \\
    $VERIFY_DIR/tb/tests.sv \\
    $VERIFY_DIR/tb/uvm_components/*.sv \\
    $VERIFY_DIR/seq/*.sv \\
    $DUT_DIR/pe_core/rtl/*.v \\
    $DUT_DIR/ucsie/rtl/*.v \\
    $DUT_DIR/chip_top/rtl/*.v \\
    -o simv_uvm \\
    -cm line,toggle,fsm,branch \\
    -l compile.log"

echo "Compiling..."
eval $COMPILE_CMD

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Running simulation..."
./simv_uvm -cm line,toggle,fsm,branch -l run.log

echo "========================================="
echo "Coverage Report"
echo "========================================="
urg -dir simv_uvm.vdb -format text -report coverage_report

echo "Done!"
