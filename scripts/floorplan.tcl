####################################################################
##
##  Core area, macro placement, power grid, tap cells and pins.
##  Sourced by pnr.tcl and fusion.tcl once the design is mapped.
##
##  Author:   Shuanghua Liu, Sne Samal
##  Version:  2.0
##  Date:     2026-10-21
##
####################################################################

set MACRO [get_cells $SRAM_INST]

# Sized from the macro, so a different memory still gets a core that
# fits it. -side_length gives the core; -core_offset adds the die edge.
set CORE_W [expr {[get_attribute $MACRO width]  + 2 * $MACRO_MARGIN}]
set CORE_H [expr {[get_attribute $MACRO height] + $MACRO_MARGIN + $CELL_STRIP}]

initialize_floorplan \
    -site_def    $SITE_NAME \
    -side_length [list $CORE_W $CORE_H] \
    -core_offset $CORE_OFFSET

# Bottom left of the core, leaving the strip above it for the cells.
set_cell_location \
    -coordinates [list [expr {$CORE_OFFSET + $MACRO_MARGIN}] \
                       [expr {$CORE_OFFSET + $MACRO_MARGIN}]] \
    -orientation R0 \
    $MACRO

# Or esle placement treats it as something it may move.
set_attribute $MACRO is_fixed true

# Cells placed hard against a macro cannot be routed to, and the router
# needs room to turn.
create_keepout_margin \
    -type  hard \
    -outer [list $MACRO_HALO $MACRO_HALO $MACRO_HALO $MACRO_HALO] \
    $MACRO

####################################################################
## Power and ground nets
####################################################################
# The netlist says nothing about power, so the supply nets and every
# cell's connection to them are made here.

if { [sizeof_collection [get_nets -quiet $PWR_NET]] == 0 } { create_net -power  $PWR_NET }
if { [sizeof_collection [get_nets -quiet $GND_NET]] == 0 } { create_net -ground $GND_NET }

connect_pg_net -automatic

####################################################################
## Power plan
####################################################################

# Both options default to false. Without them the rail reports
# end-of-line spacing violations against pins inside the cells it
# runs through.
create_pg_std_cell_conn_pattern rail_pattern \
    -layers              $RAIL_LAYER \
    -mark_as_follow_pin  true \
    -check_std_cell_drc  true

# Nothing joins the rails to the ring, so they run out to it.
set_pg_strategy rail_strategy -core \
    -pattern   [list [list pattern: rail_pattern] \
                     [list nets: [list $PWR_NET $GND_NET]]] \
    -extension [list [list stop: first_target]]

# Not M1: the cell rails are there, so a ring segment on M1 is a short.
create_pg_ring_pattern ring_pattern \
    -horizontal_layer   $RING_H_LAYER \
    -horizontal_width   [list $RING_WIDTH] \
    -horizontal_spacing [list $RING_SPACING] \
    -vertical_layer     $RING_V_LAYER \
    -vertical_width     [list $RING_WIDTH] \
    -vertical_spacing   [list $RING_SPACING]

# Nets are laid innermost first. Extending to the die boundary is what
# generates the block's power pins; without them the LEF has none.
set_pg_strategy ring_strategy -core \
    -pattern   [list [list pattern: ring_pattern] \
                     [list nets: [list $GND_NET $PWR_NET]] \
                     [list offset: [list $RING_OFFSET $RING_OFFSET]]] \
    -extension [list [list [list nets: [list $PWR_NET $GND_NET]] \
                           [list stop: design_boundary_and_generate_pin]]]

# A macro draws its current in one place rather than spread along a
# row, so the cell rails alone drop more voltage than it tolerates.
create_pg_ring_pattern macro_ring_pattern \
    -horizontal_layer   $RING_H_LAYER \
    -horizontal_width   [list $MACRO_RING_WIDTH] \
    -horizontal_spacing [list $MACRO_RING_SPACING] \
    -vertical_layer     $RING_V_LAYER \
    -vertical_width     [list $MACRO_RING_WIDTH] \
    -vertical_spacing   [list $MACRO_RING_SPACING]

set_pg_strategy macro_ring_strategy \
    -macros  $MACRO \
    -pattern [list [list pattern: macro_ring_pattern] \
                   [list nets: [list $GND_NET $PWR_NET]] \
                   [list offset: [list $MACRO_RING_OFFSET $MACRO_RING_OFFSET]]]

# Without this the ring surrounds a block it is not connected to.
create_pg_macro_conn_pattern macro_conn_pattern -pin_conn_type scattered_pin

set_pg_strategy macro_conn_strategy \
    -macros  $MACRO \
    -pattern [list [list pattern: macro_conn_pattern] \
                   [list nets: [list $PWR_NET $GND_NET]]]

# Rails are on M1 and the rings above it, so every connection is a via.
set_pg_strategy_via_rule pg_via_rule \
    -via_rule [list [list intersection: adjacent] [list via_master: default]]

# The rails stop at the first thing they meet, so they go last.
compile_pg -strategies macro_ring_strategy -via_rule pg_via_rule
compile_pg -strategies macro_conn_strategy
compile_pg -strategies ring_strategy       -via_rule pg_via_rule
compile_pg -strategies rail_strategy       -via_rule pg_via_rule

connect_pg_net

####################################################################
## Tap cells and pins
####################################################################
# The macro carries its own wells, and the keepout keeps taps off it.

create_tap_cells \
    -lib_cell [get_lib_cells */$TAP_CELL] \
    -distance $TAP_DISTANCE \
    -pattern  stagger

# -self places this block's own pins, not the macro's.
place_pins -self

redirect -tee -file $RPT_DIR/floorplan_pg_connectivity.rpt \
    {check_pg_connectivity -check_std_cell_pins none}
redirect -tee -file $RPT_DIR/floorplan_pg_drc.rpt {check_pg_drc}

save_block -label floorplan
save_lib
