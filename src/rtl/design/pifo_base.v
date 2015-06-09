module pifo_base (
    //--------------------------------------------------------------------------
    // Global signals
    //--------------------------------------------------------------------------
    clk,
    reset,

    //--------------------------------------------------------------------------
    // Input interface
    //--------------------------------------------------------------------------
    i__data_in_valid,           // assert true, if you want to enqueue
    i__data_in_priority,
    i__data_in,
    o__data_in_ready,           // true, if pifo is not full: safe to enqueue
    o__data_in_ready__next,     // [ssub]  Remove if unnecessary, but I think it may be useful

    //--------------------------------------------------------------------------
    // Output interface
    //--------------------------------------------------------------------------
    o__data_out_valid,          // true, if pifo is not empty ie. valid packet available for dequeue
    o__data_out_priority,
    o__data_out,
    i__data_out_ready,          // assert true, if you want to dequeue
    i__clear_all                // clear pifo
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter   NUM_ELEMENTS    = (16);
parameter   MAX_PRIORITY    = (256);
parameter   DATA_WIDTH      = (8);

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
localparam  PRIO_WIDTH      = $clog2(MAX_PRIORITY);


//------------------------------------------------------------------------------
// Local data structure
//------------------------------------------------------------------------------
typedef struct {
	logic [DATA_WIDTH-1:0]  data;
	logic [PRIO_WIDTH-1:0]  prio;
} PifoEntry;

//------------------------------------------------------------------------------
// Global signals
//------------------------------------------------------------------------------
input  logic                        clk;
input  logic                        reset;

//------------------------------------------------------------------------------
// Input interface
//------------------------------------------------------------------------------
input  logic                        i__data_in_valid;
input  logic    [PRIO_WIDTH-1:0]    i__data_in_priority;
input  logic    [DATA_WIDTH-1:0]    i__data_in;
output logic                        o__data_in_ready;
output logic                        o__data_in_ready__next;


//------------------------------------------------------------------------------
// Output interface
//------------------------------------------------------------------------------
output logic                        o__data_out_valid;
output logic    [PRIO_WIDTH-1:0]    o__data_out_priority;
output logic    [DATA_WIDTH-1:0]    o__data_out;
input  logic                        i__data_out_ready;
input  logic                        i__clear_all;

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                               w__push;
logic                               w__pop;

//------------------------------------------------------------------------------
// States and next signals
//------------------------------------------------------------------------------
logic                               w__empty__next;
logic                               r__empty__pff;
logic                               w__full__next;
logic                               r__full__pff;

PifoEntry                           r__buffer__pff          [NUM_ELEMENTS-1:0];

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign o__data_in_ready         = ~r__full__pff & (~reset);         // When reset, ready should be low
assign o__data_in_ready__next   = ~w__full__next;
assign o__data_out_valid        = ~r__empty__pff;                   // When reset, this _will_ be low
assign o__data_out              = r__buffer_pff[0].data;
assign o__data_out_priority     = r__buffer_pff[0].prio;


//------------------------------------------------------------------------------
// Submodules
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Internal push and pop signals
//------------------------------------------------------------------------------
always_comb
begin
    // [ssub] For now, we assume upto one of these signals can be true in
    // any particular clock cycle, but not both. Bad things will happen 
    // if this assumption is violated.
    w__push = i__data_in_valid && o__data_in_ready;
    w__pop  = o__data_out_valid && i__data_out_ready;
end

//------------------------------------------------------------------------------
// Internal full and empty states
//------------------------------------------------------------------------------
always_ff @ (posedge clk)
begin
    if(reset == 1'b1)
    begin
        r__empty__pff   <= 1'b1;
        r__full__pff    <= 1'b0;
    end
    else
    begin
        r__empty__pff   <= w__empty__next;
        r__full__pff    <= w__full__next;
    end
end

endmodule
