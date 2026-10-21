####################################################################
##
##  Build the memory's NDM reference library from its LEF
##  and the database sram_lib.tcl wrote.
##
##  Author:   Shuanghua Liu, Sne Samal
##  Version:  2.0
##  Date:     2026-10-21
##
##      lm_shell -f scripts/sram_ndm.tcl
##
####################################################################

source $env(SYN_KIT_TCL)
source scripts/sram.tcl

file mkdir [file dirname $SRAM_NDM]

# The vendor Liberty does not declare related_power_pin on every pin,
# and the bus delimiters have to match the Verilog and SDC.
set_app_options -as_user_default \
    -name lib.workspace.allow_missing_related_pg_pins -value true
set_app_options -as_user_default -name design.bus_delimiters -value {[]}


create_workspace $SRAM_CELL \
    -technology   $TECH_FILE \
    -flow         normal \
    -scale_factor $SCALE_FACTOR

read_lef $SRAM_LEF
read_db  $SRAM_DB -process_label $SRAM_LABEL

process_workspaces -force -directory [file dirname $SRAM_NDM] \
    -output [file tail $SRAM_NDM]

remove_workspace
