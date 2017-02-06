`timescale 1ns/10ps
`define C_PERIOD 1000
module cordic_tb();
reg clk, rst, start;
reg [9:0] A0, A1, A2, A3;

wire ready;
wire [11:0] B0, B1, B2, B3, U0, U1, U2, U3, V0, V1, V2, V3;

initial begin
	$dumpfile("cordic_2.fsdb");
	$dumpvars;
	#0
		clk = 1'd0;
		rst = 1'd1;
		start = 1'd0;
	#(`C_PERIOD)
		rst = 1'd0;
		A0 = -10'd4;
		A1 = 10'd8;
		A2 = 10'd12;
		A3 = -10'd16;
	#(`C_PERIOD)
		rst = 1'd1;
	#(`C_PERIOD)
		start = 1'd1;
	#(`C_PERIOD)
		start = 1'd0;
	#(`C_PERIOD*1000)
		$finish;
end
always begin
	#(`C_PERIOD/2) clk = ~clk;
end

cordic cor(clk, rst, start, ready, A0, A1, A2, A3, B0, B1, B2, B3, U0, U1, U2, U3, V0, V1, V2, V3);
endmodule