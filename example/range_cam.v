module range_cam (clk, write_0, wr_adr_0, wr_din_0, write_1, wr_adr_1, wr_din_1, search, sr_rng, sr_bmp);

parameter NUMADDR = 1024;
parameter BITADDR = 10;
parameter BITRANG = 8;
parameter WIDTH = 2*BITRANG+1;

input clk;

input write_0;
input [BITADDR-1:0] wr_adr_0;
input [WIDTH-1:0] wr_din_0;
input write_1;
input [BITADDR-1:0] wr_adr_1;
input [WIDTH-1:0] wr_din_1;

input search;
input [BITRANG-1:0] sr_rng;
output [NUMADDR-1:0] sr_bmp;

reg [WIDTH-1:0] mem [0:NUMADDR-1];
always @(posedge clk) begin
  if(write_0)
    mem[wr_adr_0] <= wr_din_0;
  if(write_1)
    mem[wr_adr_1] <= wr_din_1;
end

reg               vld_mem [0:NUMADDR-1];
reg [BITRANG-1:0] min_mem [0:NUMADDR-1];
reg [BITRANG-1:0] max_mem [0:NUMADDR-1];
integer mem_int;
always_comb
  for (mem_int=0; mem_int<NUMADDR; mem_int=mem_int+1) begin
    vld_mem[mem_int] = mem[mem_int][2*BITRANG];
    min_mem[mem_int] = mem[mem_int][2*BITRANG-1:BITRANG];
    max_mem[mem_int] = mem[mem_int][BITRANG-1:0];
  end

reg [BITRANG-1:0] sr_rng_reg;
always @(posedge clk)
  sr_rng_reg <= sr_rng;

reg [NUMADDR-1:0] sr_bmp_tmp;
integer bmp_int;
always_comb
  for (bmp_int=0; bmp_int<NUMADDR; bmp_int=bmp_int+1)
    sr_bmp_tmp[bmp_int] = vld_mem[bmp_int] && (sr_rng_reg>=min_mem[bmp_int]) && (sr_rng_reg<=max_mem[bmp_int]);

reg [NUMADDR-1:0] sr_bmp;
always @(posedge clk)
  sr_bmp <= sr_bmp_tmp;

endmodule

