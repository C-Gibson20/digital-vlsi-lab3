####################################################################
##
##  Paths to the views the memory compiler generated.
##  The only place the memory is named.
##
##  Author:   Shuanghua Liu, Sne Samal
##  Version:  2.0
##  Date:     2026-10-21
##
####################################################################

set SRAM_DIR    ts1n65lpll32x32m4_220a
set SRAM_CELL   TS1N65LPLL32X32M4
set SRAM_INST   mem32x32
set SRAM_CORNER tt1p2v25c
set SRAM_LABEL  tc          ;# kit corner the memory stands in for

set SRAM_LEF $SRAM_DIR/LEF/${SRAM_DIR}_5m.lef
set SRAM_LIB $SRAM_DIR/SYNOPSYS/${SRAM_DIR}_${SRAM_CORNER}.lib
set SRAM_GDS $SRAM_DIR/GDSII/${SRAM_DIR}.gds
set SRAM_DB  $SRAM_DIR/DB/${SRAM_DIR}.db
set SRAM_NDM $SRAM_DIR/NDM/${SRAM_DIR}.ndm
