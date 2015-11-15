#=========================================================================
# TCL Script File for DC Compiler Library Setup
#-------------------------------------------------------------------------

# The makefile will generate various variables which we now read in

source make_generated_vars.tcl

# The following commands setup the standard cell libraries

set target_library       "$SYNTH_LIB"
set link_library         "* $SYNTH_LIB"

# The search path needs to point to the verilog source directory

set search_path [concat $DESIGN_RTL_DIR $search_path ]

