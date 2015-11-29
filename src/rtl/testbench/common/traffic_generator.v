module traffic_generator (
    clk,
    reset,

    i__config,
    i__generate_phase,
    i__phase_count,
    i__pifo_ready,

    o__packet_flow_id,
    o__packet_priority,
    o__valid_packet_generated,
    o__num_pkts_sent
);

`include "common_tb_headers.vh"

//------------------------------------------------------------------------------
// Interface signals
//------------------------------------------------------------------------------
input  logic            clk;
input  logic            reset;
input  TGConfig         i__config;
input  logic            i__generate_phase;
input  CounterSignal    i__phase_count;
input  logic            i__pifo_ready;

output FlowId           o__packet_flow_id;
output Priority         o__packet_priority;
output logic            o__valid_packet_generated;
output CounterSignal    o__num_pkts_sent;

//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------
TGConfig                w__config;
InjectionRate           w__lfsr_injrate;
FlowId                  w__packet_flow_id;
Priority                w__packet_priority;
logic                   w__generate_packet;

CounterSignal           r__num_pkts_sent__pff;
logic                   r__initial__pff;

//------------------------------------------------------------------------------
// Output signal assignments
//------------------------------------------------------------------------------
assign  o__packet_flow_id           = w__packet_flow_id % NUM_FLOWS;
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
    .i__next            (i__generate_phase),
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
    .NUM_BITS           ($bits(FlowId))
) lfsr_pkt_pointer (
    .clk                (clk),
    .reset              (reset),
    .i__seed            (w__config.flow_id_seed),
    .i__next            (w__generate_packet),
    .o__value           (w__packet_flow_id)
);

//------------------------------------------------------------------------------
// Combinational logic
//------------------------------------------------------------------------------
assign w__config            = i__config;
assign w__generate_packet   = i__generate_phase && i__pifo_ready && (r__num_pkts_sent__pff < w__config.total_packets)
                                && (w__lfsr_injrate < w__config.injrate) && r__initial__pff;
                    
//------------------------------------------------------------------------------
// Sequential logic
//------------------------------------------------------------------------------
always_ff @(posedge clk)
begin
    if (reset)
    begin
    	r__num_pkts_sent__pff   <= '0;
    	r__initial__pff         <= 1'b0;
    end
    else
    begin
    	r__num_pkts_sent__pff   <=  w__generate_packet ? (r__num_pkts_sent__pff + 1'b1) : r__num_pkts_sent__pff;
    	r__initial__pff         <= 1'b1;
    end
end


endmodule
