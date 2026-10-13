####################################################################
##
##  Kit, memory, design settings and directories.
##  Sourced first by every flow script, which sets FLOW.
##
##  Author:   Sne Samal
##  Version:  1.0
##  Date:     2026-09-04
##
####################################################################

if { ![info exists FLOW] } { error "Set FLOW to logical or fusion before sourcing setup.tcl" }
if { ![info exists env(SYN_KIT_TCL)] } { error "SYN_KIT_TCL is not set. Load the PDK first." }

source $env(SYN_KIT_TCL)
source scripts/sram.tcl

# The macro is a reference library like any other.
lappend REF_LIBS $SRAM_NDM

# The kit is characterised at three corners, the memory at one.
set CORNER_LABELS $SRAM_LABEL

####################################################################
## Design
####################################################################

set DESIGN   memtest
set CLK_PORT clk

set RTL_FILES [list src/memtest.sv src/counter.sv src/control.sv src/PRBS.sv]
set SDC_FILE  constraints/$DESIGN.sdc

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
