# PE Core v3 Design FileList for iverilog
# Complete version with full regression test
# ============================================
# Usage:
#   cd /home/alan/.openclaw/workspace/apache_hw
#   iverilog -g2012 -f flist/pe_core_v3.f
#   vvp a.out
# ============================================

# PE Core v3 RTL (standalone - no external dependencies)
src/pe_core/rtl/pe_core_v3.v

# Testbench
src/pe_core/tb/tb_pe_v3.v
