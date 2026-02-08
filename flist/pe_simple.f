# PE Simple Design FileList for Verdi/iverilog
# This flist contains the working simple PE core design
# ============================================
# Usage:
#   cd /home/alan/.openclaw/workspace/apache_hw
#   iverilog -f flist/pe_simple.f
#   verdi -f flist/pe_simple.f
# ============================================

# Include directories
+incdir+design/pe_core/rtl

# PE Core RTL Files (Simple Working Version)
design/pe_core/rtl/pe_top_simple.v
design/pe_core/rtl/mac_array.v
design/pe_core/rtl/activation_unit_simple.v
design/pe_core/rtl/normalization_unit_simple.v

# Testbench
design/pe_core/rtl/tb_pe_core.v
