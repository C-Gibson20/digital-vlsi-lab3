####################################################################
##
##  Kit, memory, design settings and directories.
##  Sourced first by every flow script, which sets FLOW.
##
##  Author:   Shuanghua Liu, Sne Samal
##  Version:  2.0
##  Date:     2026-10-21
##
####################################################################

if { ![info exists FLOW] } { error "Set FLOW to logical or fusion before sourcing setup.tcl" }
if { ![info exists env(SYN_KIT_TCL)] } { error "SYN_KIT_TCL is not set. Load the PDK first." }

source $env(SYN_KIT_TCL)

####################################################################
## Design
####################################################################
# Chosen when fc_shell starts, so no script needs editing between runs:
#   fc_shell -f scripts/fusion.tcl                  memtest with the Task 1 macro
#   MEM=rtl fc_shell -f scripts/fusion.tcl          memtest with the challenge RTL SRAM
#   TOP=SRAM32X32 fc_shell -f scripts/fusion.tcl    CHALLENGE: RTL SRAM on its own
#   TOP=sram_macro fc_shell -f scripts/fusion.tcl   CHALLENGE: Task 1 macro on its own

set DESIGN   [expr {[info exists env(TOP)] ? $env(TOP) : "memtest"}]
set RTL_SRAM [expr {$DESIGN eq "SRAM32X32" ||
                    ($DESIGN eq "memtest" && [info exists env(MEM)] && $env(MEM) eq "rtl")}]

switch $DESIGN {
    memtest {
        set CLK_PORT  clk
        set RTL_FILES [list src/memtest.sv src/counter.sv src/control.sv src/PRBS.sv \
                            src/xor_array.sv src/signature_analyser.sv src/comparator.sv]
        set SDC_FILE  constraints/memtest.sdc
        if { $RTL_SRAM } {
            lappend RTL_FILES src/SRAM32X32.sv
            # Same shape as the macro version's core (226.6 x 119.0 um), so the layouts compare
            set CORE_RATIO {1.9 1}
        }
    }
    SRAM32X32 {
        set CLK_PORT  CLK
        set RTL_FILES [list src/SRAM32X32.sv]
        set SDC_FILE  constraints/sram_block.sdc
        # Same shape as the Task 1 macro (176.765 x 55.155 um), so the layouts compare
        set CORE_RATIO {3.2 1}
    }
    sram_macro {
        set CLK_PORT  CLK
        set RTL_FILES [list src/sram_macro.sv]
        set SDC_FILE  constraints/sram_block.sdc
    }
    default { error "Unknown TOP '$DESIGN'. Use memtest, SRAM32X32 or sram_macro." }
}

if { $RTL_SRAM } {
    # No macro. Keep the name, mcmm/SDF/power use it as the corner label
    set SRAM_LABEL tc
} else {
    source scripts/sram.tcl
    # The macro is a reference library like any other.
    lappend REF_LIBS $SRAM_NDM
}

# The kit is characterised at three corners, the memory at one.
set CORNER_LABELS $SRAM_LABEL

####################################################################
## Floorplan
####################################################################
# The core is sized from the macro in scripts/floorplan.tcl rather than
# from a utilization figure, because utilization counts the macro's
# area and the macro is most of the design.

set MACRO_MARGIN 25         ;# macro to core edge, um
set CELL_STRIP   40         ;# core height above the macro, um
set MACRO_HALO    5         ;# keepout around the macro, um
set CORE_OFFSET  10         ;# core to die edge, um
set CORE_UTIL    0.6        ;# RTL SRAM only: no macro to size from
if { ![info exists CORE_RATIO] } { set CORE_RATIO {1 1} }   ;# RTL SRAM only: core width to height

set RING_WIDTH   1.0        ;# core ring, um
set RING_SPACING 0.5
set RING_OFFSET  3.75

set MACRO_RING_WIDTH   0.5
set MACRO_RING_SPACING 0.3
set MACRO_RING_OFFSET  2.0

####################################################################
## Analysis
####################################################################

set DERATE_EARLY 0.95
set DERATE_LATE  1.05

set SDF_CORNER  $SRAM_LABEL
set MAX_CORES   8
set POWER_SCENARIO func_$SRAM_LABEL

####################################################################
## Directories and files
####################################################################

set WORK_DIR work
set OUT_DIR  outputs/$FLOW
set RPT_DIR  reports/$FLOW

# The two challenge blocks get their own folders, so neither overwrites memtest
if { $DESIGN ne "memtest" } {
    set OUT_DIR $OUT_DIR/$DESIGN
    set RPT_DIR $RPT_DIR/$DESIGN
}

foreach d [list $WORK_DIR $OUT_DIR $RPT_DIR] { file mkdir $d }

# A non-physical block cannot become a physical one, so the logical
# flow needs two libraries with the netlist as the handoff.
set SYN_LIB $WORK_DIR/${DESIGN}_syn.dlib
set PNR_LIB $WORK_DIR/${DESIGN}_${FLOW}.dlib

set SYNTH_V    $OUT_DIR/${DESIGN}_synth.v
set SYNTH_SDC  $OUT_DIR/${DESIGN}_synth.sdc
set LAYOUT_V   $OUT_DIR/${DESIGN}_layout.v
set LAYOUT_GDS $OUT_DIR/${DESIGN}.gds

####################################################################
## Reports
####################################################################
# One call per stage, so a stage's effect is a diff against the one
# before it.

proc lab_reports {stage {physical 1}} {
    global RPT_DIR POWER_SCENARIO

    redirect -file $RPT_DIR/${stage}_timing_max.rpt \
        {report_timing -delay_type max -max_paths 10}
    redirect -file $RPT_DIR/${stage}_timing_min.rpt \
        {report_timing -delay_type min -max_paths 10}
    redirect -file $RPT_DIR/${stage}_area.rpt  {report_area}
    redirect -file $RPT_DIR/${stage}_qor.rpt   {report_qor}
    redirect -file $RPT_DIR/${stage}_power.rpt \
        "report_power -scenarios $POWER_SCENARIO"

    if { $physical } {
        catch {redirect -file $RPT_DIR/${stage}_utilization.rpt {report_utilization}}
        catch {redirect -file $RPT_DIR/${stage}_congestion.rpt  {report_congestion}}
    }
}
