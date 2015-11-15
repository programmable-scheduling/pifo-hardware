package CommonTbPkg;

import FlowPifoPkg::Priority;
import FlowPifoPkg::FlowId;

// ssub: Whichever testbench is using the traffic generator/receiver should
// define an InterfacePkg and set these appropriately.
import InterfacePkg::InjectionRate;
import InterfacePkg::EjectionRate;
import InterfacePkg::CounterSignal;

typedef struct {
    FlowId          flow_id_seed;
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
