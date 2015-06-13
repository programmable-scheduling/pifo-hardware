# pifo-hardware

> Clone/pull the git repository

> Do:
    $ cd /path/to/pifo-hardware/
    $ cp Makefile.common.template Makefile.common
  
  Edit Makefile.common --> just change PROJ_DIR path.
  If you have the time, try to automate this.

> To test out the design:
    $ cd .../src/rtl/testbench
    $ make

  Feel free to edit parameters in:
    .../src/rtl/testbench/pifo/globals_tb.v
    .../src/rtl/design/globals_top.v

> You can find the actual design at .../src/rtl/design/
  You can find the testbench at .../src/rtl/testbench/

> Currently testbench does not "print" anything. If you want to view the operation:
    $ dve -vpd dumps/pifo_tb.vpd
  Look at pifo_tb --> tg --> o__packet_priority, o__valid_packet_generated  [[ for generated packets ]]
          pifo_tv --> tr --> i__packet_priority, o__dequeue                 [[ for dequeued packets ]]
  Eyeball the waveform for now to make sure things are working correctly. 
  I will add a text dump later. 
