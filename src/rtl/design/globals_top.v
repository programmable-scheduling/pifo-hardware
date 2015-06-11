`ifndef SYNTHESIS
timeunit 1ns;
timeprecision 1ps;
`endif

`define MAX(x, y) ((x>=y) ? (x) : (y))

package PifoPkg;

localparam  MAX_PACKET_PRIORITY     =   (256);  // Packet priorities should be in the range [0, MAX_PACKET_PRIORITY) (integers)
localparam  PRIORITY_WIDTH          =   $clog2(MAX_PACKET_PRIORITY);  
localparam  PACKET_POINTER_WIDTH    =   (8);
localparam  NUM_ELEMENTS            =   (16);

typedef logic [PACKET_POINTER_WIDTH-1:0]    PacketPointer;

endpackage

