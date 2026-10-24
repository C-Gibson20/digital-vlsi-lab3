####################################################################
##
##  Timing constraints for memtest. Read into every scenario.
##
##  Author:   Sne Samal
##  Version:  1.0
##  Date:     2026-09-04
##
####################################################################


create_clock -name clk -period 2.0 [get_ports clk]

# Jitter, and the skew the clock tree will have.
set_clock_uncertainty 0.02 [get_clocks clk]

# Edge rate assumed until the clock tree is built.
set_clock_transition 0.05 [get_clocks clk]

# Without this, max_transition checking has no value to check against.
set_max_transition 0.2 [current_design]

# 20 percent of the period budgeted at each boundary.
set_input_delay  0.4 -clock clk [get_ports {reset TEST}]
set_output_delay 0.4 -clock clk [get_ports {DATA[*] GO_NO_GO}]

set_load 0.01 [all_outputs]

# Drive strength is set in scripts/mcmm.tcl, since it names a library
# cell and cell names belong to the kit.
