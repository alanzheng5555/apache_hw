#!/bin/bash
# VCS Regression with Coverage

TOP=/home/autumn/apache_hw
TB_DIR=$TOP/design/chip_top/tb
RTL_DIR=$TOP/design/chip_top/rtl
UCSIE_DIR=$TOP/design/ucsie/rtl

WORK_DIR=$TOP/verify/cov
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "========================================="
echo "Apache_HW VCS Regression + Coverage"
echo "========================================="

# Test 1: UCIe Simple
echo "[1/4] Compiling tb_ucie_simple..."
vcs -full64 -sverilog -debug_access+all \
    -cm line,toggle,fsm,branch \
    -cm_hier $TOP/verify/cov/cm.f \
    $TB_DIR/tb_ucie_simple.v \
    $UCSIE_DIR/ucsie_top.v \
    $UCSIE_DIR/ucsie_adapter.v \
    $UCSIE_DIR/ucsie_controller.v \
    $UCSIE_DIR/ucsie_phy.v \
    -o simv_ucie

echo "Running tb_ucie_simple..."
./simv_ucie -cm line,toggle,fsm,branch -l ucie.log

# Test 2: Matrix Mult
echo "[2/4] Compiling tb_matrix_mult_simple..."
vcs -full64 -sverilog -debug_access+all \
    -cm line,toggle,fsm,branch \
    $TB_DIR/tb_matrix_mult_simple.v \
    $UCSIE_DIR/ucsie_top.v \
    $UCSIE_DIR/ucsie_adapter.v \
    $UCSIE_DIR/ucsie_controller.v \
    $UCSIE_DIR/ucsie_phy.v \
    -o simv_matrix

echo "Running tb_matrix_mult_simple..."
./simv_matrix -cm line,toggle,fsm,branch -l matrix.log

# Merge coverage
echo "[3/4] Merging coverage..."
urg -dir $WORK_DIR/*.vdb -merge -report $WORK_DIR/coverage_report

echo "[4/4] Coverage Report:"
echo "========================"
cat $WORK_DIR/coverage_report/summary.rpt

echo ""
echo "Detailed coverage:"
ls -la $WORK_DIR/coverage_report/

echo "Done!"
