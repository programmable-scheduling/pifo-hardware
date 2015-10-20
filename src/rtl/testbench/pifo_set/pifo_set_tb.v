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
`define TESTBENCH_NAME              pifo_set_tb
`define TEST_MODULE_NAME            pifo_set_test
`define TEST_INSTANCE_NAME          `TEST_MODULE_NAME
`define TEST_DUMP_NAME              `TESTBENCH_NAME

`include "pifo_set_tb_headers.vh"

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


PacketPointer                           w__enqueue_packet_pointer;
Priority                                w__enqueue_packet_priority;
logic                                   w__enqueue;

PacketPointer                           w__dequeue_packet_pointer;
Priority                                w__dequeue_packet_priority;
logic                                   w__dequeue;

logic                                   w__reinsert;
Priority                                w__reinsert_packet_priority;

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

CounterSignal                           w__reinserted_packet_count;
CounterSignal                           w__last_reinsert_packet_count__next;
CounterSignal                           r__last_reinsert_packet_count__pff;

//------------------------------------------------------------------------------
// Test module instantiation
//------------------------------------------------------------------------------
pifo_set #(
    .NUM_ELEMENTS                       (NUM_ELEMENTS),
    .MAX_PRIORITY                       (MAX_PACKET_PRIORITY),
    .DATA_WIDTH                         ($bits(PacketPointer))          // strictly, we don't care about this for this test
) pf (
    .clk                                (clk),
    .reset                              (reset),

    .i__push_valid                      (w__enqueue),              
    .i__push_priority                   (w__enqueue_packet_priority),
    .i__push_data                       (w__enqueue_packet_pointer),
    .o__push_ready                      (w__pifo_push_ready),              
    .o__push_ready__next                (),        
    .i__reinsert_priority               (w__reinsert ? w__reinsert_packet_priority : '0),       

    .o__pop_valid                       (w__pifo_pop_valid),               
    .o__pop_priority                    (w__dequeue_packet_priority),
    .o__pop_data                        (w__dequeue_packet_pointer),
    .i__pop                             (w__dequeue),                     
    .i__clear_all                       ()
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
    .i__pifo_ready                      (~w__pifo_full),

    .o__packet_pointer                  (w__enqueue_packet_pointer),
    .o__packet_priority                 (w__enqueue_packet_priority),
    .o__valid_packet_generated          (w__enqueue),
    .o__num_pkts_sent                   ()
);

traffic_generator rig (
    .clk                                (clk),
    .reset                              (reset),

    .i__config                          (w__reinsert_generator_config),
    .i__generate_phase                  (w__reinsert_phase),
    .i__phase_count                     (r__phase_count__pff),
    .i__pifo_ready                      (w__dequeue),

    .o__packet_pointer                  (),                             // don't require this for this test
    .o__packet_priority                 (w__reinsert_packet_priority),
    .o__valid_packet_generated          (w__reinsert),
    .o__num_pkts_sent                   (w__reinserted_packet_count)
);


traffic_receiver tr (
    .clk                                (clk),
    .reset                              (reset),

    .i__config                          (w__traffic_receiver_config),
    .i__receive_phase                   (w__receive_phase),
    .i__phase_count                     (r__phase_count__pff),

    .i__pifo_ready                      (~w__pifo_empty),
    .i__packet_priority                 (w__dequeue_packet_priority),
    .i__packet_pointer                  (w__dequeue_packet_pointer),

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
    w__pifo_full        = ~w__pifo_push_ready;
    w__pifo_empty       = ~w__pifo_pop_valid;
end

always_comb
begin
    w__phase__next      = r__phase__pff;
    w__last_reinsert_packet_count__next   
                        = r__last_reinsert_packet_count__pff;
    if (w__pifo_full)
    	w__phase__next  = REINSERT;
    else if (w__pifo_empty)
    	w__phase__next  = GENERATE;
    else if ((r__phase__pff == REINSERT) && (w__reinserted_packet_count != r__last_reinsert_packet_count__pff)
                && (w__reinserted_packet_count % NUM_ELEMENTS == 0))   // NOTE: Not synthesizable (or atleast not easily)
    begin
        w__phase__next  = DRAIN;
        w__last_reinsert_packet_count__next = r__last_reinsert_packet_count__pff;
    end

    if ((r__phase__pff==DRAIN) && (w__phase__next == GENERATE))
    	w__phase_count__next  = r__phase_count__pff + 1'b1;
    else w__phase_count__next = r__phase_count__pff;

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
    	r__last_reinsert_packet_count__pff 
    	                    <= '0;
    end
    else 
    begin
        r__phase__pff       <=  w__phase__next;
        r__phase_count__pff <=  w__phase_count__next;
        r__last_reinsert_packet_count__pff
                            <=  w__last_reinsert_packet_count__next;
    end
end

always_comb
begin
    w__traffic_generator_config.pkt_pointer_seed = PKT_POINTER_SEED;
    w__traffic_generator_config.priority_seed    = PRIORITY_SEED;
    w__traffic_generator_config.injrate_seed     = PKT_INJRATE_SEED;
    w__traffic_generator_config.injrate          = PKT_INJRATE;
    w__traffic_generator_config.total_packets    = MAX_PACKETS;

    w__reinsert_generator_config.pkt_pointer_seed = PKT_POINTER_SEED;
    w__reinsert_generator_config.priority_seed    = PRIORITY_SEED;
    w__reinsert_generator_config.injrate_seed     = PKT_RIRATE_SEED;
    w__reinsert_generator_config.injrate          = PKT_RIRATE;
    w__reinsert_generator_config.total_packets    = MAX_PACKETS;


    w__traffic_receiver_config.ejrate_seed       = PKT_EJRATE_SEED;
    w__traffic_receiver_config.ejrate            = PKT_EJRATE;
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
    $monitor("\n\n======= STATS =======\nTotal packets generated: %d\nTotal packets received: %d\n\n", tg.r__num_pkts_sent__pff, tr.r__num_pkts_recvd__pff);
    
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
