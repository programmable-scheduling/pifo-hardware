module prefetch_buffer (
    //--------------------------------------------------------------------------
    // Global signals
    //--------------------------------------------------------------------------
    clk,
    reset,

    //--------------------------------------------------------------------------
    // Input interface
    //--------------------------------------------------------------------------
    i__push_valid,
    i__push_flow_id,
    i__push_data,                   // For our application, this will be priority
    o__push_flow_not_full,

    i__reinsert_valid,
    i__reinsert_data,

    //--------------------------------------------------------------------------
    // Output interface
    //--------------------------------------------------------------------------
    o__pop_data,
    o__pop_valid,
    i__pop_flow_id,
    i__pop
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter   NUM_FLOWS       = (16);
parameter   DEPTH           = (1);
parameter   DATA_WIDTH      = (8);

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
localparam  IDX_WIDTH       = $clog2(NUM_FLOWS+1);

//------------------------------------------------------------------------------
// Global signals
//------------------------------------------------------------------------------
input  logic                        clk;
input  logic                        reset;

//------------------------------------------------------------------------------
// Input interface
//------------------------------------------------------------------------------
input  logic                        i__push_valid;
input  logic    [IDX_WIDTH-1:0]     i__push_flow_id;
input  logic    [DATA_WIDTH-1:0]    i__push_data;
output logic                        o__push_flow_not_full;

input  logic                        i__reinsert_valid;
input  logic    [DATA_WIDTH-1:0]    i__reinsert_data;

//------------------------------------------------------------------------------
// Output interface
//------------------------------------------------------------------------------
output logic    [DATA_WIDTH-1:0]    o__pop_data;
output logic                        o__pop_valid;
input  logic    [IDX_WIDTH-1:0]     i__pop_flow_id;
input  logic                        i__pop;

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic           [NUM_FLOWS-1:0]     w__fifo_enqueue;
logic           [DATA_WIDTH-1:0]    w__fifo_data_out            [NUM_FLOWS-1:0];
logic           [DATA_WIDTH-1:0]    w__fifo_data_in             [NUM_FLOWS-1:0];
logic           [NUM_FLOWS-1:0]     w__fifo_data_in_ready;
logic           [NUM_FLOWS-1:0]     w__fifo_data_in_ready__next;
logic           [NUM_FLOWS-1:0]     w__fifo_data_out_ready;
logic           [NUM_FLOWS-1:0]     w__fifo_data_out_valid;


//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
genvar flow_idx;
generate for(flow_idx = 0; flow_idx < NUM_FLOWS; flow_idx = flow_idx + 1)
begin: gen_prefetch_fifo
fifo #(
    .BYPASS_ENABLE          (1'b0),
    .DATA_WIDTH             (DATA_WIDTH),
    .MULTI_ISSUE            (1'b1),
    .DEPTH                  (DEPTH)
) prefetch_fifo (
    .clk                    (clk),
    .reset                  (reset),

    .i__data_in_valid       (w__fifo_enqueue[flow_idx]),
    .i__data_in             (w__fifo_data_in[flow_idx]),
    .o__data_in_ready       (w__fifo_data_in_ready[flow_idx]),
    .o__data_in_ready__next (w__fifo_data_in_ready__next[flow_idx]),

    .o__data_out_valid      (w__fifo_data_out_valid[flow_idx]),
    .o__data_out            (w__fifo_data_out[flow_idx]),
    .i__data_out_ready      (w__fifo_data_out_ready[flow_idx])
);
end
endgenerate

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign o__pop_data          = w__fifo_data_out[i__pop_flow_id];
assign o__push_flow_not_full= w__fifo_data_in_ready[i__push_flow_id];
assign o__pop_valid         = w__fifo_data_out_valid[i__pop_flow_id];

//------------------------------------------------------------------------------
// Combinational logic
//------------------------------------------------------------------------------
genvar fid;
generate for(fid = 0; fid < NUM_FLOWS; fid = fid + 1)
begin: gen_flow_fifo
always_comb
begin
    if ( (i__push_valid && (i__push_flow_id == fid)) ||
         (i__reinsert_valid && (i__pop_flow_id == fid)) )
        w__fifo_enqueue[fid]    = 1'b1;
    else
        w__fifo_enqueue[fid]    = 1'b0;
end

always_comb
begin
    if (i__push_valid && (i__push_flow_id == fid))
        w__fifo_data_in[fid]    = i__push_data;
    else if (i__reinsert_valid && (i__pop_flow_id == fid))
        w__fifo_data_in[fid]    = i__reinsert_data;
    else
        w__fifo_data_in[fid]    = '0;
end

always_comb
begin
    if (i__pop && (i__pop_flow_id == fid))
        w__fifo_data_out_ready[fid] = 1'b1;
    else
        w__fifo_data_out_ready[fid] = 1'b0;
end

end
endgenerate



endmodule
