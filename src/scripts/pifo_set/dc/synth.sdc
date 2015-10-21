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
    -period                             ${CLOCK_PERIOD} \
    -name                               master_clk \
    clk

# set clock jitter [%]
set_clock_uncertainty                   0.04 \
    -hold \
    [all_clocks]

set_clock_uncertainty                   0.04 \
    -setup \
    [all_clocks]

# set input and output delay [ns]
# set_input_delay                         0.50 \
#     -clock                              master_clk \
#     ${input_pins}

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
