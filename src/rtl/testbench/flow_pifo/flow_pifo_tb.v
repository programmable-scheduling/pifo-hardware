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
`define TESTBENCH_NAME              flow_pifo_tb
`define TEST_MODULE_NAME            flow_pifo_test
`define TEST_INSTANCE_NAME          `TEST_MODULE_NAME
`define TEST_DUMP_NAME              `TESTBENCH_NAME

`include "flow_pifo_tb_headers.vh"

// Testbench
module `TESTBENCH_NAME;
//------------------------------------------------------------------------------
// Local data structures
//------------------------------------------------------------------------------
typedef enum logic [1:0] {
	GENERATE,
	REINSERT,
    DRAIN	
} Phase;

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
// Testbench signals
//------------------------------------------------------------------------------
TGConfig                                w__traffic_generator_config;
TGConfig                                w__reinsert_generator_config;
TRConfig                                w__traffic_receiver_config;


FlowId                                  w__enqueue_flow_id;
Priority                                w__enqueue_packet_priority;
logic                                   w__enqueue;

FlowId                                  w__dequeue_flow_id;
Priority                                w__dequeue_packet_priority;
logic                                   w__dequeue;

logic                                   w__generate;
Priority                                w__generate_packet_priority;
FlowId                                  w__generate_packet_flow_id;
logic                                   w__reinsert;
Priority                                w__reinsert_packet_priority;
FlowId                                  w__reinsert_packet_flow_id;

logic                                   w__pifo_empty;
logic                                   w__pifo_full;
logic                                   w__pifo_push_ready;
logic                                   w__pifo_pop_valid;

Phase                                   r__phase__pff;
Phase                                   w__phase__next;
logic                                   w__generate_phase;
logic                                   w__receive_phase;
logic                                   w__reinsert_phase;
CounterSignal                           r__phase_count__pff;
CounterSignal                           w__phase_count__next;

CounterSignal                           w__total_packets__next;
CounterSignal                           r__total_packets__pff;

//------------------------------------------------------------------------------
// Test module instantiation
//------------------------------------------------------------------------------
flow_pifo fp (
    .clk                                (clk),
    .reset                              (reset),
    .i__enqueue                         (w__enqueue),
    .i__enqueue_priority                (w__enqueue_packet_priority),
    .i__enqueue_flow_id                 (w__enqueue_flow_id),
    .i__dequeue                         (w__dequeue),
    .o__dequeue_priority                (w__dequeue_packet_priority),
    .o__dequeue_flow_id                 (w__dequeue_flow_id)
);

//------------------------------------------------------------------------------
// Support modules instantiation
//------------------------------------------------------------------------------
traffic_generator tg (
    .clk                                (clk),
    .reset                              (reset),

    .i__config                          (w__traffic_generator_config),
    .i__generate_phase                  (w__generate_phase),
    .i__phase_count                     (r__phase_count__pff),
    .i__pifo_ready                      (1'b1),                         // TODO Verify this is OK

    .o__packet_flow_id                  (w__generate_packet_flow_id),
    .o__packet_priority                 (w__generate_packet_priority),
    .o__valid_packet_generated          (w__generate),
    .o__num_pkts_sent                   ()                              // unused: OK
);

traffic_generator rig (
    .clk                                (clk),
    .reset                              (reset),

    .i__config                          (w__reinsert_generator_config),
    .i__generate_phase                  (w__reinsert_phase),
    .i__phase_count                     (r__phase_count__pff),
    .i__pifo_ready                      (w__dequeue),

    .o__packet_flow_id                  (),                             // don't require this for this test
    .o__packet_priority                 (w__reinsert_packet_priority),
    .o__valid_packet_generated          (w__reinsert),
    .o__num_pkts_sent                   ()                              // unused: OK
);


traffic_receiver tr (
    .clk                                (clk),
    .reset                              (reset),

    .i__config                          (w__traffic_receiver_config),
    .i__receive_phase                   (w__receive_phase),
    .i__phase_count                     (r__phase_count__pff),

    .i__pifo_ready                      (1'b1),                         // TODO Verify this is okay
    .i__packet_priority                 (w__dequeue_packet_priority),
    .i__packet_flow_id                  (w__dequeue_flow_id),

    .o__dequeue                         (w__dequeue)
);

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
// Auxiliary logic
//------------------------------------------------------------------------------
always_comb
begin
    w__enqueue          =   w__generate || w__reinsert;
    w__enqueue_flow_id  =   w__generate ? w__generate_packet_flow_id : w__dequeue_flow_id;
    w__enqueue_packet_priority
                        =   w__generate ? w__generate_packet_priority : w__reinsert_packet_priority;
end

//------------------------------------------------------------------------------
// Traffic phase 
//------------------------------------------------------------------------------
logic   w__switch_phase;
always_comb
begin
    w__phase__next      = r__phase__pff;

    // Decide whether to switch phase
    if ((r__total_packets__pff % MAX_PKTS_PER_PHASE == 0) &&
            r__total_packets__pff != '0)
        w__switch_phase = 1'b1;
    else w__switch_phase = 1'b0;

    // Switch phase if required
    if ((w__switch_phase) && (r__phase__pff == GENERATE))
        w__phase__next  = REINSERT;
    else if ((w__switch_phase) && (r__phase__pff == REINSERT))
        w__phase__next  = DRAIN;
    else if ((w__switch_phase) && (r__phase__pff == DRAIN))
        w__phase__next  = GENERATE;

    // Update phase count
    if ((r__phase__pff==DRAIN) && (w__phase__next == GENERATE))
    	w__phase_count__next  = r__phase_count__pff + 1'b1;
    else w__phase_count__next = r__phase_count__pff;
end

always_comb
begin
    w__total_packets__next = r__total_packets__pff;

    // Update packet count
    if (w__generate_phase && w__generate)
        w__total_packets__next = r__total_packets__pff + 1'b1;
    else if (w__receive_phase && w__dequeue)
        w__total_packets__next = r__total_packets__pff + 1'b1;
end

always_comb
begin
    // Phase signals
    w__generate_phase   = (r__phase__pff == GENERATE);
    w__receive_phase    = ((r__phase__pff == DRAIN) || (r__phase__pff == REINSERT)); 
    w__reinsert_phase   = (r__phase__pff == REINSERT);
end

always_ff @(posedge clk)
begin
    if (reset)
    begin
    	r__phase__pff       <=  GENERATE;
    	r__phase_count__pff <=  '0;
    	r__total_packets__pff
    	                    <=  '0;
    end
    else 
    begin
        r__phase__pff       <=  w__phase__next;
        r__phase_count__pff <=  w__phase_count__next;
        r__total_packets__pff 
                            <=  w__total_packets__next;
    end
end

//------------------------------------------------------------------------------
// Traffic generator/receiver configuration
//------------------------------------------------------------------------------
always_comb
begin
    w__traffic_generator_config.flow_id_seed        = PKT_FLOWID_SEED;
    w__traffic_generator_config.priority_seed       = PRIORITY_SEED;
    w__traffic_generator_config.injrate_seed        = PKT_INJRATE_SEED;
    w__traffic_generator_config.injrate             = PKT_INJRATE;
    w__traffic_generator_config.total_packets       = MAX_PACKETS;

    w__reinsert_generator_config.flow_id_seed       = PKT_FLOWID_SEED;
    w__reinsert_generator_config.priority_seed      = PRIORITY_SEED2;
    w__reinsert_generator_config.injrate_seed       = PKT_RIRATE_SEED;
    w__reinsert_generator_config.injrate            = PKT_RIRATE;
    w__reinsert_generator_config.total_packets      = MAX_PACKETS;


    w__traffic_receiver_config.ejrate_seed          = PKT_EJRATE_SEED;
    w__traffic_receiver_config.ejrate               = PKT_EJRATE;
end

//------------------------------------------------------------------------------
// Simulation control flow
//------------------------------------------------------------------------------
initial
begin: simulation_control_flow
    reset   = 1'b0;

    // Free run the clock
    #(`CYCLE*3)
    reset   = 1'b1;

    #(`CYCLE*3)
    reset   = 1'b0;

    #(`CYCLE)

    // Determine the specified simulation cycle
    if(!$value$plusargs("NUM_SIM_CYCLES=%d", num_sim_cycles))
    begin
        num_sim_cycles = `NUM_SIM_CYCLES;
    end

    // Wait until the specified simulation time and call $finish
    #(`CYCLE*num_sim_cycles)

    // Monitor any signals you want
    $monitor("\n\n======= STATS =======\nTotal packets generated: %d\nTotal packets reinserted: %d\nTotal packets received: %d\n\n", tg.r__num_pkts_sent__pff, rig.r__num_pkts_sent__pff, tr.r__num_pkts_recvd__pff);
    
    #(`CYCLE)
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

endmodule
