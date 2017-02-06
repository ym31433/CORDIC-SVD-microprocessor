`timescale 1ns/10ps
module cordic(
	clk, 
	rst, 
	start,
	ready,
	A0, A1, A2, A3,
	U0, U1, U2, U3,
	S0, S1, S2, S3,  
	V0, V1, V2, V3
);

input                clk, rst, start;
input  signed [9:0]  A0, A1, A2, A3; //7 integer, 2 fragment

output reg           ready;
wire                 ready_next;

output signed [13:0] S0, S1, S2, S3;  //S: 8 integer, 5 fragment
output signed [7:0]  U0, U1, U2, U3, V0, V1, V2, V3; // UV: 1 integer, 6 fragment
reg    signed [10:0] U[0:1][0:1],           //1 sign, 1 integer, 9 fragment
				     U_next[0:1][0:1],
				     V[0:1][0:1],
				     V_next[0:1][0:1];
reg    signed [17:0] S[0:1][0:1],           //1 sign, 8 integer, 9 fragment
				     S_next[0:1][0:1];

reg                  uv_count;
wire                 uv_count_next;
reg    		  [3:0]  i_count;
wire   		  [3:0]  i_count_next;
reg                  ref_count;
wire                 ref_count_next;
reg           [1:0]  state, 
                     state_next;

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

assign uv_count_next  = (state == WAIT)? 1'd0: ~uv_count;
assign i_count_next   = (start == 1'd1 || (uv_count == UV_COUNT && i_count == I_COUNT))? 
                            4'd0: (uv_count == UV_COUNT)? i_count + 4'd1: i_count;
assign ref_count_next = (state == MULTIPLY && state_next == REFLECT)? 1'd0: ~ref_count;
assign ready_next = (start == 1'd1)? 1'd0: (state == REFLECT && ref_count == REF_COUNT)? 1'd1: ready;

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
	state_next = state;
	case(state)
		WAIT:     if(start == 1'd1) state_next = ROTATE;
		ROTATE:   if(uv_count == UV_COUNT && i_count == I_COUNT) state_next = MULTIPLY;
		MULTIPLY: state_next = REFLECT;
		REFLECT:  if(ref_count == REF_COUNT) state_next = WAIT;
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

	case(state)
		WAIT: begin
			if(start == 1'd1) begin
				S_next[0][0] = $signed({ {2{A0[9]}}, A0[8:0], 7'b0 });
				S_next[0][1] = $signed({ {2{A1[9]}}, A1[8:0], 7'b0 });
				S_next[1][0] = $signed({ {2{A2[9]}}, A2[8:0], 7'b0 });
				S_next[1][1] = $signed({ {2{A3[9]}}, A3[8:0], 7'b0 });

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
		for(i = 0; i != 2; i = i + 1) begin
			for(j = 0; j != 2; j = j + 1) begin
				S[i][j] <= 18'd0;
				U[i][j] <= 11'd0;
				V[i][j] <= 11'd0;
			end
		end
		ready     <= 1'd1;
		uv_count  <= 1'd0;
		i_count   <= 4'd0;
		ref_count <= 1'd0;
		state     <= WAIT;
	end
	else begin
		for(i = 0; i != 2; i = i + 1) begin
			for(j = 0; j != 2; j = j + 1) begin
				S[i][j] <= S_next[i][j];
				U[i][j] <= U_next[i][j];
				V[i][j] <= V_next[i][j];
			end
		end
		ready     <= ready_next;
		uv_count  <= uv_count_next;
		i_count   <= i_count_next;
		ref_count <= ref_count_next;
		state     <= state_next;
	end
end

endmodule