#=========================================================================
# Constraints file
#-------------------------------------------------------------------------
#
# This file contains various constraints for your chip including the
# target clock period, fanout, transition time and any
# input/output delay constraints.
#

# set clock period [ns]
create_clock -period 1 -name clk_input clk

# set clock jitter [%]
set_clock_uncertainty -setup 0.02 clk_input
set_clock_uncertainty -hold  0.02 clk_input

# set input and output delay [ns]
set_input_delay  0.05 -clock clk_input [remove_from_collection [all_inputs] clk]
set_output_delay 0.05 -clock clk_input [all_outputs]

# set wire load model
set_wire_load_model -name "SMALL" 

# set output capacitive load [pF]
set_load 0.015 [all_outputs]

# set false paths
set_false_path -from reset

