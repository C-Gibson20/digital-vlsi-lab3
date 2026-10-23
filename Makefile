####################################################################
#
#  Memory library build, simulation and waveform viewing.
#  Synthesis and layout are run in fc_shell, not from here.
#
#  Author:   Shuanghua Liu, Sne Samal
#  Version:  2.0
#  Date:     2026-10-21
#
####################################################################

DESIGN     := memtest
FLOW       ?= logical
SDF_CORNER ?= tc

OUT  := outputs/$(FLOW)
SIM  := sim
LOGS := logs
SRC  := src/$(DESIGN).sv src/counter.sv src/control.sv src/PRBS.sv # src/signature_analyser.sv src/xor_array.sv src/comparator.sv src/SRAM32X32.sv
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

# Display the header above, so the printed authors/version/date stay in sync.
define show_header
@awk 'NR == 1 { print; next } /^####/ { print; print ""; exit } { print }' "$(firstword $(MAKEFILE_LIST))"
endef

# All lab build scripts are read from this checkout's scripts/ directory.
# The installed Synopsys tools and PDK are supplied by the environment.

## sram: build the memory reference library; full output in logs/sram.log
# Run from the Lab_3 directory after loading synopsys tsmc65LP.
# Both build scripts are local. The log is replaced on each run.
# Feed an exit command to LM in case the local script leaves its prompt open.
# Count diagnostic messages, not occurrences of words in echoed Tcl/comments.
# Success also requires this run's DB-write, workspace-check and NDM-write messages.
sram:
	$(show_header)
	@mkdir -p "$(LOGS)"
	@run_log="$(LOGS)/sram.log"; \
	( \
	    set -e; \
	    printf 'SRAM build started: %s\nWorking directory: %s\n' "$$(date)" "$$(pwd)"; \
	    test -n "$$SYN_KIT_TCL" && test -r "$$SYN_KIT_TCL" || { \
	        echo "ERROR: load the environment with synopsys tsmc65LP first." >&2; exit 1; }; \
	    test -r scripts/sram.tcl || { \
	        echo "ERROR: scripts/sram.tcl is missing or unreadable. Run make from the Lab_3 directory." >&2; exit 1; }; \
	    test -r scripts/sram_lib.tcl && test -r scripts/sram_ndm.tcl || { \
	        echo "ERROR: local SRAM build scripts are missing or unreadable in scripts/." >&2; exit 1; }; \
	    command -v lc_shell >/dev/null 2>&1 || { \
	        echo "ERROR: lc_shell is not on PATH. Check the Synopsys environment." >&2; exit 1; }; \
	    command -v lm_shell >/dev/null 2>&1 || { \
	        echo "ERROR: lm_shell is not on PATH. Check the Synopsys environment." >&2; exit 1; }; \
	    printf '\n=== Library Compiler: scripts/sram_lib.tcl ===\n'; \
	    lc_shell -f scripts/sram_lib.tcl </dev/null; \
	    printf '\n=== Library Manager: scripts/sram_ndm.tcl ===\n'; \
	    printf '%s\n' 'exit 0' | lm_shell -f scripts/sram_ndm.tcl; \
	) >"$$run_log" 2>&1; \
	run_status=$$?; \
	awk -v command_status="$$run_status" -v log_file="$$run_log" ' \
	    { line = tolower($$0) } \
	    line ~ /^[[:space:]]*(\*\*[[:space:]]*)?warning[[:space:]]*:/ { warnings++ } \
	    line ~ /^[[:space:]]*(\*\*[[:space:]]*)?(error|fatal|fatal error|severe)[[:space:]]*:/ { errors++ } \
	    /^=== Library Compiler:/ { stage = "lc" } \
	    /^=== Library Manager:/ { stage = "lm" } \
	    stage == "lc" && line ~ /^[[:space:]]*wrote .*\.db.*successfully/ { db_written = 1 } \
	    stage == "lm" && line ~ /^[[:space:]]*workspace check succeeded!/ { workspace_ok = 1 } \
	    stage == "lm" && line ~ /^[[:space:]]*\.\.\. wrote .*\.ndm([[:space:]]|$$)/ { ndm_written = 1 } \
	    END { \
	        failed = (command_status != 0 || errors > 0 || !db_written || !workspace_ok || !ndm_written); \
	        if (command_status != 0) { \
	            printf "\nBUILD STATUS: command exited with status %s.\n", command_status >> log_file; \
	        } \
	        if (failed && errors == 0) { \
	            errors = 1; \
	            if (command_status != 0) \
	                print "ERROR: SRAM build process failed; inspect the preceding output." >> log_file; \
	            else \
	                print "ERROR: Build completion was not confirmed. Expected DB write, successful workspace check and NDM write messages." >> log_file; \
	        } \
	        summary = sprintf("SRAM build: %s\nWarnings: %d | Errors: %d\nLog: %s", failed ? "FAILED" : "SUCCESSFUL", warnings, errors, log_file); \
	        print summary; \
	        print "\n" summary >> log_file; \
	        close(log_file); \
	        exit (failed ? 1 : 0); \
	    }' "$$run_log"

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

# CHALLENGE: drop $(SRAM_V) from sim-rtl, sim-synth and sim-layout

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
	$(show_header)
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  make /' | \
	  awk -F': ' '{ printf "%-20s %s\n", $$1, $$2 }'
	@printf "%-20s %s\n" "    FLOW" "logical (default) or fusion"
	@printf "%-20s %s\n" "    SDF_CORNER" "corner to annotate from, default $(SDF_CORNER)"
