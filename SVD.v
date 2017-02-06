`timescale 1ns/10ps
module SVD (
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

input                clk;
input                rst;
input                we;
input                oe;
input         [1:0]  element_sel;

//element of matrix A
input         [4:0]  data_i;

//element of matrix U S V 
output reg           ready;
output        [7:0]  data_o_UV;
output        [6:0]  data_o_S;

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

wire                 next_start;
wire                 next_output_bit_sel;
wire                 finish;

reg           [2:0]  state;
reg           [2:0]  next_state;

reg                  start;
reg                  output_bit_sel;
reg           [2:0]  element_cnt;
reg           [2:0]  next_element_cnt;

reg    signed [9:0]  a0_i;
reg    signed [9:0]  a1_i;
reg    signed [9:0]  a2_i;
reg    signed [9:0]  a3_i;
reg    signed [9:0]  next_a0_i;
reg    signed [9:0]  next_a1_i;
reg    signed [9:0]  next_a2_i;
reg    signed [9:0]  next_a3_i;

reg           [7:0]  data_o_UV_r;
reg           [6:0]  data_o_S_r;

// cordic variable

wire   signed [13:0] S0, S1, S2, S3;        //S: 8 integer, 5 fragment
wire   signed [7:0]  U0, U1, U2, U3;
wire   signed [7:0]  V0, V1, V2, V3;

reg    signed [10:0] U[0:1][0:1],           //1 sign, 1 integer, 9 fragment
                     U_next[0:1][0:1],
                     V[0:1][0:1],
                     V_next[0:1][0:1];
reg    signed [17:0] S[0:1][0:1],           //1 sign, 8 integer, 9 fragment
                     S_next[0:1][0:1];

reg                  uv_count;
wire                 uv_count_next;
reg           [3:0]  i_count;
wire          [3:0]  i_count_next;
reg                  ref_count;
wire                 ref_count_next;
reg           [1:0]  state_c, 
                     state_c_next;

reg    signed [26:0] temp_S[0:1][0:1];
reg    signed [19:0] temp_U[0:1][0:1],
                     temp_V[0:1][0:1];

parameter UV_COUNT  = 1'd1;
parameter I_COUNT   = 4'd9;
parameter REF_COUNT = 1'd1;

parameter WAIT      = 2'd0;
parameter ROTATE    = 2'd1;
parameter MULTIPLY  = 2'd2;
parameter REFLECT   = 2'd3;

wire signed [17:0] KS  = 18'b0_0000_0000_010_111_100;
wire signed [10:0] KUV = 11'b0_0_100_110_101;

integer i, j;

//================================= SVD interface =================================

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
                        data_o_UV_r = U0[7:0];
                        data_o_S_r  = S0[6:0];
                    end
                    else begin
                        data_o_UV_r = V0[7:0];
                        data_o_S_r  = S0[13:7];
                    end
                end
                OUTPUT_1: begin
                    if(output_bit_sel == 1'd0) begin
                        data_o_UV_r = U1[7:0];
                        data_o_S_r  = S1[6:0];
                    end
                    else begin
                        data_o_UV_r = V1[7:0];
                        data_o_S_r  = S1[13:7];
                    end
                end
                OUTPUT_2: begin
                    if(output_bit_sel == 1'd0) begin
                        data_o_UV_r = U2[7:0];
                        data_o_S_r  = S2[6:0];
                    end
                    else begin
                        data_o_UV_r = V2[7:0];
                        data_o_S_r  = S2[13:7];
                    end
                end
                OUTPUT_3: begin
                    if(output_bit_sel == 1'd0) begin
                        data_o_UV_r = U3[7:0];
                        data_o_S_r  = S3[6:0];
                    end
                    else begin
                        data_o_UV_r = V3[7:0];
                        data_o_S_r  = S3[13:7];
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


//================================= cordic calculation =================================

assign uv_count_next  = (state_c == WAIT)? 1'd0: uv_count + 1'b1;
assign i_count_next   = (start == 1'd1 || (uv_count == UV_COUNT && i_count == I_COUNT))? 
                            4'd0: (uv_count == UV_COUNT)? i_count + 4'd1: i_count;
assign ref_count_next = (state_c == MULTIPLY && state_c_next == REFLECT)? 1'd0: ~ref_count;
assign ready_next = (start == 1'd1)? 1'd0: (state_c == REFLECT && ref_count == REF_COUNT)? 1'd1: ready;

assign S0 = S[0][0] >>> 4;
assign S1 = S[0][1] >>> 4;
assign S2 = S[1][0] >>> 4;
assign S3 = S[1][1] >>> 4;

assign U0 = U[0][0] >>> 3;
assign U1 = U[0][1] >>> 3;
assign U2 = U[1][0] >>> 3;
assign U3 = U[1][1] >>> 3;

assign V0 = V[0][0] >>> 3;
assign V1 = V[0][1] >>> 3;
assign V2 = V[1][0] >>> 3;
assign V3 = V[1][1] >>> 3;

// calculation state
always@(*) begin
    state_c_next = state_c;
    case(state_c)
        WAIT:     if(start == 1'd1) state_c_next = ROTATE;
        ROTATE:   if(uv_count == UV_COUNT && i_count == I_COUNT) state_c_next = MULTIPLY;
        MULTIPLY: state_c_next = REFLECT;
        REFLECT:  if(ref_count == REF_COUNT) state_c_next = WAIT;
    endcase
end

always@(*) begin
    S_next[0][0] = S[0][0];
    S_next[0][1] = S[0][1];
    S_next[1][0] = S[1][0];
    S_next[1][1] = S[1][1];

    U_next[0][0] = U[0][0];
    U_next[0][1] = U[0][1];
    U_next[1][0] = U[1][0];
    U_next[1][1] = U[1][1];

    V_next[0][0] = V[0][0];
    V_next[0][1] = V[0][1];
    V_next[1][0] = V[1][0];
    V_next[1][1] = V[1][1];

    case(state_c)
        WAIT: begin
            if(start == 1'd1) begin
                S_next[0][0] = $signed({ {2{a0_i[9]}}, a0_i[8:0], 7'b0 });
                S_next[0][1] = $signed({ {2{a1_i[9]}}, a1_i[8:0], 7'b0 });
                S_next[1][0] = $signed({ {2{a2_i[9]}}, a2_i[8:0], 7'b0 });
                S_next[1][1] = $signed({ {2{a3_i[9]}}, a3_i[8:0], 7'b0 });

                U_next[0][0] = 11'd512;
                U_next[0][1] = 11'd0;
                U_next[1][0] = 11'd0;
                U_next[1][1] = 11'd512;

                V_next[0][0] = 11'd512;
                V_next[0][1] = 11'd0;
                V_next[1][0] = 11'd0;
                V_next[1][1] = 11'd512;
            end
        end
        ROTATE: begin
            if(uv_count == 1'd0 && S[1][0] != $signed(18'd0)) begin // left rotation, U
                if(S[0][0][17] ^ S[1][0][17]) begin
                    S_next[0][0] = S[0][0] - (S[1][0] >>> i_count);
                    S_next[1][0] = S[1][0] + (S[0][0] >>> i_count);
                    S_next[0][1] = S[0][1] - (S[1][1] >>> i_count);
                    S_next[1][1] = S[1][1] + (S[0][1] >>> i_count);
    
                    U_next[0][0] = U[0][0] - (U[0][1] >>> i_count);
                    U_next[0][1] = U[0][1] + (U[0][0] >>> i_count);
                    U_next[1][0] = U[1][0] - (U[1][1] >>> i_count);
                    U_next[1][1] = U[1][1] + (U[1][0] >>> i_count);
                end
                else begin
                    S_next[0][0] = S[0][0] + (S[1][0] >>> i_count);
                    S_next[1][0] = S[1][0] - (S[0][0] >>> i_count);
                    S_next[0][1] = S[0][1] + (S[1][1] >>> i_count);
                    S_next[1][1] = S[1][1] - (S[0][1] >>> i_count);
                    
                    U_next[0][0] = U[0][0] + (U[0][1] >>> i_count);
                    U_next[0][1] = U[0][1] - (U[0][0] >>> i_count);
                    U_next[1][0] = U[1][0] + (U[1][1] >>> i_count);
                    U_next[1][1] = U[1][1] - (U[1][0] >>> i_count);
                end
            end
            else if(uv_count == 1'd1 && S[0][1] != $signed(18'd0))begin
                if(S[0][0][17] ^ S[0][1][17]) begin // right rotation V
                    S_next[0][0] = S[0][0] - (S[0][1] >>> i_count);
                    S_next[0][1] = S[0][1] + (S[0][0] >>> i_count);
                    S_next[1][0] = S[1][0] - (S[1][1] >>> i_count);
                    S_next[1][1] = S[1][1] + (S[1][0] >>> i_count);
    
                    V_next[0][0] = V[0][0] - (V[0][1] >>> i_count);
                    V_next[0][1] = V[0][1] + (V[0][0] >>> i_count);
                    V_next[1][0] = V[1][0] - (V[1][1] >>> i_count);
                    V_next[1][1] = V[1][1] + (V[1][0] >>> i_count);
                end
                else begin
                    S_next[0][0] = S[0][0] + (S[0][1] >>> i_count);
                    S_next[0][1] = S[0][1] - (S[0][0] >>> i_count);
                    S_next[1][0] = S[1][0] + (S[1][1] >>> i_count);
                    S_next[1][1] = S[1][1] - (S[1][0] >>> i_count);
                    
                    V_next[0][0] = V[0][0] + (V[0][1] >>> i_count);
                    V_next[0][1] = V[0][1] - (V[0][0] >>> i_count);
                    V_next[1][0] = V[1][0] + (V[1][1] >>> i_count);
                    V_next[1][1] = V[1][1] - (V[1][0] >>> i_count);
                end
            end
        end
        MULTIPLY: begin
            temp_S[0][0] = KS * S[0][0];
            temp_S[0][1] = KS * S[0][1];
            temp_S[1][0] = KS * S[1][0];
            temp_S[1][1] = KS * S[1][1];

            temp_U[0][0] = KUV * U[0][0];
            temp_U[0][1] = KUV * U[0][1];
            temp_U[1][0] = KUV * U[1][0];
            temp_U[1][1] = KUV * U[1][1];

            temp_V[0][0] = KUV * V[0][0];
            temp_V[0][1] = KUV * V[0][1];
            temp_V[1][0] = KUV * V[1][0];
            temp_V[1][1] = KUV * V[1][1];

            S_next[0][0] = temp_S[0][0] >>> 9;//3;
            S_next[0][1] = temp_S[0][1] >>> 9;//3;
            S_next[1][0] = temp_S[1][0] >>> 9;//3;
            S_next[1][1] = temp_S[1][1] >>> 9;//3;

            U_next[0][0] = temp_U[0][0] >>> 9;//3;
            U_next[0][1] = temp_U[0][1] >>> 9;//3;
            U_next[1][0] = temp_U[1][0] >>> 9;//3;
            U_next[1][1] = temp_U[1][1] >>> 9;//3;

            V_next[0][0] = temp_V[0][0] >>> 9;//3;
            V_next[0][1] = temp_V[0][1] >>> 9;//3;
            V_next[1][0] = temp_V[1][0] >>> 9;//3;
            V_next[1][1] = temp_V[1][1] >>> 9;//3;
        end
        REFLECT: begin
            if(S[ref_count][ref_count][17] == 1'd1) begin
                S_next[0][ref_count] = $signed(~S[0][ref_count] + 18'd1);
                S_next[1][ref_count] = $signed(~S[1][ref_count] + 18'd1);
                V_next[0][ref_count] = $signed(~V[0][ref_count] + 11'd1);
                V_next[1][ref_count] = $signed(~V[1][ref_count] + 11'd1);
            end
        end
    endcase

end

always@(posedge clk or negedge rst) begin
	if(!rst) begin
        state           <= STAND_BY;
        start           <= 1'd0;
        element_cnt     <= 3'd0;
        output_bit_sel  <= 1'd0;
        a0_i            <= 10'd0;
        a1_i            <= 10'd0;
        a2_i            <= 10'd0;
        a3_i            <= 10'd0;
        //cordic
        for(i = 0; i != 2; i = i + 1) begin
            for(j = 0; j != 2; j = j + 1) begin
                S[i][j] <= 18'd0;
                U[i][j] <= 11'd0;
                V[i][j] <= 11'd0;
            end
        end
        ready           <= 1'd1;
        uv_count        <= 1'd0;
        i_count         <= 4'd0;
        ref_count       <= 1'd0;
        state_c         <= WAIT;
	end
	else begin
        state           <= next_state;
        start           <= next_start;
        element_cnt     <= next_element_cnt;
        output_bit_sel  <= next_output_bit_sel;
        a0_i            <= next_a0_i;
        a1_i            <= next_a1_i;
        a2_i            <= next_a2_i;
        a3_i            <= next_a3_i;
        //cordic
        for(i = 0; i != 2; i = i + 1) begin
            for(j = 0; j != 2; j = j + 1) begin
                S[i][j] <= S_next[i][j];
                U[i][j] <= U_next[i][j];
                V[i][j] <= V_next[i][j];
            end
        end
        ready           <= ready_next;
        uv_count        <= uv_count_next;
        i_count         <= i_count_next;
        ref_count       <= ref_count_next;
        state_c         <= state_c_next;
	end
end

endmodule