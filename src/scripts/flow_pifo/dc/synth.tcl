#=========================================================================
# TCL Script File for Synthesis using Cadence RTL Compiler
#-------------------------------------------------------------------------

# 

# The makefile will generate various variables which we now read in
# and then display

source make_generated_vars.tcl

echo "================================="
echo ${DESIGN_RTL_DIR} "\n"
echo ${DESIGN_RTL} "\n"
echo ${DESIGN_TOPLEVEL} "\n"
echo "================================="

set_host_options \
    -max_cores                          10

# The library setup is kept in a separate tcl file which we now source

source libs.tcl

set alib_library_analysis_path          "/homes/owenhsin/share/ibm_soi12s0_alib/alib"

set hdlin_sverilog_std                  2009
set hdlin_ff_always_async_set_reset     true
set hdlin_ff_always_sync_set_reset      true
set hdlin_auto_save_templates           true
#set hdlin_mux_size_limit 128
# set hdlin_check_no_latch true
set verilogout_show_unconnected_pins    true
set compile_fix_multiple_port_ets       true

set fsm_auto_inferring true
set fsm_enable_state_minimization true
set fsm_export_formality_state_info true

# set hdlin_check_no_latch true
define_name_rules nameRules -restricted "!@#$%^&*()\\-" -case_insensitive
set verilogout_show_unconnected_pins "true"

sh mkdir analyzed
define_design_lib WORK -path analyzed

# These two commands read in your verilog source and elaborate it

analyze -f sverilog ${DESIGN_RTL} -vcs "+define+USE_STDCELL_LATCH"
elaborate -lib WORK ${DESIGN_TOPLEVEL} -update
#elaborate -lib WORK router -update

set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

# This command will check your design for any errors

current_design ${DESIGN_TOPLEVEL}
check_design

#ungroup rtr -flatten
#ungroup -all -flatten

link
uniquify
check_design

# We now load in the constraints file

source synth.sdc

report_timing -loops

# This actually does the synthesis. The -effort option indicates 
# how much time the synthesizer should spend optimizing your design to
# gates. Setting it to high means synthesis will take longer but will
# probably produce better results.

echo "======START COMPILATION===========================\n\n\n"
#list_designs

#compile_ultra -timing_high_effort_script


compile_ultra -timing_high_effort_script

#compile -map_effort medium 
#compile -map_effort high
#compile_ultra -timing_high_effort_script -no_autoungroup
#compile_ultra
#compile_ultra -no_autoungroup
#compile_ultra -timing_high_effort_script

echo "======END COMPILATION=============================\n\n\n"


report_timing -loops

# Make sure we are at the top level
set current_design  ${DESIGN_TOPLEVEL}
change_names -rules verilog -hierarchy -verbose
change_names -rules nameRules -hierarchy -verbose

# We write out the results as a verilog netlist

write -format verilog -hierarchy -output [format "%s%s" ${DESIGN_TOPLEVEL} ".gate.v"]

# Write out the delay information to the sdf file
write_sdf [format "%s%s" ${DESIGN_TOPLEVEL} ".gate.sdf"]  
write_sdc [format "%s%s" ${DESIGN_TOPLEVEL} ".gate.sdc"]

# We create a timing report for the worst case timing path, 
# an area report for each reference in the heirachy and a DRC report

report_timing > [format "%s%s" ${DESIGN_TOPLEVEL} ".timing.rpt"]
report_area -hierarchy > [format "%s%s" ${DESIGN_TOPLEVEL} ".area.rpt"]
report_power > [format "%s%s" ${DESIGN_TOPLEVEL} ".power.rpt"]

# Used to exit the Design Compiler 

quit
