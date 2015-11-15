`define     MAX_PACKETS         (200)

package FlowPifoTbPkg;

localparam  MAX_PKTS_PER_PHASE  = `MAX_PACKETS / 10;
localparam  PRIORITY_SEED       = 8'b00000010;      // Number of bits needs to be set based on MAX_PACKET_PRIORITY
localparam  PRIORITY_SEED2      = 8'b01000010;
localparam  PKT_FLOWID_SEED     = 8'b00001100;
localparam  PKT_INJRATE_SEED    = 10'b0010001001;
localparam  PKT_EJRATE_SEED     = 10'b1000100101;
localparam  PKT_RIRATE_SEED     = 10'b1110100100;
localparam  MAX_PACKETS         = `MAX_PACKETS;
localparam  NUM_ELEMENTS        = 4;                // Number of elements in the pifo set
localparam  PKT_INJRATE         = 1023;             // Number of packets per 1024 cycles
localparam  PKT_EJRATE          = 1023;
localparam  PKT_RIRATE          = 512;              // PKT_RIRATE/1024 gives the probability of a
                                                    // dequeued flow being reinserted into the pifo-set
endpackage

package InterfacePkg;
typedef logic [9:0] InjectionRate;
typedef logic [9:0] EjectionRate;
typedef logic [9:0] CounterSignal;
endpackage
