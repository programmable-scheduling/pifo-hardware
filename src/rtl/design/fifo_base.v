
// First-word fall-through synchronous FIFO with synchronous reset
module fifo_base (
    //--------------------------------------------------------------------------
    // Global signals
    //--------------------------------------------------------------------------
    clk,
    reset,

    //--------------------------------------------------------------------------
    // Input interface
    //--------------------------------------------------------------------------
    i__data_in_valid,
    i__data_in,
    o__data_in_ready,
    o__data_in_ready__next,

    //--------------------------------------------------------------------------
    // Output interface
    //--------------------------------------------------------------------------
    o__data_out_valid,
    o__data_out,
    i__data_out_ready,
    i__clear_all,
    oa__all_data
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter MULTI_ISSUE   = 1'b0;
parameter DATA_WIDTH    = 64;
parameter DEPTH         = 3;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
localparam  ADDR_WIDTH  = $clog2(DEPTH);
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Global signals
//------------------------------------------------------------------------------
input  logic                            clk;
input  logic                            reset;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Input interface
//------------------------------------------------------------------------------
input  logic                            i__data_in_valid;
input  logic [DATA_WIDTH-1:0]           i__data_in;
output logic                            o__data_in_ready;
output logic                            o__data_in_ready__next;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Output interface
//------------------------------------------------------------------------------
output logic                            o__data_out_valid;
output logic [DATA_WIDTH-1:0]           o__data_out;
input  logic                            i__data_out_ready;
input  logic                            i__clear_all;
output logic [DATA_WIDTH-1:0]           oa__all_data            [DEPTH-1:0];
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                                   w__push;
logic                                   w__pop;
logic                                   w__wr_clk;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// States and next signals
//------------------------------------------------------------------------------
logic                                   w__empty__next;
logic                                   r__empty__pff;
logic                                   w__full__next;
logic                                   r__full__pff;

logic        [ADDR_WIDTH-1:0]           w__wr_addr;
logic        [ADDR_WIDTH-1:0]           w__wr_addr_next;
logic        [ADDR_WIDTH-1:0]           w__rd_addr;
logic        [ADDR_WIDTH-1:0]           w__rd_addr_next;

logic        [DATA_WIDTH-1:0]           r__buffer__pff          [DEPTH-1:0];
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign o__data_in_ready         = ~r__full__pff & (~reset);         // When reset, ready should be low
assign o__data_in_ready__next   = ~w__full__next;
assign o__data_out_valid        = ~r__empty__pff;                   // When reset, this _will_ be low
assign o__data_out              = r__buffer__pff[w__rd_addr];

always_comb
begin
    integer i;
    for(i = 0 ; i < DEPTH ; i = i + 1)
    begin
        oa__all_data[i] = r__buffer__pff[i];
    end
end
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Submodules
//------------------------------------------------------------------------------
counter
    #(
        .NUM_COUNT                      (DEPTH),
        .COUNT_WIDTH                    (ADDR_WIDTH)
    )
    m_write_addr (
        .clk                            (clk),
        .reset                          (reset | i__clear_all),
        .i__inc                         (w__push),
        .o__count                       (w__wr_addr),
        .o__count__next                 (w__wr_addr_next)
    );

counter
    #(
        .NUM_COUNT                      (DEPTH),
        .COUNT_WIDTH                    (ADDR_WIDTH)
    )
    m_read_addr (
        .clk                            (clk),
        .reset                          (reset | i__clear_all),
        .i__inc                         (w__pop),
        .o__count                       (w__rd_addr),
        .o__count__next                 (w__rd_addr_next)
    );

clock_gater
    gate_update_clk (
        .clk                            (clk),
        .reset                          (reset),
        .i__enable                      (w__push),
        .o__gated_clk                   (w__wr_clk)
    );
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Internal push and pop signals
//------------------------------------------------------------------------------
generate
if (MULTI_ISSUE == 1'b0)
begin: single_issue_pp
    always_comb
    begin
        w__push = i__data_in_valid && o__data_in_ready;
        w__pop  = o__data_out_valid && i__data_out_ready;
    end
end
else if (MULTI_ISSUE == 1'b1)
begin: multi_issue_pp
    always_comb
    begin
        if (o__data_in_ready)
            w__push = i__data_in_valid;
        else if (~o__data_in_ready && i__data_out_ready)
            w__push = i__data_in_valid;
        else
            w__push = 1'b0;

        w__pop  = o__data_out_valid && i__data_out_ready;
    end
end
endgenerate
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Internal full and empty states
//------------------------------------------------------------------------------
generate
if (MULTI_ISSUE == 1'b0)
begin: single_issue_fe
    always_comb
    begin
        w__empty__next = r__empty__pff;
        if(w__push == 1'b1)
        begin
            w__empty__next = 1'b0;
        end
        else if((w__pop == 1'b1) && (w__rd_addr_next == w__wr_addr))
        begin
            w__empty__next = 1'b1;
        end
    
        w__full__next = r__full__pff;
        if(w__pop == 1'b1)
        begin
            w__full__next = 1'b0;
        end
        else if((w__push == 1'b1) && (w__wr_addr_next == w__rd_addr))
        begin
            w__full__next = 1'b1;
        end
    end
end
else if (MULTI_ISSUE == 1'b1)
begin: multi_issue_fe
    always_comb
    begin
        w__empty__next = r__empty__pff;
        if ((w__push == 1'b1) && (w__pop == 1'b1))
        begin
            if (r__empty__pff)  w__empty__next = 1'b1;
            else                w__empty__next = 1'b0;
        end
        else if(w__push == 1'b1)
        begin
            w__empty__next = 1'b0;
        end
        else if((w__pop == 1'b1) && (w__rd_addr_next == w__wr_addr))
        begin
            w__empty__next = 1'b1;
        end

        w__full__next = r__full__pff;
        if ((w__pop == 1'b1) && (w__push == 1'b1))
        begin
            if (r__full__pff)   w__full__next = 1'b1;
            else                w__full__next = 1'b0;
        end
        else if(w__pop == 1'b1)
        begin
            w__full__next = 1'b0;
        end
        else if((w__push == 1'b1) && (w__wr_addr_next == w__rd_addr))
        begin
            w__full__next = 1'b1;
        end
    end
end
endgenerate

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

//------------------------------------------------------------------------------
// Internal full and empty states
//------------------------------------------------------------------------------
always_ff @ (posedge w__wr_clk)
begin
    if(w__push == 1'b1)
    begin
        r__buffer__pff[w__wr_addr] <= i__data_in;
    end
end
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Parameter checks
//------------------------------------------------------------------------------
// `ifndef SYNTHESIS
// initial
// begin
//     if(DATA_WIDTH < 1)
//     begin
//         $display("[ERROR][fifo] Invalid data width: \"%d\"", DATA_WIDTH);
//         $finish;
//     end
//     if(DEPTH < 2)
//     begin
//         $display("[ERROR][fifo] Invalid depth: \"%d\"", DEPTH);
//         $finish;
//     end
// end
// `endif
//------------------------------------------------------------------------------

endmodule

