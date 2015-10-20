module linear_feedback_shift_register(
    clk,
    reset,

    i__seed,

    i__next,
    o__value
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter NUM_BITS                      = 16;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------
input  logic                            clk;
input  logic                            reset;

input  logic [NUM_BITS-1:0]             i__seed;
input  logic                            i__next;
output logic [NUM_BITS-1:0]             o__value;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------
logic [NUM_BITS-1:0]                    w__feedback_poly;
logic [NUM_BITS-1:0]                    w__value__next;
logic [NUM_BITS-1:0]                    r__value__pff;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Get next value
//------------------------------------------------------------------------------
assign o__value = r__value__pff;

always_comb
begin
    w__value__next = r__value__pff;

    if(i__next == 1'b1)
    begin
        w__value__next = (r__value__pff[0] == 1'b1)? ((r__value__pff >> 1) ^ w__feedback_poly) : (r__value__pff >> 1);
    end
end

always_ff @ (posedge clk)
begin
    if(reset == 1'b1)
    begin
        r__value__pff <= i__seed;
    end
    else
    begin
        r__value__pff <= w__value__next;
    end
end
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Feedback polynomials
// http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
//------------------------------------------------------------------------------
generate
if(NUM_BITS == 2)
begin: b2
    assign w__feedback_poly = 2'h3;
end
else if(NUM_BITS == 3)
begin: b3
    assign w__feedback_poly = 3'h6;
end
else if(NUM_BITS == 4)
begin: b4
    assign w__feedback_poly = 4'hC;
end
else if(NUM_BITS == 5)
begin: b5
    assign w__feedback_poly = 5'h14;
end
else if(NUM_BITS == 6)
begin: b6
    assign w__feedback_poly = 6'h30;
end
else if(NUM_BITS == 7)
begin: b7
    assign w__feedback_poly = 7'h60;
end
else if(NUM_BITS == 8)
begin: b8
    assign w__feedback_poly = 8'hB8;
end
else if(NUM_BITS == 9)
begin: b9
    assign w__feedback_poly = 9'h110;
end
else if(NUM_BITS == 10)
begin: b10
    assign w__feedback_poly = 10'h240;
end
else if(NUM_BITS == 11)
begin: b11
    assign w__feedback_poly = 11'h500;
end
else if(NUM_BITS == 12)
begin: b12
    assign w__feedback_poly = 12'h809;
end
else if(NUM_BITS == 13)
begin: b13
    assign w__feedback_poly = 13'h100D;
end
else if(NUM_BITS == 14)
begin: b14
    assign w__feedback_poly = 14'h2015;
end
else if(NUM_BITS == 15)
begin: b15
    assign w__feedback_poly = 15'h6000;
end
else if(NUM_BITS == 16)
begin: b16
    assign w__feedback_poly = 16'hD008;
end
else if(NUM_BITS == 17)
begin: b17
    assign w__feedback_poly = 17'h1_2000;
end
else if(NUM_BITS == 18)
begin: b18
    assign w__feedback_poly = 18'h2_0400;
end
else if(NUM_BITS == 19)
begin: b19
    assign w__feedback_poly = 19'h4_0023;
end
else if(NUM_BITS == 20)
begin: b20
    assign w__feedback_poly = 20'h9_0000;
end
else if(NUM_BITS == 21)
begin: b21
    assign w__feedback_poly = 21'h14_0000;
end
else if(NUM_BITS == 22)
begin: b22
    assign w__feedback_poly = 22'h30_0000;
end
else if(NUM_BITS == 23)
begin: b23
    assign w__feedback_poly = 23'h42_0000;
end
else if(NUM_BITS == 24)
begin: b24
    assign w__feedback_poly = 24'hE1_0000;
end
else if(NUM_BITS == 25)
begin: b25
    assign w__feedback_poly = 25'h120_0000;
end
else if(NUM_BITS == 26)
begin: b26
    assign w__feedback_poly = 26'h200_0023;
end
else if(NUM_BITS == 27)
begin: b27
    assign w__feedback_poly = 27'h400_0013;
end
else if(NUM_BITS == 28)
begin: b28
    assign w__feedback_poly = 28'h900_0000;
end
else if(NUM_BITS == 29)
begin: b29
    assign w__feedback_poly = 29'h1400_0000;
end
else if(NUM_BITS == 30)
begin: b30
    assign w__feedback_poly = 30'h2000_0029;
end
else if(NUM_BITS == 31)
begin: b31
    assign w__feedback_poly = 31'h4800_0000;
end
else if(NUM_BITS == 32)
begin: b32
    assign w__feedback_poly = 32'h8020_0003;
end
else if(NUM_BITS == 33)
begin: b33
    assign w__feedback_poly = 33'h1_0008_0000;
end
else if(NUM_BITS == 34)
begin: b34
    assign w__feedback_poly = 34'h2_0400_0003;
end
else if(NUM_BITS == 35)
begin: b35
    assign w__feedback_poly = 35'h5_0000_0000;
end
else if(NUM_BITS == 36)
begin: b36
    assign w__feedback_poly = 36'h8_0100_0000;
end
else if(NUM_BITS == 37)
begin: b37
    assign w__feedback_poly = 37'h10_0000_001F;
end
else if(NUM_BITS == 38)
begin: b38
    assign w__feedback_poly = 38'h20_0000_0031;
end
else if(NUM_BITS == 39)
begin: b39
    assign w__feedback_poly = 39'h44_0000_0000;
end
else if(NUM_BITS == 40)
begin: b40
    assign w__feedback_poly = 40'hA0_0014_0000;
end
else if(NUM_BITS == 41)
begin: b41
    assign w__feedback_poly = 41'h120_0000_0000;
end
else if(NUM_BITS == 42)
begin: b42
    assign w__feedback_poly = 42'h300_000C_0000;
end
else if(NUM_BITS == 43)
begin: b43
    assign w__feedback_poly = 43'h630_0000_0000;
end
else if(NUM_BITS == 44)
begin: b44
    assign w__feedback_poly = 44'hC00_0003_0000;
end
else if(NUM_BITS == 45)
begin: b45
    assign w__feedback_poly = 45'h1B00_0000_0000;
end
else if(NUM_BITS == 46)
begin: b46
    assign w__feedback_poly = 46'h3000_0300_0000;
end
else if(NUM_BITS == 47)
begin: b47
    assign w__feedback_poly = 47'h4200_0000_0000;
end
else if(NUM_BITS == 48)
begin: b48
    assign w__feedback_poly = 48'hC000_0018_0000;
end
else if(NUM_BITS == 49)
begin: b49
    assign w__feedback_poly = 49'h1_0080_0000_0000;
end
else if(NUM_BITS == 50)
begin: b50
    assign w__feedback_poly = 50'h3_0000_00C0_0000;
end
else if(NUM_BITS == 51)
begin: b51
    assign w__feedback_poly = 51'h6_000C_0000_0000;
end
else if(NUM_BITS == 52)
begin: b52
    assign w__feedback_poly = 52'h9_0000_0000_0000;
end
else
begin: not_supported
    assign w__feedback_poly = 'bx;
end
endgenerate
//------------------------------------------------------------------------------

endmodule

