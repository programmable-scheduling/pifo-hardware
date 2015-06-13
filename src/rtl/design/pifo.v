module pifo (
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
logic                                   w__pifo_data_in_ready;
logic                                   w__pifo_data_out_valid;

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign  o__pifo_full    =   ~w__pifo_data_in_ready;
assign  o__pifo_empty   =   ~w__pifo_data_out_valid;

//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
pifo_base #(
    .NUM_ELEMENTS           (NUM_ELEMENTS),
    .MAX_PRIORITY           (MAX_PACKET_PRIORITY),
    .DATA_WIDTH             ($bits(PacketPointer))
) base  (
    .clk                    (clk),
    .reset                  (reset),

    .i__data_in_valid       (i__enqueue),
    .i__data_in_priority    (i__enqueue_priority),
    .i__data_in             (i__packet_pointer),
    .o__data_in_ready       (w__pifo_data_in_ready),
    .o__data_in_ready__next (),

    .o__data_out_valid      (w__pifo_data_out_valid),
    .o__data_out_priority   (o__dequeue_priority),
    .o__data_out            (o__packet_pointer),
    .i__data_out_ready      (i__dequeue),
    .i__clear_all           ()
);


endmodule
