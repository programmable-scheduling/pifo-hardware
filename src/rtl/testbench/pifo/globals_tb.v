`define     MAX_PACKETS         (16)

package PifoTbPkg;

import PifoPkg::PacketPointer;
import PifoPkg::Priority;

localparam  PRIORITY_SEED   = 8'b00000000;
localparam  PKT_POINTER_SEED= 8'b00001100;
localparam  PKT_INJRATE_SEED= 10'b0010001001;
localparam  PKT_EJRATE_SEED = 10'b1000100101;
localparam  MAX_PACKETS     = `MAX_PACKETS;
localparam  PKT_INJRATE     = 1023;         // Number of packets per 1024 cycles
localparam  PKT_EJRATE      = 1023;

typedef logic [9:0] InjectionRate;
typedef logic [9:0] EjectionRate;
typedef logic [9:0] CounterSignal;

typedef struct {
    PacketPointer   pkt_pointer_seed;
    Priority        priority_seed; 
    InjectionRate   injrate_seed;

    InjectionRate   injrate;
    CounterSignal   total_packets;
} TGConfig; 

typedef struct {
	EjectionRate    ejrate_seed;
	EjectionRate    ejrate;
} TRConfig;


endpackage
