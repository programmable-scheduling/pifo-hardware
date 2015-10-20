package CommonTbPkg;

// TODO Make this generic to generate any metadata
import FlowPifoPkg::PacketPointer;
import FlowPifoPkg::Priority;

// ssub: Whichever testbench is using the traffic generator/receiver should
// define an InterfacePkg and set these appropriately.
import InterfacePkg::InjectionRate;
import InterfacePkg::EjectionRate;
import InterfacePkg::CounterSignal;

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
