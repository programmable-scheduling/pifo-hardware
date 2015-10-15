module flow_pifo (
    clk,
    reset,

    i__enqueue,
    i__enqueue_priority,
    i__packet_pointer,
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

input  logic                            i__dequeue;

output Priority                         o__dequeue_priority;
output PacketPointer                    o__packet_pointer;

output logic                            o__pifo_full;
output logic                            o__pifo_empty;

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                                   w__pifo_push_ready;
logic                                   w__pifo_data_out_valid;

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign  o__pifo_full    =   ~w__pifo_push_ready;
assign  o__pifo_empty   =   ~w__pifo_data_out_valid;

//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
pifo_set #(
    .NUM_ELEMENTS           (NUM_FLOWS),
    .MAX_PRIORITY           (MAX_PACKET_PRIORITY),
    .DATA_WIDTH             ($bits(PacketPointer))
) base  (
    .clk                    (clk),
    .reset                  (reset),

    .i__push_valid          (i__enqueue),
    .i__push_priority       (i__enqueue_priority),
    .i__push_data           (i__packet_pointer),
    .o__push_ready          (w__pifo_push_ready),
    .o__push_ready__next    (),
    .i__reinsert_priority   (),

    .o__pop_valid           (w__pifo_data_out_valid),
    .o__pop_priority        (o__dequeue_priority),
    .o__pop_data            (o__packet_pointer),
    .i__pop                 (i__dequeue),
    .i__clear_all           ()
);


endmodule
