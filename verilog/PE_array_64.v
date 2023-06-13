module PE_array (
    input i_clk,
    input i_rst,
    input i_start,
    input i_stop,
    input [127:0] i_B,
    input [1:0]   i_A
);

integer i;

// states
reg [1:0] state, state_nxt;
parameter IDLE = 2'd0;
parameter CALC = 2'd1;

// 2 input sequence
reg [1:0] A_array[63:0], A_array_nxt[63:0];
reg [1:0] B_array[63:0], B_array_nxt[63:0];

// score metrix
reg [13:0] v_score_metrix[0:63][0:63], v_score_metrix_nxt[0:63][0:63];
reg [13:0] i_score_metrix[0:63][0:63], i_score_metrix_nxt[0:63][0:63];
reg [13:0] d_score_metrix[0:63][0:63], d_score_metrix_nxt[0:63][0:63];

// score feed into PEs
reg [13:0] v_score_array[0:63], v_score_array_nxt[0:63];
reg [13:0] v_score_dia_array[0:63], v_score_dia_array_nxt[0:63];
reg [13:0] i_score_lef_array[0:63], i_score_lef_array_nxt[0:63];
reg [13:0] d_score_top_array[0:63], d_score_top_array_nxt[0:63];

// PEs output
wire [13:0] v_score_out[0:63];
wire [13:0] i_score_out[0:63];
wire [13:0] d_score_out[0:63];

// directions
reg [1:0] v_dir[0:63];
wire [1:0] v_dir_nxt[0:63];
reg i_dir[0:63];
wire i_dir_nxt[0:63];
reg d_dir[0:63];
wire d_dir_nxt[0:63];

// 64 PEs
genvar gv;
generate
    for (gv=0; gv<64; gv=gv+1) begin: PEs
        if (gv==0) begin
            PE single_PE(
                .i_A(A_array[gv]),
                .i_B(B_array[gv]),
                .i_v_diagonal_score(14'b00000000000000),
                .i_v_top_score(14'b10000000000000),
                .i_v_left_score(v_score_array[gv]),
                .i_i_left_score(i_score_lef_array[gv]),
                .i_d_top_score(14'b10000000000000),
                .o_v_score(v_score_out[gv]),
                .o_i_score(i_score_out[gv]),
                .o_d_score(d_score_out[gv]),
                .o_v_direct(v_dir_nxt[gv]),
                .o_i_direct(i_dir_nxt[gv]),
                .o_d_direct(d_dir_nxt[gv])
            );
        end
        else begin
            PE single_PE(
                .i_A(A_array[gv]),
                .i_B(B_array[gv]),
                .i_v_diagonal_score(v_score_dia_array[gv-1]),
                .i_v_top_score(v_score_array[gv-1]),
                .i_v_left_score(v_score_array[gv]),
                .i_i_left_score(i_score_lef_array[gv]),
                .i_d_top_score(d_score_top_array[gv-1]),
                .o_v_score(v_score_out[gv]),
                .o_i_score(i_score_out[gv]),
                .o_d_score(d_score_out[gv]),
                .o_v_direct(v_dir_nxt[gv]),
                .o_i_direct(i_dir_nxt[gv]),
                .o_d_direct(d_dir_nxt[gv])
            );
        end
    end
endgenerate

always @(*) begin
    state_nxt = state;
    for (i=0; i<64; i=i+1) begin
        A_array_nxt[i] = A_array[i];
        B_array_nxt[i] = B_array[i];
        v_score_array_nxt[i] = v_score_array[i];
        v_score_dia_array_nxt[i] = v_score_dia_array[i];
        i_score_lef_array_nxt[i] = i_score_lef_array[i];
        d_score_top_array_nxt[i] = d_score_top_array[i];
    end
    case (state)
        IDLE: begin
            if (i_start) begin
                state_nxt = CALC;
                for (i=0; i<64; i=i+1) begin
                    B_array_nxt[i] = i_B[(2*i)+:2];
                end
                A_array_nxt[0] = i_A;
            end
        end
        CALC: begin
            if (i_stop) begin
                state_nxt = IDLE;
            end
            A_array_nxt[0] = i_A;
            v_score_array_nxt[0] = v_score_out[0];
            v_score_dia_array_nxt[0] = 14'b10000000000000;
            i_score_lef_array_nxt[0] = i_score_out[0];
            d_score_top_array_nxt[0] = 14'b10000000000000;
            for (i=1; i<64; i=i+1) begin
                A_array_nxt[i] = A_array[i-1];
                v_score_array_nxt[i] = v_score_out[i];
                v_score_dia_array_nxt[i] = v_score_array[i];
                i_score_lef_array_nxt[i] = i_score_out[i];
                d_score_top_array_nxt[i] = d_score_out[i-1];
            end
        end
    endcase
end

always @(posedge i_clk or posedge i_rst) begin
	// reset
	if (i_rst) begin
        state <= IDLE;
        for (i=0; i<64; i=i+1) begin
            A_array[i] <= 2'b0;
            B_array[i] <= 2'b0;
            v_score_array[i] <= 14'b0;
            v_score_dia_array[i] <= 14'b0;
            i_score_lef_array[i] <= 14'b0;
            d_score_top_array[i] <= 14'b0;
            v_dir[i] <= 2'b0;
            i_dir[i] <= 1'b0;
            d_dir[i] <= 1'b0;
        end
	end
	// clock edge
	else begin
        state <= state_nxt;
        for (i=0; i<64; i=i+1) begin
            A_array[i] <= A_array_nxt[i];
            B_array[i] <= B_array_nxt[i];
            v_score_array[i] <= v_score_array_nxt[i];
            v_score_dia_array[i] <= v_score_dia_array_nxt[i];
            i_score_lef_array[i] <= i_score_lef_array_nxt[i];
            d_score_top_array[i] <= d_score_top_array_nxt[i];
            v_dir[i] <= v_dir_nxt[i];
            i_dir[i] <= i_dir_nxt[i];
            d_dir[i] <= d_dir_nxt[i];
        end
	end
end
endmodule