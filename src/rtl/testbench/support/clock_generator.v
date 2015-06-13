
module clock_generator(
    clk,
    clk_delay,
    clk_count
);

parameter HALF_CYCLE                    = 0.5;
parameter SCAN_CLOCK                    = 0;
parameter INIT_VALUE                    = 1'b1;

output logic                            clk;
output logic                            clk_delay;
output integer                          clk_count;

initial
begin
    clk         = INIT_VALUE;
    clk_count   = 0;
end

generate
if(SCAN_CLOCK == 1)
begin: scan_clock
    always
    begin
        if(clk == 1'b1)
        begin
            #(HALF_CYCLE/2);
            clk = 1'b0;
            #(HALF_CYCLE/2);
        end
        else
        begin
            #(HALF_CYCLE);
            clk = 1'b1;
        end
    end
end
else
begin: normal_clock
    always #(HALF_CYCLE)
    begin
        clk = ~clk;
    end
end
endgenerate

always @ (posedge clk)
begin
    clk_count <= clk_count + 1;
end

assign #(HALF_CYCLE-0.01) clk_delay = clk;

endmodule

