# PE Top Complete Design FileList for Verdi/iverilog
# Generated for wave viewing and design analysis
# WARNING: Some files may have SystemVerilog compatibility issues
# ============================================
# Usage:
#   cd /home/alan/.openclaw/workspace/apache_hw
#   iverilog -g2012 -f flist/pe_top_design.f
#   verdi -f flist/pe_top_design.f
# ============================================

# Include directories
+incdir+design/pe_core/rtl
+incdir+design/utils/rtl

# PE Core RTL Files (Core Computing Units)
design/pe_core/rtl/pe_top_enhanced.v
design/pe_core/rtl/pe_core_complete.v
design/pe_core/rtl/mac_array.v
design/pe_core/rtl/activation_unit_simple.v
design/pe_core/rtl/normalization_unit_simple.v
design/pe_core/rtl/register_file.v
design/pe_core/rtl/local_cache.v

# Utility RTL Files (Clock and Sync Components)
design/utils/rtl/clock_buffer.v
design/utils/rtl/clock_divider.v
design/utils/rtl/clock_gating.v
design/utils/rtl/clock_mux.v
design/utils/rtl/clock_switch.v
design/utils/rtl/edge_detector.v
design/utils/rtl/sync_cell.v

# Testbench Files
design/pe_core/rtl/tb_pe_enhanced.v
design/pe_core/rtl/tb_pe_complete.v
