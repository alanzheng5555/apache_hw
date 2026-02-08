# PE Top with Full AXI4 Interface
# ============================================
# Usage:
#   cd /home/alan/.openclaw/workspace/apache_hw
#   iverilog -g2012 -f flist/pe_top_enhanced.f
#   vvp a.out
# ============================================

+incdir+design/pe_core/rtl

# PE Top with Full AXI4 Master
design/pe_core/rtl/pe_top_enhanced.v
design/pe_core/rtl/tb_pe_top_enhanced.v
