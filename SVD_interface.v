`timescale 1ns/10ps
module SVD_interface(
    clk,
    rst,
    we,
    oe,
    data_i,
    element_sel,
    //output
    ready,
    data_o_UV,
    data_o_S
);

input               clk;
input               rst;
input               we;
input               oe;
input         [1:0] element_sel;

//element of matrix A
input         [4:0] data_i;

//element of matrix U S V 
output              ready;
output        [7:0] data_o_UV;
output        [6:0] data_o_S;

//start signal for cordic
wire   signed [7:0] u0;
wire   signed [7:0] u1;
wire   signed [7:0] u2;
wire   signed [7:0] u3;

wire   signed [13:0] s0;
wire   signed [13:0] s1;
wire   signed [13:0] s2;
wire   signed [13:0] s3;

wire   signed [7:0] v0;
wire   signed [7:0] v1;
wire   signed [7:0] v2;
wire   signed [7:0] v3;

wire                next_start;
wire                next_output_bit_sel;
wire                finish;

reg           [2:0] state;
reg           [2:0] next_state;

reg                 start;
reg                 output_bit_sel;
reg           [2:0] element_cnt;
reg           [2:0] next_element_cnt;

reg    signed [9:0] a0_i;
reg    signed [9:0] a1_i;
reg    signed [9:0] a2_i;
reg    signed [9:0] a3_i;
reg    signed [9:0] next_a0_i;
reg    signed [9:0] next_a1_i;
reg    signed [9:0] next_a2_i;
reg    signed [9:0] next_a3_i;

reg           [7:0] data_o_UV_r;
reg           [6:0] data_o_S_r;

parameter STAND_BY   = 3'd0;
parameter DATA_IN    = 3'd1;
parameter CACULATION = 3'd2;
parameter READY      = 3'd3;
parameter DATA_OUT   = 3'd4;

parameter INPUT_0    = 2'd0;
parameter INPUT_1    = 2'd1;
parameter INPUT_2    = 2'd2;
parameter INPUT_3    = 2'd3;

parameter OUTPUT_0   = 2'd0;
parameter OUTPUT_1   = 2'd1;
parameter OUTPUT_2   = 2'd2;
parameter OUTPUT_3   = 2'd3;

cordic COR(
           clk, rst, start, ready,
           a0_i, a1_i, a2_i, a3_i,
           u0,   u1,   u2,   u3  ,
           s0,   s1,   s2,   s3  ,
           v0,   v1,   v2,   v3
);

assign next_start  = (element_cnt == 3'd3 && next_element_cnt == 3'd4)? 1'd1 : 1'd0;
assign next_output_bit_sel = (state == DATA_OUT || state == DATA_IN)? ~output_bit_sel : 1'd0; 
assign finish = (state == DATA_OUT && element_sel == OUTPUT_3 && output_bit_sel == 1'd1)? 1'd1 : 1'd0;

assign data_o_UV   = data_o_UV_r;
assign data_o_S   = data_o_S_r;

// next_state logic 
always@(*) begin
    case(state)
        STAND_BY:begin
            if(we == 1'd1) next_state = DATA_IN;
            else next_state = STAND_BY;
        end
        DATA_IN:begin
            if(start == 1'd1) next_state = CACULATION;
            else next_state = DATA_IN;
        end
        CACULATION:begin
            if(ready == 1'd1) next_state = READY;
            else next_state = CACULATION;
        end
        READY:begin
            if(oe == 1'd1) next_state = DATA_OUT;
            else next_state = READY;
        end
        DATA_OUT:begin
            if(finish == 1'd1) next_state = STAND_BY;
            else next_state = DATA_OUT;
        end
        default:next_state = state;
    endcase
end

// state logic
always@(*) begin
    next_a0_i        = a0_i;
    next_a1_i        = a1_i;
    next_a2_i        = a2_i;
    next_a3_i        = a3_i;
    next_element_cnt = 3'd0;
    data_o_UV_r      = 8'd0;
    data_o_S_r       = 7'd0;
    case(state)
        DATA_IN:begin
            case(element_sel)
                INPUT_0: begin
                    if(output_bit_sel == 1'd0) begin
                        next_a0_i[4:0] = data_i;
                        next_element_cnt = element_cnt;
                    end
                    else begin
                        next_a0_i[9:5] = data_i;
                        next_element_cnt = element_cnt + 3'd1;
                    end
                end
                INPUT_1:begin
                    if(output_bit_sel == 1'd0) begin
                        next_a1_i[4:0] = data_i;
                        next_element_cnt = element_cnt;
                    end
                    else begin
                        next_a1_i[9:5] = data_i;
                        next_element_cnt = element_cnt + 3'd1;
                    end
                end
                INPUT_2:begin
                    if(output_bit_sel == 1'd0) begin
                        next_a2_i[4:0] = data_i;
                        next_element_cnt = element_cnt;
                    end
                    else begin
                        next_a2_i[9:5] = data_i;
                        next_element_cnt = element_cnt + 3'd1;
                    end
                end
                INPUT_3:begin 
                    if(output_bit_sel == 1'd0) begin
                        next_a3_i[4:0] = data_i;
                        next_element_cnt = element_cnt;
                    end
                    else begin
                        next_a3_i[9:5] = data_i;
                        next_element_cnt = element_cnt + 3'd1;
                    end
                end
            endcase
        end
        DATA_OUT:begin
            case(element_sel)
                OUTPUT_0: begin
                    if(output_bit_sel == 1'd0) begin
                        data_o_UV_r = u0[7:0];
                        data_o_S_r  = s0[6:0];
                    end
                    else begin
                        data_o_UV_r = v0[7:0];
                        data_o_S_r  = s0[13:7];
                    end
                end
                OUTPUT_1: begin
                    if(output_bit_sel == 1'd0) begin
                        data_o_UV_r = u1[7:0];
                        data_o_S_r  = s1[6:0];
                    end
                    else begin
                        data_o_UV_r = v1[7:0];
                        data_o_S_r  = s1[13:7];
                    end
                end
                OUTPUT_2: begin
                    if(output_bit_sel == 1'd0) begin
                        data_o_UV_r = u2[7:0];
                        data_o_S_r  = s2[6:0];
                    end
                    else begin
                        data_o_UV_r = v2[7:0];
                        data_o_S_r  = s2[13:7];
                    end
                end
                OUTPUT_3: begin
                    if(output_bit_sel == 1'd0) begin
                        data_o_UV_r = u3[7:0];
                        data_o_S_r  = s3[6:0];
                    end
                    else begin
                        data_o_UV_r = v3[7:0];
                        data_o_S_r  = s3[13:7];
                    end
                end
            endcase
        end
        default:begin
            next_a0_i        = a0_i;
            next_a1_i        = a1_i;
            next_a2_i        = a2_i;
            next_a3_i        = a3_i;
            next_element_cnt = 3'd0;
            data_o_UV_r      = 8'd0;
            data_o_S_r       = 7'd0;
        end
    endcase
end

always@(posedge clk or negedge rst) begin
	if(!rst) begin
        state          <= STAND_BY;
        start          <= 1'd0;
        element_cnt    <= 3'd0;
        output_bit_sel <= 1'd0;
        a0_i           <= 10'd0;
        a1_i           <= 10'd0;
        a2_i           <= 10'd0;
        a3_i           <= 10'd0;
	end
	else begin
        state          <= next_state;
        start          <= next_start;
        element_cnt    <= next_element_cnt;
        output_bit_sel <= next_output_bit_sel;
        a0_i           <= next_a0_i;
        a1_i           <= next_a1_i;
        a2_i           <= next_a2_i;
        a3_i           <= next_a3_i;
	end
end

endmodule