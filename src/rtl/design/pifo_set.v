//------------------------------------------------------------------------------
// pifo_set maintains a sorted list of elements, 0 ... NUM_ELEMENTS
// 0 --> highest priority element
// It returns the highest priority element when queried
//
// eg: This is a valid state of the pifo_buffer 
// Index    0   1   2   3   4   5   6   7   8   9
// Priority 237 234 37  23  22  10  x   x   x   x
// In this state, when queried, pifo_buffer[0] (ie. prio 237) will
// be returned.
//
// A popped element may be reinserted with a different priority into
// the pifo-set. i.e 237 may be popped, and re-inserted with a different
// priority.
// 
// The pifo-set effectively supports upto 2 inserts (push) and 1 dequeue (pop)
// in the same cycle (you can have any combination of upto 2 inserts + 1 dequeue).
//------------------------------------------------------------------------------
module pifo_set (
    //--------------------------------------------------------------------------
    // Global signals
    //--------------------------------------------------------------------------
    clk,
    reset,

    //--------------------------------------------------------------------------
    // Input interface
    //--------------------------------------------------------------------------
    i__push_valid,              // assert true, if you want to enqueue
    i__push_priority,
    i__push_flow_id,
    o__push_flow_empty,         // Is the flow-id corresponding to the push flow id
                                // empty currently? 

    o__pifo_set_ready,          // true, if pifo-set is not full: safe to enqueue
    o__pifo_set_ready__next,    // [ssub]  Remove if unnecessary, but I think it may be useful

    i__reinsert_valid,
    i__reinsert_priority,       // we know the popped "index" from the output interface; no need 
                                // to pass it again

    //--------------------------------------------------------------------------
    // Output interface
    //--------------------------------------------------------------------------
    o__pop_valid,               // true, if pifo-set is not empty ie. valid packet available for dequeue
    o__pop_priority,
    o__pop_flow_id,
    i__pop,                     // assert true, if you want to dequeue
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
localparam  IDX_WIDTH       = $clog2(NUM_ELEMENTS+1);


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
input  logic                        i__push_valid;
input  logic    [PRIO_WIDTH-1:0]    i__push_priority;
input  logic    [DATA_WIDTH-1:0]    i__push_flow_id;
output logic                        o__push_flow_empty;
output logic                        o__pifo_set_ready;
output logic                        o__pifo_set_ready__next;
input  logic                        i__reinsert_valid;
input  logic    [PRIO_WIDTH-1:0]    i__reinsert_priority;


//------------------------------------------------------------------------------
// Output interface
//------------------------------------------------------------------------------
output logic                        o__pop_valid;
output logic    [PRIO_WIDTH-1:0]    o__pop_priority;
output logic    [DATA_WIDTH-1:0]    o__pop_flow_id;
input  logic                        i__pop;
input  logic                        i__clear_all;

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                               w__push;
logic                               w__pop;
logic                               w__reinsert;
logic           [IDX_WIDTH-1:0]     w__enq_high_idx; 
logic           [IDX_WIDTH-1:0]     w__enq_low_idx; 
PifoEntry                           w__enq_high_entry;
PifoEntry                           w__enq_low_entry;

logic                               w__pifo_set_ready;
logic                               w__pifo_set_ready__next;
logic                               w__pop_valid;
logic           [DATA_WIDTH-1:0]    w__pop_flow_id;
logic           [PRIO_WIDTH-1:0]    w__pop_priority;

//------------------------------------------------------------------------------
// States and next signals
//------------------------------------------------------------------------------
logic                               w__empty__next;
logic                               r__empty__pff;
logic                               w__full__next;
logic                               r__full__pff;
logic           [IDX_WIDTH-1:0]     r__pifo_count__pff;
logic           [IDX_WIDTH-1:0]     w__pifo_count__next; 

logic           [NUM_ELEMENTS-1:0]  r__valid__pff;
logic           [NUM_ELEMENTS-1:0]  r__valid__next;

PifoEntry                           r__buffer__pff          [NUM_ELEMENTS-1:0];

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign o__pifo_set_ready        =   w__pifo_set_ready; 
assign o__pifo_set_ready__next  =   w__pifo_set_ready__next;
assign o__pop_valid             =   w__pop_valid;
assign o__pop_flow_id           =   w__pop_flow_id;
assign o__pop_priority          =   w__pop_priority;
assign o__push_flow_empty       =   ~r__valid__pff[i__push_flow_id];

//------------------------------------------------------------------------------
// Output signals
//------------------------------------------------------------------------------
always_comb
begin
    w__pifo_set_ready        = ~r__full__pff & (~reset);            // When reset, ready should be low
    w__pifo_set_ready__next  = ~w__full__next;                                                        
    w__pop_valid             = ~r__empty__pff;                      // When reset, this _will_ be low
    w__pop_flow_id           = r__buffer__pff[0].data;
    w__pop_priority          = r__buffer__pff[0].prio;
end

//------------------------------------------------------------------------------
// Internal push and pop signals
//------------------------------------------------------------------------------
always_comb
begin
    // [ssub] All three of these signals can be high in 
    // the same cycle. 
    w__push     = i__push_valid && o__pifo_set_ready;
    w__pop      = o__pop_valid && i__pop;
    w__reinsert = i__reinsert_valid;
end

//------------------------------------------------------------------------------
// Pifo element count 
//------------------------------------------------------------------------------
always_comb
begin
    w__pifo_count__next = r__pifo_count__pff;
    if (reset == 1'b1)
        w__pifo_count__next = '0;
    else if ( (w__push && w__reinsert && w__pop)     || 
         (w__push && ~w__reinsert && ~w__pop)   || 
         (~w__push && w__reinsert && ~w__pop) )
        w__pifo_count__next = r__pifo_count__pff + 1'b1;
    else if ( (w__push && ~w__reinsert && w__pop)   || 
              (~w__push && w__reinsert && w__pop)   || 
              (~w__push && ~w__reinsert && ~w__pop) )
        w__pifo_count__next = r__pifo_count__pff;
    else if (w__push && w__reinsert && ~w__pop)
        w__pifo_count__next = r__pifo_count__pff + 2'b10;   // add 2
    else if (~w__push && ~w__reinsert && w__pop)
        w__pifo_count__next = r__pifo_count__pff - 1'b1;
end

always_ff @(posedge clk)
begin
    if ((reset == 1'b1) || (i__clear_all == 1'b1))
    	r__pifo_count__pff <= '0;
    else
        r__pifo_count__pff <= w__pifo_count__next;
end


//------------------------------------------------------------------------------
// Internal full and empty states, signals
//------------------------------------------------------------------------------
always_comb
begin
    w__empty__next  = (w__pifo_count__next == '0);
    w__full__next   = (w__pifo_count__next == NUM_ELEMENTS);
end

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

//------------------------------------------------------------------------------
// Internal valid signals for each flow
//------------------------------------------------------------------------------
genvar flow_idx;
generate for(flow_idx = 0; flow_idx < NUM_ELEMENTS; flow_idx = flow_idx + 1) 
begin: gen_valid_flow 
    always_comb
    begin
        // [ssub] You cannot compute i__push_valid or i__reinsert_valid
        // based on r__valid__next[flow_idx] signal. It will lead to a 
        // combinational loop. Be cognizant of this.
        if ( (i__push_valid && (i__push_flow_id == flow_idx)) ||
             (i__reinsert_valid && (w__pop_flow_id == flow_idx)) )
            r__valid__next[flow_idx]    = 1'b1;
        else
            r__valid__next[flow_idx]    = r__valid__pff[flow_idx];
    end
    
    always_ff @(posedge clk)
    begin
        if (reset == 1'b1)
            r__valid__pff[flow_idx] <= 1'b0;
        else
            r__valid__pff[flow_idx] <= r__valid__next[flow_idx];
    end
end
endgenerate

//------------------------------------------------------------------------------
// Pifo next state : Core PIFO logic
//------------------------------------------------------------------------------
// Pick higher and lower entry
always_comb
begin
    w__enq_high_entry.prio = '0;
    w__enq_high_entry.data = '0;
    w__enq_low_entry.prio  = '0;
    w__enq_low_entry.data  = '0;

    if (w__push && w__reinsert)
    begin
        if (i__push_priority > i__reinsert_priority)
        begin
            w__enq_high_entry.prio  = i__push_priority;
            w__enq_high_entry.data  = i__push_flow_id;
            w__enq_low_entry.prio   = i__reinsert_priority;
            w__enq_low_entry.data   = r__buffer__pff[0].data;   // TODO Check if this needs to be refetched
        end
        else
        begin
            w__enq_low_entry.prio   = i__push_priority;
            w__enq_low_entry.data   = i__push_flow_id;
            w__enq_high_entry.prio  = i__reinsert_priority;
            w__enq_high_entry.data  = r__buffer__pff[0].data;   // TODO Check if this needs to be refetched
        end
    end
    else if (w__push && ~w__reinsert)
    begin
        w__enq_high_entry.prio = i__push_priority;
        w__enq_high_entry.data = i__push_flow_id;
    end
    else if (~w__push && w__reinsert)
    begin
        w__enq_high_entry.prio = i__reinsert_priority;
        w__enq_high_entry.data = r__buffer__pff[0].data;        // FIXME Check if this needs to be refetched
    end
end

// Enqueue indices computation
integer idx1;
always_comb
begin
    if (w__enq_high_entry.prio > r__buffer__pff[0].prio)
    begin
    	w__enq_high_idx = w__pop ? 1'b1 : '0;
    end
    else
    begin
        w__enq_high_idx = r__pifo_count__pff;
        for(idx1 = 0; idx1 < NUM_ELEMENTS; idx1 = idx1 + 1)
        	if ((idx1 < r__pifo_count__pff) && (w__enq_high_entry.prio < r__buffer__pff[idx1].prio))
        		w__enq_high_idx = idx1;
        w__enq_high_idx = w__enq_high_idx + 1'b1;
    end
end

integer idx2;
always_comb
begin
    // By construction w__enq_high_idx >= w__enq_low_idx
    if (w__enq_low_entry.prio > r__buffer__pff[0].prio)
    begin
    	w__enq_low_idx = w__pop ? 1'b1 : '0;
    end
    else
    begin
        w__enq_low_idx = r__pifo_count__pff;
        for(idx2 = 0; idx2 < NUM_ELEMENTS; idx2 = idx2 + 1)
        	if ((idx2 < r__pifo_count__pff) && (w__enq_low_entry.prio < r__buffer__pff[idx2].prio))
        		w__enq_low_idx = idx2;
        w__enq_low_idx = w__enq_low_idx + 1'b1;
    end
end


// Next state 
genvar pifo_idx;
generate for(pifo_idx = 0; pifo_idx < NUM_ELEMENTS; pifo_idx = pifo_idx + 1) 
begin: gen_pifo_next_state
    PifoEntry   r__buffer__next;
    PifoEntry   w__buffer_shift;
    PifoEntry   w__buffer_noshift;

    // In event of a dequeue, we have to left shift elements. I use the 
    // shorthand shift for denoting this. In addition to the left shift
    // we may have to right shift some elements. 
    // Note that this logic works correctly, even if (w__enq_high_idx == w__enq_low_idx)
    // i.e. we want to insert the two items one after the other.
    always_comb
    begin
        w__buffer_shift = r__buffer__pff[pifo_idx];
        if (pifo_idx < (w__enq_high_idx-1))                         // must also be less than w__enq_low_idx
            w__buffer_shift = r__buffer__pff[pifo_idx+1];
        else if (pifo_idx == (w__enq_high_idx-1))
            w__buffer_shift = w__enq_high_entry;
        else if ((pifo_idx >= w__enq_high_idx) && (pifo_idx < w__enq_low_idx))
            w__buffer_shift = r__buffer__pff[pifo_idx];
        else if (pifo_idx == w__enq_low_idx)
            w__buffer_shift = w__enq_low_entry;
        else if (pifo_idx > w__enq_low_idx)
            w__buffer_shift = r__buffer__pff[pifo_idx - 1];
    end

    // In event of no pop (dequeue), we do not have to left-shift elements (hence the shorthand
    // noshift). We still may have to shift elements to the right if we have a push. 
    always_comb
    begin
        w__buffer_noshift = r__buffer__pff[pifo_idx];
        // Strictly we should have atmost w__enq_high_idx 
        // No pop => No reinsert; So only if there is a push will there 
        // be a change in state
        if (pifo_idx == w__enq_high_idx)
            w__buffer_noshift = w__enq_high_entry;
        else if (pifo_idx > w__enq_high_idx)
            w__buffer_noshift = r__buffer__pff[pifo_idx-1];
    end

    always_comb
    begin
        if (w__pop)
            r__buffer__next = w__buffer_shift;
        else
            r__buffer__next = w__buffer_noshift;
    end

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
        	r__buffer__pff[pifo_idx].data   <= '0;
        	r__buffer__pff[pifo_idx].prio   <= '0;
        end
        else
            r__buffer__pff[pifo_idx]    <= r__buffer__next;
    end
end
endgenerate

endmodule
