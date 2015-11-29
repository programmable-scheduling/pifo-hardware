module flow_pifo (
    clk,
    reset,

    i__enqueue,
    i__enqueue_priority,
    i__enqueue_flow_id,

    i__dequeue,
    o__dequeue_priority,
    o__dequeue_flow_id
);

`include "flow_pifo_headers.vh"

//------------------------------------------------------------------------------
// Global signals
//------------------------------------------------------------------------------
input  logic                            clk;
input  logic                            reset;

//------------------------------------------------------------------------------
// Interface
//------------------------------------------------------------------------------
input  logic                            i__enqueue;
input  Priority                         i__enqueue_priority;
input  FlowId                           i__enqueue_flow_id;

input  logic                            i__dequeue;
output Priority                         o__dequeue_priority;
output FlowId                           o__dequeue_flow_id;


//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                                   w__pifo_set_push_valid;
Priority                                w__pifo_set_push_priority;
FlowId                                  w__pifo_set_push_flow_id;
logic                                   w__pifo_set_push_flow_empty;
logic                                   w__pifo_set_ready;
logic                                   w__pifo_set_reinsert_valid;
Priority                                w__pifo_set_reinsert_priority;
logic                                   w__pifo_set_pop_valid;
FlowId                                  w__pifo_set_pop_flow_id;
Priority                                w__pifo_set_pop_priority;
logic                                   w__pifo_set_pop;

logic                                   w__prefetch_push_valid;
logic                                   w__prefetch_push_flow_not_full;
logic                                   w__prefetch_reinsert_valid;
Priority                                w__prefetch_reinsert_priority;
Priority                                w__prefetch_pop_priority;
logic                                   w__prefetch_pop_priority_valid;
logic                                   w__prefetch_pop;

logic                                   w__fifobank_push_valid;
logic                                   w__fifobank_reinsert_valid;
Priority                                w__fifobank_reinsert_priority;
Priority                                w__fifobank_pop_priority;
logic                                   w__fifobank_pop_priority_valid;
logic                                   w__fifobank_pop;

logic                                   w__bypass_prefetch;
logic                                   w__bypass_fifo;

//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
pifo_set #(
    .NUM_ELEMENTS           (NUM_FLOWS),
    .MAX_PRIORITY           (MAX_PACKET_PRIORITY),
    .DATA_WIDTH             ($bits(FlowId))
) pifo  (
    .clk                    (clk),
    .reset                  (reset),

    // Input interface
    .i__push_valid          (w__pifo_set_push_valid),
    .i__push_priority       (i__enqueue_priority),
    .i__push_flow_id        (w__pifo_set_push_flow_id),
    .o__push_flow_empty     (w__pifo_set_push_flow_empty),

    .o__pifo_set_ready      (w__pifo_set_ready),
    .o__pifo_set_ready__next(),

    .i__reinsert_priority   (w__pifo_set_reinsert_priority),
    .i__reinsert_valid      (w__pifo_set_reinsert_valid),

    // Output interface
    .o__pop_valid           (w__pifo_set_pop_valid),
    .o__pop_priority        (w__pifo_set_pop_priority),
    .o__pop_flow_id         (w__pifo_set_pop_flow_id),
    .i__pop                 (w__pifo_set_pop),
    .i__clear_all           ('0)                                                // pulled to '0: OK
);

prefetch_buffer #(
    .NUM_FLOWS              (NUM_FLOWS),
    .DEPTH                  (PREFETCH_BUFFER_DEPTH),
    .DATA_WIDTH             ($bits(Priority))
) pre_buf (
    .clk                    (clk),
    .reset                  (reset),

    // Input interface
    .i__push_valid          (w__prefetch_push_valid),
    .i__push_flow_id        (i__enqueue_flow_id),
    .i__push_data           (i__enqueue_priority),
    .o__push_flow_not_full  (w__prefetch_push_flow_not_full),

    .i__reinsert_valid      (w__prefetch_reinsert_valid),
    .i__reinsert_data       (w__prefetch_reinsert_priority),

    // Output interface
    .o__pop_data            (w__prefetch_pop_priority),
    .o__pop_valid           (w__prefetch_pop_priority_valid),
    .i__pop                 (w__prefetch_pop),
    .i__pop_flow_id         (w__pifo_set_pop_flow_id)                           // OK
);

fifo_bank #(
    .NUM_FLOWS              (NUM_FLOWS),
    .DEPTH                  (FIFO_DEPTH),
    .DATA_WIDTH             ($bits(Priority))
) fifobank (
    .clk                    (clk),
    .reset                  (reset),

    // Input interface
    .i__push_valid          (w__fifobank_push_valid),
    .i__push_flow_id        (i__enqueue_flow_id),
    .i__push_data           (i__enqueue_priority),
    .o__push_flow_not_full  (),                                                 // unused: OK

    .i__reinsert_valid      (w__fifobank_reinsert_valid),                       // pulled to '0: OK
    .i__reinsert_data       (w__fifobank_reinsert_priority),                    // pulled to '0: OK

    // Output interface
    .o__pop_data            (w__fifobank_pop_priority),
    .o__pop_valid           (w__fifobank_pop_priority_valid),
    .i__pop                 (w__fifobank_pop),
    .i__pop_flow_id         (w__pifo_set_pop_flow_id)                           // OK
);


//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign  o__dequeue_priority = w__pifo_set_pop_priority;
assign  o__dequeue_flow_id  = w__pifo_set_pop_flow_id;

//------------------------------------------------------------------------------
// Bypass signals
//------------------------------------------------------------------------------
always_comb
begin
    if (w__pifo_set_push_flow_empty)                                            // 1. PIFO set entry for the flow being
    begin                                                                       // enqueued is invalid
        w__bypass_prefetch      =   1'b1;
        w__bypass_fifo          =   1'b1;
    end
    else if (w__prefetch_push_flow_not_full)                                    // 2. PIFO set entry exists for enqueue flow
    begin                                                                       // But it's prefetch buffer is not full
        w__bypass_prefetch      =   1'b0;
        w__bypass_fifo          =   1'b1;
    end
    else                                                                        // 3. PIFO set entry exists for enqueue flow
    begin                                                                       // And it's prefetch buffer is also full
        w__bypass_prefetch      =   1'b0;
        w__bypass_fifo          =   1'b0;
    end
end


//------------------------------------------------------------------------------
// Pifo-set signals
//------------------------------------------------------------------------------
// Reinsert logic
always_comb
begin
    if (w__prefetch_pop_priority_valid ||                                       // 1. Have a valid prefetch entry OR
            (~w__prefetch_pop_priority_valid && i__enqueue &&                   // 2. Don't have a valid prefetch entry, AND
              (i__enqueue_flow_id == w__pifo_set_pop_flow_id))                  //    new enqueue flow is the same as popped
       )                                                                        //    flow.
        w__pifo_set_reinsert_valid = i__dequeue;
    else 
        w__pifo_set_reinsert_valid = 1'b0;

    // TODO Assert that if prefetch is empty, then so is the 
    // corresponding fifo bank.
end

always_comb
begin
    if (w__prefetch_pop_priority_valid)                                         // 1. Prefetch entry is valid, get prio from there
        w__pifo_set_reinsert_priority   = w__prefetch_pop_priority;
    else if (~w__prefetch_pop_priority_valid && (i__enqueue_flow_id == w__pifo_set_pop_flow_id))
        w__pifo_set_reinsert_priority   = i__enqueue_priority;                  // 2. Same as 2, above. Get the enqueue priority
    else 
        w__pifo_set_reinsert_priority   = '0;                                   // 3. Neither, ignore reinsert priority
                                                                                // TODO Assert that w__pifo_set_reinsert_valid = false
end

// Push logic
always_comb
begin
    // TODO Asserts
    w__pifo_set_push_flow_id    =   i__enqueue_flow_id;
    if ((w__pifo_set_push_flow_empty) && i__enqueue)                            // 1. If no valid entry for enqueue flow, push
        w__pifo_set_push_valid  =   1'b1;                                       // Note that if enqueue flow == popped flow 
    else                                                                        // by defn w__pifo_set_push_flow_empty = 0
        w__pifo_set_push_valid  =   1'b0;                                       // and we will fall back to the reinsert mechn.
end

// Pop logic
always_comb
begin
    w__pifo_set_pop             =   i__dequeue;                                 // Obvious
end

//------------------------------------------------------------------------------
// Prefetch buffer signals
//------------------------------------------------------------------------------
// Reinsert logic 
always_comb
begin
    if ( ( w__fifobank_pop_priority_valid ||                                    // 1. Fifobank has a valid entry OR
           (~w__fifobank_pop_priority_valid && i__enqueue &&                    // 2. Fifobank does not have a valid entry AND
            (i__enqueue_flow_id == w__pifo_set_pop_flow_id))                    //    enqueued flow is same as popped flow.
         ) &&
         ~w__bypass_prefetch                                                    // Gate the entire thing by bypass prefetch
       )
        w__prefetch_reinsert_valid = i__dequeue;
    else 
        w__prefetch_reinsert_valid = 1'b0;
end

always_comb
begin
    if (w__fifobank_pop_priority_valid)                                         // Similar reasoning to pifo-set reinsert
        w__prefetch_reinsert_priority   = w__fifobank_pop_priority;
    else if ( (~w__fifobank_pop_priority_valid && (i__enqueue_flow_id == w__pifo_set_pop_flow_id)) &&
              ~w__bypass_prefetch)
        w__prefetch_reinsert_priority   = i__enqueue_priority;
    else 
        w__prefetch_reinsert_priority   = '0;
end

// Push logic
always_comb
begin
    // TODO Assert that corresponding fifo is empty
    if ((w__prefetch_push_flow_not_full) && ~w__bypass_prefetch && i__enqueue)  // Similar reasoning to pifo-set
        w__prefetch_push_valid  = 1'b1;
    else
        w__prefetch_push_valid  = 1'b0;
end

// Pop logic
always_comb
begin
    w__prefetch_pop             =   i__dequeue;                                 // Obvious
end


//------------------------------------------------------------------------------
// Fifobank signals
//------------------------------------------------------------------------------
// [ssub] I am re-using the logic of the pre-fetch buffer for the fifo bank
// The fifo bank will have atmost 1 push and 1 pop in any cycle. There is no
// notion of "re-inserting". We just set reinsert signals to '0 and they should
// get synthesized away. We can explicitly re-write the fifo bank module if 
// this does not happen, or if this organization is confusing.
// Reinsert logic 
always_comb
begin
    w__fifobank_reinsert_valid      = 1'b0;
    w__fifobank_reinsert_priority   = 1'b0;
end

// Push logic
always_comb
begin
    if (i__enqueue && ~w__bypass_fifo)  w__fifobank_push_valid  = 1'b1;         // 1. Push to fifobank if there's valid enqueue
    else                                w__fifobank_push_valid  = 1'b0;         // and bypass is false.
end

// Pop logic
always_comb
begin
    w__fifobank_pop         =   i__dequeue;                                     // Obvious
end

endmodule
