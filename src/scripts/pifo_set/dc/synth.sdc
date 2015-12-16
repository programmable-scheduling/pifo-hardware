#=========================================================================
# Constraints file
#-------------------------------------------------------------------------
#
# This file contains various constraints for your chip including the
# target clock period, fanout, transition time and any
# input/output delay constraints.

set_units \
    -capacitance                        fF \
    -time                               ps


echo "======Start Set Clock Period======\n"
set clock_period    ${CLOCK_PERIOD}
echo "======End Set Clock Period======\n"

# set clock period [ns]
create_clock \
    -period                             ${CLOCK_PERIOD} \
    -name                               master_clk \
    clk

# set clock jitter [%]
set_clock_uncertainty                   40 \
    -hold \
    [all_clocks]

set_clock_uncertainty                   40 \
    -setup \
    [all_clocks]

# set input and output delay [ns]
# set_input_delay                         0.50 \
#     -clock                              master_clk \
#     ${input_pins}

# Set suitable driving cell
# set_driving_cell \
#     -lib_cell                           \
#     [all_inputs]

set_max_transition                      40 \
    [all_inputs]

set_max_transition                      40 \
    [all_outputs]

set_load \
    -pin_load                           10 \
    [all_outputs]
