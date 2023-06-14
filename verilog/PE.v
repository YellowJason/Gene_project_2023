module PE (
    input [1:0] i_A, // base 1
    input [1:0] i_B, // base 2
    // Score matrix
    input signed [13:0] i_v_diagonal_score, 
    input signed [13:0] i_v_top_score,
    input signed [13:0] i_v_left_score, 
    // Insertion matrix
    input signed [13:0] i_i_left_score,
    // deletion metrix
    input signed [13:0] i_d_top_score,
    // output score of V,I,D
    output signed [13:0] o_v_score,
    output signed [13:0] o_i_score,
    output signed [13:0] o_d_score,
    // output direction
    output [1:0] o_v_direct, // 0:top-left, 1:top, 2:left
    output       o_i_direct, // 0:from I (extension), 1:from V (opening)
    output       o_d_direct  // 0:from D (extension), 1:from V (opening)
);

parameter g_o_penalty = -14'd12;
parameter g_e_penalty = -14'd1;
parameter width = 14;

// Match score of two base (extra bit for overflow)
wire [width-1:0] match_score;
wire [width-1:0] V_temp;
Substitution_Matrix W_0(.i_A(i_A), .i_B(i_B), .o_score(match_score));
assign V_temp = $signed(i_v_diagonal_score) + $signed(match_score);

// Score from Insertion (extra bit for overflow)
wire [width-1:0] I_temp_1, I_temp_2;
assign I_temp_1 = $signed(i_v_left_score) + $signed(g_o_penalty);
assign I_temp_2 = (i_i_left_score == 14'b10000000000000) ? i_i_left_score: $signed(i_i_left_score) + $signed(g_e_penalty); // keep -inf
assign o_i_score = ($signed(I_temp_1) > $signed(I_temp_2)) ? I_temp_1 : I_temp_2;
assign o_i_direct = ($signed(I_temp_1) > $signed(I_temp_2)) ? 1'b1 : 1'b0;

// Score from Deletion (extra bit for overflow)
wire [width-1:0] D_temp_1, D_temp_2;
assign D_temp_1 = $signed(i_v_top_score) + $signed(g_o_penalty);
assign D_temp_2 = (i_d_top_score == 14'b10000000000000) ? i_d_top_score: $signed(i_d_top_score) + $signed(g_e_penalty);
assign o_d_score = ($signed(D_temp_1) > $signed(D_temp_2)) ? D_temp_1 : D_temp_2;
assign o_d_direct = ($signed(D_temp_1) > $signed(D_temp_2)) ? 1'b1 : 1'b0;

// final score
assign o_v_score = (($signed(V_temp) >= $signed(o_i_score)) & ($signed(V_temp) >= $signed(o_d_score))) ? V_temp :
                    ($signed(o_i_score) >= $signed(o_d_score)) ? o_i_score : o_d_score;
assign o_v_direct = (($signed(V_temp) >= $signed(o_i_score)) & ($signed(V_temp) >= $signed(o_d_score))) ? 2'd0 :
                    ($signed(o_i_score) >= $signed(o_d_score)) ? 2'd2 : 2'd1;

endmodule

module Substitution_Matrix(
    input [1:0] i_A, // base 1
    input [1:0] i_B, // base 2
    output signed [13:0] o_score
);

parameter width = 14;
reg [width-1:0] score;
assign o_score = score;

always @(*) begin
    case (i_A)
        2'd0:begin // A
            case (i_B)
                2'd0: score =  14'd3;
                2'd1: score = -14'd3;
                2'd2: score = -14'd1;
                2'd3: score = -14'd4;
            endcase
        end
        2'd1:begin // C
            case (i_B)
                2'd0: score = -14'd3;
                2'd1: score =  14'd4;
                2'd2: score = -14'd4;
                2'd3: score = -14'd1;
            endcase
        end
        2'd2:begin // G
            case (i_B)
                2'd0: score = -14'd1;
                2'd1: score = -14'd4;
                2'd2: score =  14'd4;
                2'd3: score = -14'd3;
            endcase
        end
        2'd3:begin // T
            case (i_B)
                2'd0: score = -14'd4;
                2'd1: score = -14'd1;
                2'd2: score = -14'd3;
                2'd3: score =  14'd3;
            endcase
        end
    endcase
end

endmodule