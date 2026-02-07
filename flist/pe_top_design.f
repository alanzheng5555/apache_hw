# PE Top Complete Design FileList for Verdi
# Generated for wave viewing and design analysis
# ============================================
# Note: Use relative paths (.) which resolves to APACHE_HW_ROOT
# To setup: source setup.sh update-flist
# To restore: source setup.sh restore-flist
# ============================================

# PE Core RTL Files (Complete Design)
+incdir+./design/pe_core/rtl
./design/pe_core/rtl/pe_top_enhanced.v
./design/pe_core/rtl/pe_core_complete.v
./design/pe_core/rtl/mac_array.v
./design/pe_core/rtl/activation_unit_simple.v
./design/pe_core/rtl/normalization_unit_simple.v
./design/pe_core/rtl/register_file.v
./design/pe_core/rtl/local_cache.v

# Utility RTL Files (Clock and Sync Components)
+incdir+./design/utils/rtl
./design/utils/rtl/clock_buffer.v
./design/utils/rtl/clock_divider.v
./design/utils/rtl/clock_gating.v
./design/utils/rtl/clock_mux.v
./design/utils/rtl/clock_switch.v
./design/utils/rtl/edge_detector.v
./design/utils/rtl/sync_cell.v

# Testbench Files
+incdir+./design/pe_core/rtl
./design/pe_core/rtl/tb_pe_enhanced.v
./design/pe_core/rtl/tb_pe_complete.v
