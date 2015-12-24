module pifo (
  clk, rst,
  pop_0, oprt_0, ovld_0, opri_0, odout_0,
  push_1, uprt_1, upri_1, udin_1,
  push_2, uprt_2, upri_2, udin_2
);

parameter NUMPIFO = 1024;  
parameter BITPORT = 8; 
parameter BITPRIO = 16;
parameter BITDATA = 32;

localparam BITPIFO = $clog2(NUMPIFO);

localparam FLOP_IDX  = 1;

input     clk, rst;

input                pop_0;
input  [BITPORT-1:0] oprt_0;
output               ovld_0;
output [BITPRIO-1:0] opri_0;
output [BITDATA-1:0] odout_0;

input                push_1;
input  [BITPORT-1:0] uprt_1;
input  [BITPRIO-1:0] upri_1;
input  [BITDATA-1:0] udin_1;

input                push_2;
input  [BITPORT-1:0] uprt_2;
input  [BITPRIO-1:0] upri_2;
input  [BITDATA-1:0] udin_2;

wire                pop_0_del;
wire  [BITPORT-1:0] oprt_0_del;
wire                push_1_del;
wire  [BITPORT-1:0] uprt_1_del;
wire  [BITPRIO-1:0] upri_1_del;
wire  [BITDATA-1:0] udin_1_del;
wire                push_2_del;
wire  [BITPORT-1:0] uprt_2_del;
wire  [BITPRIO-1:0] upri_2_del;
wire  [BITDATA-1:0] udin_2_del;
shift #(.BITDATA(1+BITPORT), .DELAY(FLOP_IDX)) pop_fidx_inst (.clk(clk), .din({pop_0,oprt_0}), .dout({pop_0_del,oprt_0_del}));
shift #(.BITDATA(1+BITPORT+BITPRIO+BITDATA), .DELAY(FLOP_IDX)) push_1_fidx_inst (.clk(clk), .din({push_1,uprt_1,upri_1,udin_1}), .dout({push_1_del,uprt_1_del,upri_1_del,udin_1_del}));
shift #(.BITDATA(1+BITPORT+BITPRIO+BITDATA), .DELAY(FLOP_IDX)) push_2_fidx_inst (.clk(clk), .din({push_2,uprt_2,upri_2,udin_2}), .dout({push_2_del,uprt_2_del,upri_2_del,udin_2_del}));

reg [BITDATA-1:0] pf_data [0:NUMPIFO-1];
reg [BITPRIO-1:0] pf_prio [0:NUMPIFO-1];
reg [BITPORT-1:0] pf_port [0:NUMPIFO-1];
reg [BITPIFO  :0] pf_cnt;

reg               pop_0_hit;
reg [BITPIFO-1:0] pop_0_idx;
reg [BITPIFO-1:0] push_1_idx;
reg [BITPIFO-1:0] push_1_idx_raw;
reg [BITPIFO-1:0] push_2_idx;
reg [BITPIFO-1:0] push_2_idx_raw;
reg               push_hi;
reg [BITPIFO-1:0] push_hi_idx;
reg [BITPIFO-1:0] push_hi_idx_raw;
reg [BITPRIO-1:0] push_hi_pri;
reg [BITPORT-1:0] push_hi_prt;
reg               push_lo;
reg [BITPIFO-1:0] push_lo_idx;
reg [BITPIFO-1:0] push_lo_idx_raw;
reg [BITPRIO-1:0] push_lo_pri;
reg [BITPORT-1:0] push_lo_prt;

wire               pop_0_hit_del;
wire [BITPIFO-1:0] pop_0_idx_del;
wire [BITPIFO-1:0] push_1_idx_del;
wire [BITPIFO-1:0] push_2_idx_del;
wire [BITPIFO-1:0] push_1_idx_raw_del;
wire [BITPIFO-1:0] push_2_idx_raw_del;
wire               push_hi_del;
wire [BITPIFO-1:0] push_hi_idx_del;
wire [BITPIFO-1:0] push_hi_idx_raw_del;
wire [BITPRIO-1:0] push_hi_pri_del;
wire [BITPORT-1:0] push_hi_prt_del;
wire               push_lo_del;
wire [BITPIFO-1:0] push_lo_idx_del;
wire [BITPIFO-1:0] push_lo_idx_raw_del;
wire [BITPRIO-1:0] push_lo_pri_del;
wire [BITPORT-1:0] push_lo_prt_del;
shift #(.BITDATA(1+BITPIFO), .DELAY(FLOP_IDX)) pop_idx_del_inst (.clk(clk), .din({pop_0_hit,pop_0_idx}), .dout({pop_0_hit_del,pop_0_idx_del}));
shift #(.BITDATA(2*BITPIFO), .DELAY(FLOP_IDX)) push_idx_del_inst (.clk(clk), .din({push_1_idx, push_2_idx}), .dout({push_1_idx_del,push_2_idx_del}));
shift #(.BITDATA(2*BITPIFO), .DELAY(FLOP_IDX)) push_idx_raw_del_inst (.clk(clk), .din({push_1_idx_raw, push_2_idx_raw}), .dout({push_1_idx_raw_del,push_2_idx_raw_del}));
shift #(.BITDATA(1+BITPIFO+BITPIFO+BITPRIO+BITPORT), .DELAY(FLOP_IDX)) push_hi_del_inst (.clk(clk), .din({push_hi, push_hi_idx, push_hi_idx_raw, push_hi_pri, push_hi_prt}), .dout({push_hi_del,push_hi_idx_del,push_hi_idx_raw_del,push_hi_pri_del, push_hi_prt_del}));
shift #(.BITDATA(1+BITPIFO+BITPIFO+BITPRIO+BITPORT), .DELAY(FLOP_IDX)) push_lo_del_inst (.clk(clk), .din({push_lo, push_lo_idx, push_lo_idx_raw, push_lo_pri, push_lo_prt}), .dout({push_lo_del,push_lo_idx_del,push_lo_idx_raw_del,push_lo_pri_del, push_lo_prt_del}));



reg [BITPIFO-1:0] pop_0_bmp_id;
reg               pop_0_bmp_hit;
pop_pe_idx  #(.NUMPIFO(NUMPIFO), .BITPORT(BITPORT)) pop_idx_inst  (.port(oprt_0), .pf_port(pf_port), .pf_cnt(pf_cnt), .pop_idx(pop_0_bmp_id), .pop_hit(pop_0_bmp_hit));

reg [BITPIFO-1:0] push_1_bmp_id;
push_pe_idx #(.NUMPIFO(NUMPIFO), .BITPRIO(BITPRIO)) push_1_idx_inst (.prio(upri_1), .pf_prio(pf_prio), .pf_cnt(pf_cnt), .push_idx(push_1_bmp_id));

reg [BITPIFO-1:0] push_2_bmp_id;
push_pe_idx #(.NUMPIFO(NUMPIFO), .BITPRIO(BITPRIO)) push_2_idx_inst (.prio(upri_2), .pf_prio(pf_prio), .pf_cnt(pf_cnt), .push_idx(push_2_bmp_id));

reg pop_0_hit_tmp;
reg [BITPIFO-1:0] pop_0_idx_tmp;
always_comb begin
  pop_0_idx = pop_0_bmp_id;
  pop_0_hit_tmp = pop_0_bmp_hit;

  if(pop_0_hit_del && pop_0_idx > pop_0_idx_del)
    pop_0_idx = pop_0_idx -1;

  pop_0_idx_tmp = pop_0_idx;
  pop_0_idx = pop_0_idx + (push_1_del && pop_0_idx_tmp >= push_1_idx_raw_del) + (push_2_del && pop_0_idx_tmp >= push_2_idx_raw_del);

  if(push_hi_del && push_hi_prt_del==oprt_0) begin
    if(!pop_0_hit_tmp || push_hi_idx_raw_del <= pop_0_idx_tmp) begin
      pop_0_idx = push_hi_idx_del;
      pop_0_hit_tmp = 1;
    end
  end
  else if(push_lo_del && push_lo_prt_del==oprt_0 && (!pop_0_hit_tmp || push_lo_idx_raw_del <= pop_0_idx_tmp)) begin
    pop_0_idx = push_lo_idx_del;
    pop_0_hit_tmp = 1;
  end
  pop_0_hit = pop_0 && pop_0_hit_tmp;
end

always_comb begin
  push_1_idx = push_1_bmp_id;
  if(pop_0_hit_del && pop_0_idx_del < push_1_idx)
    push_1_idx = push_1_idx -1;
  push_1_idx = push_1_idx 
              + (push_1_del && (push_1_idx_raw_del < push_1_idx || (push_1_idx_raw_del==push_1_idx && upri_1_del <= upri_1)))
              + (push_2_del && (push_2_idx_raw_del < push_1_idx || (push_2_idx_raw_del==push_1_idx && upri_2_del <= upri_1)));
  if(pop_0_hit && pop_0_idx < push_1_idx)
    push_1_idx = push_1_idx -1;

  push_1_idx_raw = push_1_idx;
  if(push_1 && push_2 && upri_2 < upri_1)
      push_1_idx = push_1_idx+1;
end

always_comb begin
  push_2_idx = push_2_bmp_id;
  if(pop_0_hit_del && pop_0_idx_del < push_2_idx)
    push_2_idx = push_2_idx -1;
  push_2_idx = push_2_idx 
              + (push_1_del && (push_1_idx_raw_del < push_2_idx || (push_1_idx_raw_del==push_2_idx && upri_1_del <= upri_2)))
              + (push_2_del && (push_2_idx_raw_del < push_2_idx || (push_2_idx_raw_del==push_2_idx && upri_2_del <= upri_2)));
  if(pop_0_hit && pop_0_idx < push_2_idx)
    push_2_idx = push_2_idx -1;

  push_2_idx_raw = push_2_idx;
  if(push_1 && push_2 && upri_2 >= upri_1)
      push_2_idx = push_2_idx+1;
end

always_comb begin
  push_hi     = push_1 || push_2;
  push_lo     = push_1 && push_2;
  push_hi_idx = push_1_idx;
  push_lo_idx = push_2_idx;
  push_hi_idx_raw = push_1_idx_raw;
  push_lo_idx_raw = push_2_idx_raw;
  push_hi_pri = upri_1;
  push_lo_pri = upri_2;
  push_hi_prt = uprt_1;
  push_lo_prt = uprt_2;
  if((push_1 && push_2 && upri_2 < upri_1) || !push_1) begin
    push_hi_idx = push_2_idx;
    push_lo_idx = push_1_idx;
    push_hi_idx_raw = push_2_idx_raw;
    push_lo_idx_raw = push_1_idx_raw;
    push_hi_pri = upri_2;
    push_lo_pri = upri_1;
    push_hi_prt = uprt_2;
    push_lo_prt = uprt_1;
  end
end

always @(posedge clk) 
  if(rst)
    pf_cnt <= 0;
  else
    pf_cnt <= pf_cnt - pop_0_hit_del + push_1_del + push_2_del;

assign opri_0  = pf_prio[pop_0_idx_del];
assign odout_0 = pf_data[pop_0_idx_del];
assign ovld_0  = pop_0_hit_del;

reg [NUMPIFO-1:0] pop_shift;
always_comb 
  for(integer i=0; i<NUMPIFO; i=i+1) 
    pop_shift[i] = pop_0_hit_del && (pop_0_idx_del <= i);

reg [BITDATA-1:0] pf_data_nxt [0:NUMPIFO-1];
reg [BITPRIO-1:0] pf_prio_nxt [0:NUMPIFO-1];
reg [BITPORT-1:0] pf_port_nxt [0:NUMPIFO-1];
genvar pv;
generate for(pv=0; pv<NUMPIFO; pv=pv+1) begin : pifo_loop
  wire pu1_set = push_1_del && pv == push_1_idx_del;
  wire pu2_set = push_2_del && pv == push_2_idx_del;
  wire lo_move = push_lo_del && pv > push_lo_idx_del && pv > 1;
  wire hi_move = push_hi_del && pv > push_hi_idx_del && pv > 0;
  wire po_move = pop_shift[pv];
  wire shift_r1 = !pu1_set && !pu2_set && !lo_move && !hi_move && po_move;
  wire shift_l1 = !pu1_set && !pu2_set && ((pv>1 && lo_move && pop_shift[pv-2]) || (pv>0 && !lo_move && hi_move && !pop_shift[pv-1]));
  wire shift_l2 = !pu1_set && !pu2_set && (pv>1 && lo_move && !pop_shift[pv-2]);
  wire shift_no = !pu1_set && !pu2_set && !shift_r1 && !shift_l1 && !shift_l2;
  always_comb begin
    pf_data_nxt[pv] = '0;
    pf_prio_nxt[pv] = '0;
    pf_port_nxt[pv] = '0;
    if(pu1_set) begin
      pf_data_nxt[pv] = pf_data_nxt[pv] | udin_1_del;
      pf_prio_nxt[pv] = pf_prio_nxt[pv] | upri_1_del;
      pf_port_nxt[pv] = pf_port_nxt[pv] | uprt_1_del;
    end
    if(pu2_set) begin
      pf_data_nxt[pv] = pf_data_nxt[pv] | udin_2_del;
      pf_prio_nxt[pv] = pf_prio_nxt[pv] | upri_2_del;
      pf_port_nxt[pv] = pf_port_nxt[pv] | uprt_2_del;
    end
    if(shift_l2 && pv>1) begin
      pf_data_nxt[pv] = pf_data_nxt[pv] | pf_data[pv-2];
      pf_prio_nxt[pv] = pf_prio_nxt[pv] | pf_prio[pv-2];
      pf_port_nxt[pv] = pf_port_nxt[pv] | pf_port[pv-2];
    end
    if(shift_l1 && pv>0) begin
      pf_data_nxt[pv] = pf_data_nxt[pv] | pf_data[pv-1];
      pf_prio_nxt[pv] = pf_prio_nxt[pv] | pf_prio[pv-1];
      pf_port_nxt[pv] = pf_port_nxt[pv] | pf_port[pv-1];
    end
    if(shift_r1 && pv<NUMPIFO-1) begin
      pf_data_nxt[pv] = pf_data_nxt[pv] | pf_data[pv+1];
      pf_prio_nxt[pv] = pf_prio_nxt[pv] | pf_prio[pv+1];
      pf_port_nxt[pv] = pf_port_nxt[pv] | pf_port[pv+1];
    end
    if(shift_no) begin
      pf_data_nxt[pv] = pf_data_nxt[pv] | pf_data[pv];
      pf_prio_nxt[pv] = pf_prio_nxt[pv] | pf_prio[pv];
      pf_port_nxt[pv] = pf_port_nxt[pv] | pf_port[pv];
    end
  end
end
endgenerate

always @(posedge clk) 
  for(integer i=0; i<NUMPIFO; i=i+1) begin
    pf_data[i] <= pf_data_nxt[i];
    pf_prio[i] <= pf_prio_nxt[i];
    pf_port[i] <= pf_port_nxt[i];
  end

endmodule

module shift (
  clk, din, dout
);

parameter BITDATA = 8;
parameter DELAY   = 0;

input                clk;
input  [BITDATA-1:0] din;
output [BITDATA-1:0] dout;

reg [BITDATA-1:0]    din_reg [0:DELAY];

genvar fdel_var;
generate for (fdel_var=0; fdel_var<=DELAY; fdel_var=fdel_var+1) begin: fdel_loop
  if (fdel_var>0) begin: flp_loop
    always @(posedge clk)
      din_reg[fdel_var] <= din_reg[fdel_var-1];
  end else begin: nflp_loop
    always_comb 
      din_reg[fdel_var] = din;
  end
end
endgenerate

assign dout = din_reg[DELAY];

endmodule 

module priority_encode_log (
  decode,
  encode,valid
);

parameter width = 1024;
parameter log_width = 10;

localparam pot_width = 1 << log_width;

input  [width-1:0]     decode;
output [log_width-1:0] encode;
output                 valid;

wire [pot_width-1:0] pot_decode = {pot_width{1'b0}} | decode;

reg [pot_width-1:0] part_idx [0:log_width-1];

always_comb begin
  part_idx[0] = 0;
  for(integer i=0; i<pot_width; i=i+2) begin
    part_idx[0][i] = pot_decode[i] || pot_decode[i+1];
    part_idx[0][i+1] = !pot_decode[i];
  end
end

genvar lvar;
generate for(lvar=1; lvar<log_width; lvar=lvar+1) begin
  always_comb begin
    part_idx[lvar] = 0;
    for(integer i=0; i<pot_width; i=i+(1<<(lvar+1))) begin
      part_idx[lvar][i] = part_idx[lvar-1][i] ||  part_idx[lvar-1][i+(1<<lvar)];
      part_idx[lvar][i+1 +: lvar] = part_idx[lvar-1][i] ? part_idx[lvar-1][i+1 +:lvar] : part_idx[lvar-1][i+(1<<lvar)+1 +:lvar];
      part_idx[lvar][i+1 + lvar] = !part_idx[lvar-1][i];
    end
  end
end
endgenerate

assign valid  = part_idx[log_width-1][0];
assign encode = part_idx[log_width-1][1+:log_width];

endmodule 

module pop_pe_idx (port, pf_port, pf_cnt, pop_idx, pop_hit);
parameter NUMPIFO = 8;
parameter BITPORT = 2;
localparam BITPIFO = $clog2(NUMPIFO);
input  [BITPORT-1:0] port;
input  [BITPORT-1:0] pf_port[0:NUMPIFO-1];
input  [BITPIFO  :0] pf_cnt;
output [BITPIFO-1:0] pop_idx;
output               pop_hit;

reg [NUMPIFO-1:0] pop_bmp;
always_comb
  for(integer i=0; i<NUMPIFO; i=i+1)
    pop_bmp[i] = (i<pf_cnt && pf_port[i]==port);

priority_encode_log #(.width(NUMPIFO), .log_width(BITPIFO)) pop_pe (.decode(pop_bmp), .encode(pop_idx), .valid(pop_hit));
endmodule

module push_pe_idx (prio, pf_prio, pf_cnt, push_idx);
parameter NUMPIFO = 8;
parameter BITPRIO = 4;
localparam BITPIFO = $clog2(NUMPIFO);
input  [BITPRIO-1:0] prio;
input  [BITPRIO-1:0] pf_prio [0:NUMPIFO-1];
input  [BITPIFO  :0] pf_cnt;
output [BITPIFO-1:0] push_idx;

reg [NUMPIFO-1:0] push_bmp;
always_comb
  for(integer i=0; i<NUMPIFO; i=i+1)
    push_bmp[i] = (i==pf_cnt || pf_prio[i]>prio);

priority_encode_log #(.width(NUMPIFO), .log_width(BITPIFO)) push_pe (.decode(push_bmp), .encode(push_idx), .valid());
endmodule
