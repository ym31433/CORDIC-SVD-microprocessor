`timescale 1ns/10ps
`define CYCLE  100           	            // Modify your clock period here
//`define SDFFILE    "./CHIP.sdf"	            // Modify your sdf file name       ex:CHIP.sdf
`define IMAGE1     "./data_in.dat"          // Modify your test image file
`define EXPECT_S   "./output_golden_S.dat"  // Modify your output golden file
`define EXPECT_UV  "./output_golden_UV.dat"

`timescale 1ns/10ps

module CHIP_SVD_tb();


parameter DATA_IN_LENGTH = 1;
parameter OUTPUT_LENGTH  = 1;

reg          clk; 
reg          rst;
reg          we;
reg          oe; 
reg   [4:0]  data_i;
reg   [1:0]  element_sel;

wire         ready;
wire  [7:0]  data_o_UV;
wire  [6:0]  data_o_S;

reg   [7:0]  out_mem_S  [0:OUTPUT_LENGTH*8-1];
reg   [7:0]  out_mem_UV [0:OUTPUT_LENGTH*8-1];
reg   [7:0]  image_mem  [0:DATA_IN_LENGTH*8-1];

reg          over;

integer      i, j, out_f;

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

//initial $sdf_annotate(`SDFFILE, svd);
initial $readmemh (`IMAGE1,  image_mem);
initial $readmemh (`EXPECT_S, out_mem_S);
initial $readmemh (`EXPECT_UV, out_mem_UV);

// generate clk
always begin
    #(`CYCLE/2) clk = ~clk;
end

initial begin
    $dumpfile("CHIP.fsdb");
    $dumpvars;
    out_f = $fopen("output.dat");
    if(out_f == 0) begin
         $display("Output file open error hahaha");
         $finish;
    end
end

initial begin
    #0;
    clk         = 1'd1;
    rst         = 1'd1;
    we          = 1'd0;
    over        = 1'd0;
    oe          = 1'd0;
    element_sel = 2'd0;
    //integer
    i           = 0; 
  
    #(`CYCLE) rst = 1'd0;
    #(`CYCLE) rst = 1'd1;
    #(`CYCLE) we  = 1'd1;

    while(i < DATA_IN_LENGTH) begin
        j = 0;
        while(j < 8) begin
            #(`CYCLE);
            if(j == 2) begin
                element_sel = 2'd1;
            end
            else if(j == 4) begin
                element_sel = 2'd2;
            end
            else if(j == 6) begin
                element_sel = 2'd3;
            end
            data_i = image_mem[j + 8*i];
            j = j+1;
        end
        
        #(`CYCLE)
        we = 1'd0;
        element_sel = 1'd0;
        data_i = 5'd0;
                
        @(posedge ready);
        @(posedge clk);
        #(`CYCLE) oe = 1'd1;
        #(`CYCLE);
        
        j = 0;
        while(j < 8) begin
            if(j == 2) begin
                element_sel = 2'd1;
            end
            else if(j == 4) begin
                element_sel = 2'd2;
            end
            else if(j == 6) begin
                element_sel = 2'd3;
            end
            #(0.1*`CYCLE);
            if(data_o_S !== out_mem_S[j + 8*i]) begin
                $display(" S_ERROR at %d:output %h != expect %h ", j + 8*i, data_o_S, out_mem_S[j + 8*i]);
                $fdisplay(out_f,"ERROR at %d:output %h != expect %h ", j + 8*i, data_o_S, out_mem_S[j + 8*i]);
                //$finish;
            end
            if(data_o_UV != out_mem_UV[j + 8*i]) begin
                $display("UV_ERROR at %d:output %h != expect %h ", j + 8*i, data_o_UV, out_mem_UV[j + 8*i]);
                $fdisplay(out_f,"ERROR at %d:output %h !=expect %h ", j + 8*i, data_o_S, out_mem_UV[j + 8*i]);
                //$finish;
            end
            #(0.9*`CYCLE);
            j = j + 1;
        end

        #(`CYCLE)
        oe = 1'b0;
        element_sel = 1'd0;
        #(`CYCLE*2);
        i = i+1;
    end

    $display("---------------------------------------------\n");
    $display("All data have been generated successfully!\n");
    $display("-------------------PASS----------------------\n");
    $finish;      
end

endmodule









