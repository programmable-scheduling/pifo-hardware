
// First-word fall-through synchronous FIFO with synchronous reset
module fifo_base_bypass(
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
output logic [DATA_WIDTH-1:0]           oa__all_data            [0:DEPTH-1];
//------------------------------------------------------------------------------

// Wires
logic                                   w__data_in_valid;
logic [DATA_WIDTH-1:0]                  w__data_in;
logic                                   w__data_in_ready;
logic                                   w__data_in_ready__next;
logic                                   w__data_out_valid;
logic [DATA_WIDTH-1:0]                  w__data_out;
logic                                   w__data_out_ready;


//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
fifo_base
    #(
        .DATA_WIDTH                     (DATA_WIDTH),
        .DEPTH                          (DEPTH),
        .MULTI_ISSUE                    (MULTI_ISSUE)
    )
    base (
        .clk                            (clk),
        .reset                          (reset),

        .i__data_in_valid               (w__data_in_valid),
        .i__data_in                     (w__data_in),
        .o__data_in_ready               (w__data_in_ready),
        .o__data_in_ready__next         (w__data_in_ready__next),

        .o__data_out_valid              (w__data_out_valid),
        .o__data_out                    (w__data_out),
        .i__data_out_ready              (w__data_out_ready),
        .oa__all_data                   (oa__all_data),
        .i__clear_all                   (i__clear_all)
    );
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// FIFO base input interface logic
//------------------------------------------------------------------------------
always_comb
begin
    w__data_in_valid    = i__data_in_valid;
    w__data_in          = i__data_in;

    if(w__data_out_valid == 1'b0)
    begin
        // FIFO base is empty
        if((i__data_in_valid == 1'b1) && (i__data_out_ready == 1'b1))
        begin
            // If there is a valid incoming data and it is popped out in the same cycle
            //  - Deassert the data in valid bit so that nothing is inserted into the FIFO
            w__data_in_valid = 1'b0;
        end
    end
end

always_comb
begin
    o__data_in_ready        = w__data_in_ready;
    o__data_in_ready__next  = w__data_in_ready__next;
end
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// FIFO base output interface logic
//------------------------------------------------------------------------------
always_comb
begin
    o__data_out_valid   = w__data_out_valid;
    o__data_out         = w__data_out;

    if((w__data_out_valid == 1'b0) && (reset == 1'b0))
    begin
        // FIFO base is empty and not in reset phase
        if(i__data_in_valid == 1'b1)
        begin
            // If there is a valid incoming data
            //  - Assert data out valid bit
            //  - Forward the incoming data to the output
            o__data_out_valid   = 1'b1;
            o__data_out         = i__data_in;
        end
    end
end

always_comb
begin
    // The FIFO base ignores the ready signal if there is no element in the FIFO
    // so it is valid to pass ready signal directly to the FIFO base without any 
    // condition
    w__data_out_ready = i__data_out_ready;
end
//------------------------------------------------------------------------------

endmodule

