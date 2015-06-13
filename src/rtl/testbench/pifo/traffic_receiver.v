module traffic_receiver (
    clk,
    reset,

    i__config,
    i__receive_phase,
    i__phase_count,

    i__pifo_ready,
    i__packet_pointer,
    i__packet_priority,

    o__dequeue
);

`include "pifo_tb_headers.vh"

//------------------------------------------------------------------------------
// Interface signals
//------------------------------------------------------------------------------
input  logic            clk;
input  logic            reset;
input  TRConfig         i__config;
input  logic            i__receive_phase;
input  CounterSignal    i__phase_count;
input  logic            i__pifo_ready;
input  PacketPointer    i__packet_pointer;
input  Priority         i__packet_priority;
output logic            o__dequeue;

//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------
TRConfig                w__config;
InjectionRate           w__lfsr_ejrate;
CounterSignal           r__num_pkts_recvd__pff;
logic                   w__receive_packet;

//------------------------------------------------------------------------------
// Output signal assignments
//------------------------------------------------------------------------------
assign  o__dequeue      = w__receive_packet;

//------------------------------------------------------------------------------
// Sub-modules 
//------------------------------------------------------------------------------
linear_feedback_shift_register 
#(
    .NUM_BITS           ($bits(EjectionRate))
) lfsr_ejrate (
    .clk                (clk),
    .reset              (reset),
    .i__seed            (w__config.ejrate_seed),
    .i__next            (w__receive_packet),
    .o__value           (w__lfsr_ejrate)
);

//------------------------------------------------------------------------------
// Combinational logic
//------------------------------------------------------------------------------
assign w__config         = i__config;
assign w__receive_packet = i__receive_phase && i__pifo_ready && (w__lfsr_ejrate < w__config.ejrate);

//------------------------------------------------------------------------------
// Sequential logic
//------------------------------------------------------------------------------
always @(posedge clk)
begin
    if (reset)
    	r__num_pkts_recvd__pff <= '0;
    else
    	r__num_pkts_recvd__pff <=  w__receive_packet ? (r__num_pkts_recvd__pff + 1'b1) : r__num_pkts_recvd__pff;
end

endmodule
