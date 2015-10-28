module priority_encode_log (
  clk,rst,
  decode,
  encode,valid
);

parameter width = 1024;
parameter log_width = 10;

localparam pot_width = 1 << log_width;

input                  clk;
input                  rst;
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

endmodule // encoder_test
