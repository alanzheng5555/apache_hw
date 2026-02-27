# VCS Simulation Makefile
# Usage: make ucie | make matrix_mult | make clean
.PHONY: all clean ucie matrix_mult

TOP = /home/autumn/apache_hw/design/chip_top
UCSIE = /home/autumn/apache_hw/design/ucsie/rtl

all: ucie

ucie:
	cd $(TOP) && vcs -full64 -sverilog -debug_access+all -l compile.log \
		tb/tb_ucie_simple.v \
		$(UCSIE)/ucsie_top.v \
		$(UCSIE)/ucsie_adapter.v \
		$(UCSIE)/ucsie_controller.v \
		$(UCSIE)/ucsie_phy.v \
		-o simv_ucie
	cd $(TOP) && ./simv_ucie +vcdpluson -l run.log

matrix_mult:
	cd $(TOP) && vcs -full64 -sverilog -debug_access+all -l compile.log \
		tb/tb_matrix_mult_simple.v \
		$(UCSIE)/ucsie_top.v \
		)/ucsie_adapter.v \
		$(UCSIE$(UCSIE)/ucsie_controller.v \
		$(UCSIE)/ucsie_phy.v \
		-o simv_matrix_mult
	cd $(TOP) && ./simv_matrix_mult +vcdpluson -l run.log

clean:
	cd $(TOP) && rm -rf simv* *.vcd *.vpd *.log *.key csrc simv.daidir
