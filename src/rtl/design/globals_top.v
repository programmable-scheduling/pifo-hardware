`ifndef SYNTHESIS
timeunit 1ns;
timeprecision 1ps;
`endif

`define MAX(x, y) ((x>=y) ? (x) : (y))

package FlowPifoPkg;

localparam  MAX_PACKET_PRIORITY     =   (255);  // Packet priorities should be in the range [0, MAX_PACKET_PRIORITY] (integers)
localparam  PRIORITY_WIDTH          =   $clog2(MAX_PACKET_PRIORITY+1);  
localparam  PACKET_POINTER_WIDTH    =   (8);
localparam  NUM_FLOWS               =   (4);
localparam  FIFO_DEPTH              =   (10);
localparam  PREFETCH_BUFFER_DEPTH   =   (1);
localparam  FLOW_ID_WIDTH           =   $clog2(NUM_FLOWS+1);

typedef logic [PRIORITY_WIDTH-1:0]          Priority;
typedef logic [FLOW_ID_WIDTH-1:0]           FlowId;


endpackage

