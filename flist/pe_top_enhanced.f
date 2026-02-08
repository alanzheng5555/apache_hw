# PE Top AXI Design FileList
# ============================================
# Usage:
#   cd /home/alan/.openclaw/workspace/apache_hw
#   iverilog -g2012 -f flist/pe_top_enhanced.f
#   vvp a.out
# ============================================

# Include directories
+incdir+design/pe_core/rtl

# PE Top AXI (simplified version with MAC/Act/Norm)
design/pe_core/rtl/pe_top_enhanced.v
design/pe_core/rtl/tb_pe_top_enhanced.v
