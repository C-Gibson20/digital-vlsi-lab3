####################################################################
#
#  Memory library build, simulation and waveform viewing.
#  Synthesis and layout are run in fc_shell, not from here.
#
#  Author:   Sne Samal
#  Version:  1.0
#  Date:     2026-09-04
#
####################################################################

DESIGN     := memtest
FLOW       ?= logical
SDF_CORNER ?= tc

OUT  := outputs/$(FLOW)
SIM  := sim
LOGS := logs
SRC  := src/$(DESIGN).sv src/counter.sv src/control.sv src/PRBS.sv
TB   := src/$(DESIGN)_tb.sv

# The memory's own Verilog model, needed by every simulation including
# gate level: a hard macro is never in the netlist.
SRAM_DIR    := ts1n65lpll32x32m4_220a
SRAM_CORNER := tt1p2v25c
SRAM_V      := $(SRAM_DIR)/VERILOG/$(SRAM_DIR)_$(SRAM_CORNER).v

# -full64        the 32-bit binary is broken on this server
# -timescale=    the netlist declares none and VCS rejects a mix
# +neg_tchk      honour negative setup and hold from the library
# +error+30      the default of 10 hides whole categories of failure
# -kdb           lets Verdi show source and schematic, not just waves
VCS := vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb \
       +neg_tchk +error+30

.DEFAULT_GOAL := help
.PHONY: sram sim-rtl sim-synth sim-layout waves waves-verdi clean help

## sram: build the memory reference library
sram:
	lc_shell -f scripts/sram_lib.tcl
	lm_shell -f scripts/sram_ndm.tcl

# The testbench dumps to waveform.vcd in the current directory, so each
# simulation's output is moved aside and kept under its own tag.
define run_sim
	mkdir -p $(SIM) $(LOGS)
	rm -f waveform.vcd
	$(1) -o $(SIM)/simv_$(2) -Mdir=$(SIM)/csrc_$(2) -l $(LOGS)/vcs_$(2).log
	./$(SIM)/simv_$(2) -l $(LOGS)/sim_$(2).log
	test -f waveform.vcd && mv -f waveform.vcd $(SIM)/$(2).vcd || true
endef

## sim-rtl: simulate the RTL, before synthesis has touched it
sim-rtl:
	$(call run_sim,$(VCS) $(SRC) $(SRAM_V) $(TB),rtl)

## sim-synth: simulate the synthesised netlist, real cells, no wire delay
sim-synth:
	$(call run_sim,$(VCS) $$SYN_SIM_MODELS $(SRAM_V) $(OUT)/$(DESIGN)_synth.v $(TB),synth)

## sim-layout: simulate the routed layout with SDF back-annotation
sim-layout:
	$(call run_sim,$(VCS) +sdfverbose $$SYN_SIM_MODELS $(SRAM_V) \
	    $(OUT)/$(DESIGN)_layout.v $(TB) \
	    -sdf typ:$(DESIGN)_tb.dut:$(OUT)/$(DESIGN)_$(SDF_CORNER).sdf,layout_$(FLOW))

####################################################################
# Waveforms
####################################################################

KIND ?= layout_$(FLOW)

## waves: view waveforms in GTKWave (KIND=rtl, synth or layout_<flow>)
waves:
	gtkwave $(SIM)/$(KIND).vcd

# Verdi reads its own FSDB format, so the VCD is converted once.
$(SIM)/%.fsdb: $(SIM)/%.vcd
	vcd2fsdb $< -o $@

## waves-verdi: the same waveforms in Verdi, which also shows the design
# -dbdir is the database VCS wrote next to simv. Without it Verdi shows
# waveforms and nothing to relate them to.
waves-verdi: $(SIM)/$(KIND).fsdb
	verdi -nologo -ssf $(SIM)/$(KIND).fsdb \
	  $$(test -d $(SIM)/simv_$(KIND).daidir/kdb && echo "-dbdir $(SIM)/simv_$(KIND).daidir/kdb")

## clean: remove everything the flow and the simulator generated
# The memory is not touched.
clean:
	rm -rf work outputs reports logs sim
	rm -rf *.svf fc_command.log fc_output.txt HDL_LIBRARIES over_utilization_*.tcl*
	rm -rf csrc simv simv.daidir ucli.key *.vcd *.fsdb
	rm -rf verdiLog novas* .inter.vpd DVEfiles
	rm -rf lc_shell_command.log lc_output.txt default.svf

## help: list the targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  make /' | \
	  awk -F': ' '{ printf "%-20s %s\n", $$1, $$2 }'
	@printf "%-20s %s\n" "    FLOW" "logical (default) or fusion"
	@printf "%-20s %s\n" "    SDF_CORNER" "corner to annotate from, default $(SDF_CORNER)"
