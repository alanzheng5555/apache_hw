# NoC Router FileList
# Usage: iverilog -g2012 -f flist/router.f

+incdir+design/noc/router/rtl

# Router modules
design/noc/router/rtl/router_top.v
design/noc/router/rtl/router_table.v
design/noc/router/rtl/traffic_monitor.v

# Testbench
design/noc/router/tb/tb_router.v
