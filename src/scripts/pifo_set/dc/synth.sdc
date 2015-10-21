#=========================================================================
# Constraints file
#-------------------------------------------------------------------------
#
# This file contains various constraints for your chip including the
# target clock period, fanout, transition time and any
# input/output delay constraints.

set_units \
    -capacitance                        pf \
    -time                               ns


echo "======Start Set Clock Period======\n"
set clock_period    ${CLOCK_PERIOD}
echo "======End Set Clock Period======\n"

# set clock period [ns]
create_clock \
    -period                             0.95 \
    -name                               master_clk \
    clk

create_clock                            i__scan_control\[clk_master\] \
    -period                             1000.0 \
    -name                               scan_clk_master

create_clock                            i__scan_control\[clk_slave\] \
    -period                             1000.0 \
    -name                               scan_clk_slave


set_false_path \
    -from                               [get_clocks master_clk] \
    -to                                 [get_clocks scan_clk_master]

set_false_path \
    -from                               [get_clocks master_clk] \
    -to                                 [get_clocks scan_clk_slave]

set_false_path \
    -from                               [get_clocks scan_clk_master] \
    -to                                 [get_clocks master_clk]

set_false_path \
    -from                               [get_clocks scan_clk_master] \
    -to                                 [get_clocks scan_clk_slave]

set_false_path \
    -from                               [get_clocks scan_clk_slave] \
    -to                                 [get_clocks master_clk]

set_false_path \
    -from                               [get_clocks scan_clk_slave] \
    -to                                 [get_clocks scan_clk_master]


set_false_path \
    -from                               [get_ports my*]

# set clock jitter [%]
set_clock_uncertainty                   0.04 \
    -hold \
    [all_clocks]

set_clock_uncertainty                   0.04 \
    -setup \
    [all_clocks]

# set input and output delay [ns]
set input_pins  [all_inputs]
set input_pins  [remove_from_collection ${input_pins} [get_ports clk]]
set input_pins  [remove_from_collection ${input_pins} [get_ports ia__notification*]]
set input_pins  [remove_from_collection ${input_pins} [get_ports ia__neighbor_esid*]]
set input_pins  [remove_from_collection ${input_pins} [get_ports ia__credit*]]
set input_pins  [remove_from_collection ${input_pins} [get_ports i__scan_control\[clk*]]
set_input_delay                         0.50 \
    -clock                              master_clk \
    ${input_pins}

set input_pins  [get_ports ia__notification*]
set input_pins  [add_to_collection ${input_pins} [get_ports ia__neighbor_esid*]]
set input_pins  [add_to_collection ${input_pins} [get_ports ia__credit*]]
set_input_delay                         0.2 \
    -clock                              master_clk \
    ${input_pins}

set output_pins [all_outputs]
set output_pins [remove_from_collection ${output_pins} [get_ports oa__flit*]]
set output_pins [remove_from_collection ${output_pins} [get_ports oa__credit*]]
set_output_delay                        0.45 \
    -clock                              master_clk \
    ${output_pins}

set output_pins [get_ports oa__flit*]
set output_pins [add_to_collection ${output_pins} [get_ports oa__credit*]]
set_output_delay                        0.2 \
    -clock                              master_clk \
    ${output_pins}

set_driving_cell \
    -lib_cell                           BUF_X1M_A12TH \
    [all_inputs]

set_max_transition                      0.04 \
    [all_inputs]

set_max_transition                      0.04 \
    [all_outputs]

set_load \
    -pin_load                           0.05 \
    [all_outputs]


#set_ideal_network \
#    -no_propagate \
#    reset

