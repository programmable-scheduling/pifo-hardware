//------------------------------------------------------------------------------
// Preamble
//------------------------------------------------------------------------------
// Simulation precision
`timescale 1ns/1ps

// Clock period
`define CYCLE                       (1.0)
`define HALF_CYCLE                  (`CYCLE / 2.0)

// Active simulation cycles (started to count after all the initialization)
`define NUM_SIM_CYCLES              100

// Generic names to be used in the testbench
`define TESTBENCH_NAME              pifo_tb
`define TEST_MODULE_NAME            pifo_test
`define TEST_INSTANCE_NAME          `TEST_MODULE_NAME
`define TEST_DUMP_NAME              `TESTBENCH_NAME


// Testbench
module `TESTBENCH_NAME;

//------------------------------------------------------------------------------
// IO 
//------------------------------------------------------------------------------
logic                                   clk;
logic                                   reset;
integer                                 clk_count;

//------------------------------------------------------------------------------
// Simulation required signals
//------------------------------------------------------------------------------
integer                                 num_sim_cycles;

//------------------------------------------------------------------------------
// Test module instantiation
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Support module instantiation
//------------------------------------------------------------------------------
clock_generator
    #(
        .HALF_CYCLE                     (`HALF_CYCLE)
    )
    clock_generator(
        .clk                            (clk),
        .clk_delay                      (),
        .clk_count                      (clk_count)
    );

//------------------------------------------------------------------------------
// Simulation control flow
//------------------------------------------------------------------------------
initial
begin: simulation_control_flow
    // Determine the specified simulation cycle
    if(!$value$plusargs("NUM_SIM_CYCLES=%d", num_sim_cycles))
    begin
        num_sim_cycles = `NUM_SIM_CYCLES;
    end

    // Wait until the specified simulation time and call $finish
    #(`CYCLE*num_sim_cycles)
    $finish();

end

//------------------------------------------------------------------------------
// Dump wave
//------------------------------------------------------------------------------
initial
begin: dump_wave
`ifdef VPD
    string test_dump_name = $psprintf("dumps/%s.vpd", `STRINGIFY(`TEST_DUMP_NAME));
    // Dump VCD+ (VPD)
    $vcdplusfile(test_dump_name);
    $vcdpluson;
    $vcdplusmemon;
`endif

`ifdef VCD
    // Dump VCD
    string test_dump_name = $psprintf("dumps/%s.vcd", `STRINGIFY(`TEST_DUMP_NAME));
    $dumpfile(test_dump_name);
    $dumpvars(0, `TESTBENCH_NAME);
`endif
end
/* ************************************************************************** */

//------------------------------------------------------------------------------
// Monitor any signals 
//------------------------------------------------------------------------------
initial
begin: monitor_signals
end
/* ************************************************************************** */

endmodule
