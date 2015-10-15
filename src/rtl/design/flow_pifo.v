module flow_pifo (
    clk,
    reset,

    i__enqueue,
    i__enqueue_priority,
    i__enqueue_flow_id,
    i__packet_metadata,
    i__dequeue,

    o__dequeue_priority,
    o__packet_pointer,
    o__pifo_full,
    o__pifo_empty
);

`include "pifo_headers.vh"

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
input  PacketPointer                    i__packet_pointer;
input  FlowId                           i__enqueue_flow_id;

input  logic                            i__dequeue;

output Priority                         o__dequeue_priority;
output PacketPointer                    o__packet_pointer;

output logic                            o__pifo_full;
output logic                            o__pifo_empty;

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                                   w__pifo_push_ready;
logic                                   w__pifo_pop_valid;

logic                                   w__pifo_push_valid;
FlowId                                  w__pifo_push_flow_id;
FlowId                                  w__pifo_pop_flow_id;
Priority                                w__pifo_push_priority;

Metadata    [NUM_FLOWS-1:0]             w__fifo_data_out;
logic       [NUM_FLOWS-1:0]             w__fifo_dequeue;            // dequeue signal for each fifo
logic       [NUM_FLOWS-1:0]             w__fifo_enqueue;            // enqueue signal for each fifo
                                                                    // require: atmost one of the bits is 1
                                                                    // currently enforced by construction   [TOASSERT]

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign  o__pifo_full    =   ~w__pifo_push_ready;
assign  o__pifo_empty   =   ~w__pifo_pop_valid;

//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
pifo_set #(
    .NUM_ELEMENTS           (NUM_FLOWS),
    .MAX_PRIORITY           (MAX_PACKET_PRIORITY),
    .DATA_WIDTH             ($bits(FlowId))
) base  (
    .clk                    (clk),
    .reset                  (reset),

    .i__push_valid          (w__pifo_push_valid),
    .i__push_priority       (w__pifo_push_priority),
    .i__push_data           (w__pifo_push_flow_id),
    .o__push_ready          (w__pifo_push_ready),
    .o__push_ready__next    (),
    .i__reinsert_priority   (),

    .o__pop_valid           (w__pifo_pop_valid),
    .o__pop_priority        (w__pifo_pop_priority),
    .o__pop_data            (w__pifo_pop_flow_id),
    .i__pop                 (w__pifo_pop_ready),
    .i__clear_all           ()
);

// [ssub] The fifos have to be bypass enabled. Or there has to be
// a separate bypass mechanism in the pre-fetch modules.
// Why? Say flow 1 is highest priority and has exactly 1 element.
// Cycle 0: Enqueue a packet to flow 1
// Cycle 0: Dequeue a packet from flow 1
// We need to re-insert flow 1 with new priority (of the new incoming
// packet) in this very cycle. We cannot defer it to the next
// cycle.  FIXME 
genvar flow_idx;
generate for(flow_idx = 0; flow_idx < NUM_FLOWS; flow_idx = flow_idx + 1)
begin: gen_flow_fifo
fifo #(
    .BYPASS_ENABLE          (1'b0),
    .DATA_WIDTH             ($bits(Metadata)),
    .DEPTH                  (FIFO_DEPTH),
) flow_fifo (
    .clk                    (clk),
    .reset                  (reset),

    .i__data_in_valid       (w__fifo_enqueue[flow_idx]),
    .i__data_in             (w__packet_metadata),
    .o__data_in_ready       (),         // FIXME Add this signal!
    .o__data_in_ready__next (),

    o__data_out_valid       (),
    o__data_out             (w__fifo_data_out[flow_idx]),
    i__data_out_ready       ()
);
end
endgenerate

//------------------------------------------------------------------------------
// Output signals
//------------------------------------------------------------------------------
assign  o__dequeue_priority = w__pifo_pop_priority;                         // Should be equal to w__fifo_data_out[w__pifo_pop_flow_id].prio [TOASSERT]
assign  o__packet_pointer   = w__fifo_data_out[w__pifo_pop_flow_id].pointer;


//------------------------------------------------------------------------------
// Flow fifo signals
//------------------------------------------------------------------------------
genvar fid;
generate for (fid = 0; fid < NUM_FLOWS; fid = fid + 1)
begin: gen_flow_fifo_signal
always_comb
begin
    if (fid == i__enqueue_flow_id)
        w__fifo_enqueue[fid] = 1'b1;
    else 
        w__fifo_enqueue[fid] = 1'b0;

    if (fid == w__pifo_pop_flow_id)
        w__fifo_dequeue[fid] = i__dequeue;
    else
        w__fifo_dequeue[fid] = 1'b0;
end // always_comb
end // generate
endgenerate

//------------------------------------------------------------------------------
// Pifo-set signals
//------------------------------------------------------------------------------
always_comb
begin
    w__pifo_push_priority   = i__enqueue_priority;
    w__pifo_push_flow_id    = i__enqueue_flow_id;
    w__pifo_push_valid      = ;     // FIXME

    w__pifo_pop_ready       = i__dequeue;
end

endmodule
