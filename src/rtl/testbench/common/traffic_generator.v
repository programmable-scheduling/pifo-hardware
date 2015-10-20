module traffic_generator (
    clk,
    reset,

    i__config,
    i__generate_phase,
    i__phase_count,
    i__pifo_ready,

    o__packet_pointer,
    o__packet_priority,
    o__valid_packet_generated,
    o__num_pkts_sent;
);

`include "pifo_tb_headers.vh"

//------------------------------------------------------------------------------
// Interface signals
//------------------------------------------------------------------------------
input  logic            clk;
input  logic            reset;
input  TGConfig         i__config;
input  logic            i__generate_phase;
input  CounterSignal    i__phase_count;
input  logic            i__pifo_ready;

output PacketPointer    o__packet_pointer;
output Priority         o__packet_priority;
output logic            o__valid_packet_generated;

//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------
TGConfig                w__config;
InjectionRate           w__lfsr_injrate;
PacketPointer           w__packet_pointer;
Priority                w__packet_priority;
logic                   w__generate_packet;

CounterSignal           r__num_pkts_sent__pff;

//------------------------------------------------------------------------------
// Output signal assignments
//------------------------------------------------------------------------------
assign  o__packet_pointer           = w__packet_pointer;
assign  o__packet_priority          = w__packet_priority;
assign  o__valid_packet_generated   = w__generate_packet;
assign  o__num_pkts_sent            = r__num_pkts_sent__pff;

//------------------------------------------------------------------------------
// Sub-modules 
//------------------------------------------------------------------------------
linear_feedback_shift_register 
#(
    .NUM_BITS           ($bits(InjectionRate))
) lfsr_injrate (
    .clk                (clk),
    .reset              (reset),
    .i__seed            (w__config.injrate_seed),
    .i__next            (w__generate_packet),
    .o__value           (w__lfsr_injrate)
);

linear_feedback_shift_register 
#(
    .NUM_BITS           ($bits(Priority))
) lfsr_prio (
    .clk                (clk),
    .reset              (reset),
    .i__seed            (w__config.priority_seed),
    .i__next            (w__generate_packet),
    .o__value           (w__packet_priority)
);

linear_feedback_shift_register 
#(
    .NUM_BITS           ($bits(PacketPointer))
) lfsr_pkt_pointer (
    .clk                (clk),
    .reset              (reset),
    .i__seed            (w__config.pkt_pointer_seed),
    .i__next            (w__generate_packet),
    .o__value           (w__packet_pointer)
);

//------------------------------------------------------------------------------
// Combinational logic
//------------------------------------------------------------------------------
assign w__config            = i__config;
assign w__generate_packet   = i__generate_phase && i__pifo_ready && (r__num_pkts_sent__pff < w__config.total_packets)
                                && (w__lfsr_injrate < w__config.injrate);
                    
//------------------------------------------------------------------------------
// Sequential logic
//------------------------------------------------------------------------------
always_ff @(posedge clk)
begin
    if (reset)
    	r__num_pkts_sent__pff <= '0;
    else
    	r__num_pkts_sent__pff <=  w__generate_packet ? (r__num_pkts_sent__pff + 1'b1) : r__num_pkts_sent__pff;
end


endmodule
