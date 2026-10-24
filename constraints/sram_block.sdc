####################################################################
##
##  Timing constraints for the challenge comparison: the RTL SRAM
##  (SRAM32X32) and the Task 1 macro (sram_macro) on their own.
##  Same clock and budgets as memtest.sdc, so the results compare.
##
####################################################################


# Named after the port, since the flow looks the clock up by CLK_PORT.
create_clock -name CLK -period 2.0 [get_ports CLK]

# Jitter, and the skew the clock tree will have.
set_clock_uncertainty 0.02 [get_clocks CLK]

# Edge rate assumed until the clock tree is built.
set_clock_transition 0.05 [get_clocks CLK]

# Without this, max_transition checking has no value to check against.
set_max_transition 0.2 [current_design]

# 20 percent of the period budgeted at each boundary.
set_input_delay  0.4 -clock CLK [get_ports {A[*] D[*] CEB WEB BWEB[*] TSEL[*]}]
set_output_delay 0.4 -clock CLK [get_ports {Q[*]}]

set_load 0.01 [all_outputs]

# Drive strength is set in scripts/mcmm.tcl, since it names a library
# cell and cell names belong to the kit.
