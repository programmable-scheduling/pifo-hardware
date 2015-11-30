
// First-word fall-through synchronous FIFO with synchronous reset
module fifo(
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
    i__data_out_ready
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter MULTI_ISSUE   = 1'b0;
parameter BYPASS_ENABLE = 1'b0;
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
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
generate 
if(BYPASS_ENABLE == 1'b0)
begin: no_bypass
    fifo_base
        #(
            .DATA_WIDTH                 (DATA_WIDTH),
            .DEPTH                      (DEPTH),
            .MULTI_ISSUE                (MULTI_ISSUE)
        )
        base(
            .clk                        (clk),
            .reset                      (reset),
    
            .i__data_in_valid           (i__data_in_valid),
            .i__data_in                 (i__data_in),
            .o__data_in_ready           (o__data_in_ready),
            .o__data_in_ready__next     (o__data_in_ready__next),
    
            .o__data_out_valid          (o__data_out_valid),
            .o__data_out                (o__data_out),
            .i__data_out_ready          (i__data_out_ready),
            .oa__all_data               (),
            .i__clear_all               ('0)
        );
end
else
begin: bypass
    fifo_base_bypass
        #(
            .DATA_WIDTH                 (DATA_WIDTH),
            .DEPTH                      (DEPTH),
            .MULTI_ISSUE                (MULTI_ISSUE)
        )
        base (
            .clk                        (clk),
            .reset                      (reset),
        
            .i__data_in_valid           (i__data_in_valid),
            .i__data_in                 (i__data_in),
            .o__data_in_ready           (o__data_in_ready),
            .o__data_in_ready__next     (o__data_in_ready__next),
        
            .o__data_out_valid          (o__data_out_valid),
            .o__data_out                (o__data_out),
            .i__data_out_ready          (i__data_out_ready),
            .oa__all_data               (),
            .i__clear_all               ('0)
        );
end
endgenerate

endmodule

