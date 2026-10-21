####################################################################
##
##  Mode, corner and scenario, and the SDC read into them.
##  Sourced once the block exists; the caller sets PHYSICAL first.
##
##  Author:   Shuanghua Liu, Sne Samal
##  Version:  2.0
##  Date:     2026-10-21
##
####################################################################

if { ![info exists PHYSICAL] } { error "Set PHYSICAL to 1 or 0 before sourcing mcmm.tcl" }

set CORNER $SRAM_LABEL

catch {remove_scenarios -all}
catch {remove_corners   -all}
catch {remove_modes     -all}

if { $PHYSICAL } {
    read_parasitic_tech -tlup $TLUPLUS_TYP -name rctyp
}

create_mode func
current_mode func

create_corner $CORNER
current_corner $CORNER

set_process_label $CORNER
set_temperature   $CORNER_TEMP($CORNER)
set_voltage $CORNER_VOLTAGE($CORNER) -object_list $PWR_NET
set_voltage 0.0                      -object_list $GND_NET

if { $PHYSICAL } {
    set_parasitic_parameters -late_spec rctyp -early_spec rctyp
}

create_scenario -name func_$CORNER -mode func -corner $CORNER
current_scenario func_$CORNER

read_sdc $SDC_FILE

# Every input except the clock, whose edge rate the SDC sets.
set_driving_cell -lib_cell $DRIVE_CELL \
    [get_ports * -filter "direction == in && name != $CLK_PORT"]

# A corner fixes one process, voltage and temperature for the whole
# die. Derating lets paths differ from each other within it.
set_timing_derate -early $DERATE_EARLY -cell_delay -net_delay
set_timing_derate -late  $DERATE_LATE  -cell_delay -net_delay

set_scenario_status func_$CORNER -active true \
    -setup true -hold true \
    -max_transition true -max_capacitance true \
    -leakage_power true  -dynamic_power true

# read_sdc reports an error and carries on, so a scenario can end up
# with no clock and then report no violations.
if { [sizeof_collection [all_clocks]] == 0 } {
    error "No clock after reading $SDC_FILE. Look for 'Errors reading SDC file' above."
}
