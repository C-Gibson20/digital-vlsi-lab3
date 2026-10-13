####################################################################
##
##  Compile the memory's Liberty to a Synopsys database.
##
##  Author:   Sne Samal
##  Version:  1.0
##  Date:     2026-09-04
##
##      lc_shell -f scripts/sram_lib.tcl
##
####################################################################

source scripts/sram.tcl

# read_lib on a path that does not exist leaves the shell at an
# interactive prompt rather than saying what is wrong.
if { ![file exists $SRAM_LIB] } {
    puts "No Liberty at $SRAM_LIB. Check the filenames the memory compiler wrote."
    exit 1
}

file mkdir [file dirname $SRAM_DB]

# write_lib names the library declared inside the Liberty, which is not
# reliably the filename, so it is read rather than constructed.
proc lib_name {path} {
    set fh [open $path r]
    while { [gets $fh line] >= 0 } {
        if { [regexp {^\s*library\s*\(\s*"?([^")]+)"?\s*\)} $line -> name] } {
            close $fh
            return [string trim $name]
        }
    }
    close $fh
    error "No library declaration found in $path"
}

read_lib $SRAM_LIB
write_lib [lib_name $SRAM_LIB] -format db -output $SRAM_DB

exit 0
