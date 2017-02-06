`timescale 1ns/10ps
`define CYCLE 20

module SVD_interface_tb();

reg               clk; 
reg               rst;
reg               we;
reg               oe; 
reg         [4:0] data_i;
reg         [1:0] element_sel;

wire              ready;
wire        [7:0] data_o_UV;
wire        [6:0] data_o_S;

SVD_interface svd(
	.clk(clk), 
	.rst(rst),
	.we(we),
	.oe(oe),
	.data_i(data_i),
	.element_sel(element_sel),
	.ready(ready),
	.data_o_UV(data_o_UV),
	.data_o_S(data_o_S)
);

initial begin
	$dumpfile("SVD_interface.fsdb");
	$dumpvars;
end

always begin
    #(`CYCLE/2) clk = ~clk;
end

initial begin
    #0;
    rst              = 1'd1;
    clk              = 1'd1;
    we               = 1'd0;
    oe               = 1'd0;
    data_i           = 10'd0;
    element_sel      = 2'd0; 
	
	#(`CYCLE) rst    = 1'd0;
	#(`CYCLE) rst    = 1'd1;

	#(`CYCLE)
	we               = 1'd1;

    #(`CYCLE) data_i = 5'b011_00; // 43
    #(`CYCLE) data_i = 5'b00101;

    #(`CYCLE) element_sel = 2'd1;
              data_i      = 5'b001_00; // -31
    #(`CYCLE) data_i      = 5'b11100;

    #(`CYCLE) element_sel = 2'd2;
              data_i      = 5'b000_00; // -56
    #(`CYCLE) data_i      = 5'b11001;

    #(`CYCLE) element_sel = 2'd3;
              data_i      = 5'b100_00; // -28
    #(`CYCLE) data_i      = 5'b11100;

    #(`CYCLE) 
    data_i           = 5'd0;
    element_sel      = 2'd0;
    we               = 1'd0;

    #(50*`CYCLE);
    oe               = 1'd1;
    element_sel      = 2'd0;

    #(3*`CYCLE) element_sel      = 2'd1;
    #(2*`CYCLE) element_sel      = 2'd2;
    #(2*`CYCLE) element_sel      = 2'd3;
    #(2*`CYCLE) 
    element_sel      = 2'd0;
    oe               = 1'd0;

    #(20*`CYCLE);

    $finish;
end

endmodule