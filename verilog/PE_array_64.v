module PE_array_64 (
    input i_clk,
    input i_rst,
    input i_start,
    input [127:0] i_B,
    input [1:0]   i_A,

    output o_stripe_end,
    output [9:0] o_start_position,
    output [9:0] o_end_position,
    output [13:0] o_max_score_stripe
);

integer i, j;

parameter g_o_penalty = -14'd12;
parameter g_e_penalty = -14'd1;
parameter mem_length = 600;

// states
reg [1:0] state, state_nxt;
parameter IDLE = 2'd0;
parameter CALC = 2'd1;
parameter EVAL = 2'd2;
parameter TRAC = 2'd3;

// counter
reg [9:0] counter, counter_nxt;
reg [3:0] stripe_count, stripe_count_nxt;

// 2 input sequence
reg [1:0] A_array[63:0], A_array_nxt[63:0];
reg [1:0] B_array[63:0], B_array_nxt[63:0];

// score metrix // need modify
// reg [13:0] v_score_metrix[0:63][0:399], v_score_metrix_nxt[0:63][0:399];
// reg [13:0] i_score_metrix[0:63][0:399], i_score_metrix_nxt[0:63][0:399];
// reg [13:0] d_score_metrix[0:63][0:399], d_score_metrix_nxt[0:63][0:399];

reg [1:0] v_dir_metrix[0:mem_length-1][0:63], v_dir_metrix_nxt[0:mem_length-1][0:63];
reg       i_dir_metrix[0:mem_length-1][0:63], i_dir_metrix_nxt[0:mem_length-1][0:63];
reg       d_dir_metrix[0:mem_length-1][0:63], d_dir_metrix_nxt[0:mem_length-1][0:63];

// save score or not
reg [63:0] PE_enable, PE_enable_nxt;

// score feed into PEs
reg [13:0] v_score_array[0:63]    , v_score_array_nxt[0:63];
reg [13:0] v_score_dia_array[0:63], v_score_dia_array_nxt[0:63]; // v_score delay one cycle
reg [13:0] i_score_lef_array[0:63], i_score_lef_array_nxt[0:63];
reg [13:0] d_score_top_array[0:63], d_score_top_array_nxt[0:63];

// score for left boundary initial
reg [13:0] left_bound_init, left_bound_init_nxt;

// if stripe start from left boundary
reg start_on_bound, start_on_bound_nxt;

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

// dia & top score of first PE
reg [13:0] dia_score_first_PE, dia_score_first_PE_nxt, top_score_first_PE, top_score_first_PE_nxt;
reg [13:0] top_d_first_PE, top_d_first_PE_nxt;

// save score of last PE for next stripe
reg [13:0] score_last_PE[0:mem_length-1], score_last_PE_nxt[0:mem_length-1];
reg [13:0] d_last_PE[0:mem_length-1], d_last_PE_nxt[0:mem_length-1];

// min & max of PEs
wire [13:0] max_in_PEs, min_in_PEs;
wire [5:0] max_y_temp;
reg [14*64-1:0] v_score_merge;
always @(*) begin
    for (i=0; i<64; i=i+1) begin
        v_score_merge[i*14+:14] = v_score_array[i];
    end
end
max_n_min comparator(
    .v_score_merge(v_score_merge),
    .o_max(max_in_PEs),
    .o_min(min_in_PEs),
    .o_x(max_y_temp)
);

// end signal (all score < max-threshold)
reg finish, finish_nxt;
reg [9:0] start_position, start_position_nxt;
reg [9:0] start_position_old, start_position_old_nxt;
reg [9:0] end_position, end_position_nxt;
assign o_stripe_end = finish;
assign o_start_position = start_position;
assign o_end_position = end_position;

// save min & max of every steps
reg [13:0] min_array [0:mem_length-1], min_array_nxt [0:mem_length-1];
reg [13:0] local_max, local_max_nxt; // max score in the stripe
wire [13:0] stop_threshold;
assign stop_threshold = local_max - 14'd250;
assign o_max_score_stripe = local_max;

// max position
reg [9:0] x_max, x_max_nxt;
reg [5:0] y_max, y_max_nxt;

// 64 PEs
genvar gv;
generate
    for (gv=0; gv<64; gv=gv+1) begin: PEs
        if (gv==0) begin
            PE single_PE(
                .i_A(A_array[gv]),
                .i_B(B_array[gv]),
                .i_v_diagonal_score(dia_score_first_PE),
                .i_v_top_score(top_score_first_PE),
                .i_v_left_score(v_score_array[gv]),
                .i_i_left_score(i_score_lef_array[gv]),
                .i_d_top_score(top_d_first_PE),
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
    // keep reg value
    state_nxt = state;
    counter_nxt = counter;
    stripe_count_nxt = stripe_count;
    for (i=0; i<64; i=i+1) begin
        A_array_nxt[i] = A_array[i];
        B_array_nxt[i] = B_array[i];
        v_score_array_nxt[i] = v_score_array[i];
        v_score_dia_array_nxt[i] = v_score_dia_array[i];
        i_score_lef_array_nxt[i] = i_score_lef_array[i];
        d_score_top_array_nxt[i] = d_score_top_array[i];
    end
    for (j=0; j<mem_length; j=j+1) begin
        min_array_nxt[j] = min_array[j];
        score_last_PE_nxt[j] = score_last_PE[j];
        d_last_PE_nxt[j] = d_last_PE[j];
        for (i=0; i<64; i=i+1) begin
            v_dir_metrix_nxt[j][i] = v_dir_metrix[j][i];
            i_dir_metrix_nxt[j][i] = i_dir_metrix[j][i];
            d_dir_metrix_nxt[j][i] = d_dir_metrix[j][i];
        end
    end
    local_max_nxt = local_max;
    // PE enable is a shift register
    for (i=0; i<64; i=i+1) begin
        PE_enable_nxt[i] = PE_enable[i];
    end
    dia_score_first_PE_nxt = dia_score_first_PE;
    top_score_first_PE_nxt = top_score_first_PE;
    top_d_first_PE_nxt = top_d_first_PE;
    finish_nxt = 1'b0;
    start_position_nxt = start_position;
    start_position_old_nxt = start_position_old;
    end_position_nxt = end_position;
    left_bound_init_nxt = left_bound_init;
    start_on_bound_nxt = start_on_bound;
    x_max_nxt = x_max;
    y_max_nxt = y_max;
    case (state)
        IDLE: begin
            if (i_start) begin
                state_nxt = CALC;
                counter_nxt = 10'b0;
                for (i=0; i<64; i=i+1) begin
                    B_array_nxt[i] = i_B[(2*i)+:2];
                end
                A_array_nxt[0] = i_A;
                PE_enable_nxt[0] = i_start;
                for (i=1; i<64; i=i+1) begin
                    PE_enable_nxt[i] = 1'b0;
                end
                left_bound_init_nxt = left_bound_init + $signed(g_e_penalty);
            end
            // initial score
            for (i=0; i<64; i=i+1) begin
                // change fisrt left score of all PEs to -inf
                // v_score_array_nxt[i] = $signed(g_o_penalty) + $signed(g_e_penalty) * $signed(i);  // left boundary
                v_score_array_nxt[i] = 14'b11000000000000;
                v_score_dia_array_nxt[i] = 14'b11000000000000;
                i_score_lef_array_nxt[i] = 14'b11000000000000;
                d_score_top_array_nxt[i] = 14'b11000000000000;
            end
            for (j=0; j<mem_length; j=j+1) begin
                min_array_nxt[j] = 14'b11000000000000;
            end
            if (start_on_bound) begin
                v_score_array_nxt[0] = left_bound_init;
            end
            dia_score_first_PE_nxt = dia_score_first_PE;
            top_score_first_PE_nxt = score_last_PE[start_position_old];
            top_d_first_PE_nxt = d_last_PE[start_position_old];
            local_max_nxt = 14'b11000000000000;
            start_position_nxt = 10'b0;
        end
        CALC: begin
            PE_enable_nxt[0] = i_start;
            counter_nxt = counter + 1;
            for (i=1; i<64; i=i+1) begin
                PE_enable_nxt[i] = PE_enable[i-1];
            end
            if ((PE_enable[63] == 1) & (PE_enable[62] == 0)) begin
                state_nxt = EVAL;
                end_position_nxt = counter;
                counter_nxt = 10'b0;
            end
            A_array_nxt[0] = i_A;
            v_score_array_nxt[0] = PE_enable[0] ? v_score_out[0] : v_score_array[0];
            v_score_dia_array_nxt[0] = PE_enable[1] ? v_score_array[0] : v_score_dia_array[0];
            i_score_lef_array_nxt[0] = PE_enable[0] ? i_score_out[0] : i_score_lef_array[0];
            d_score_top_array_nxt[0] = PE_enable[0] ? d_score_out[0] : 14'b11000000000000;
            for (i=1; i<64; i=i+1) begin
                A_array_nxt[i] = A_array[i-1];
                v_score_array_nxt[i] = PE_enable[i] ? v_score_out[i] : v_score_array[i];
                v_score_dia_array_nxt[i] = PE_enable[i+1] ? v_score_array[i] : v_score_dia_array[i];
                i_score_lef_array_nxt[i] = PE_enable[i] ? i_score_out[i] : i_score_lef_array[i];
                d_score_top_array_nxt[i] = PE_enable[i] ? d_score_out[i] : d_score_top_array[i];
            end
            dia_score_first_PE_nxt = top_score_first_PE;
            if (counter+start_position_old+1 > mem_length-1) begin
                top_score_first_PE_nxt = 14'b11000000000000;
                top_d_first_PE_nxt = 14'b11000000000000;
            end
            else begin
                top_score_first_PE_nxt = score_last_PE[counter+start_position_old+1];
                top_d_first_PE_nxt = d_last_PE[counter+start_position_old+1];
            end
            // Save direction
            for (i=0; i<64; i=i+1) begin
                v_dir_metrix_nxt[counter][i] = PE_enable[i] ? v_dir_nxt[i] : 2'd3;
                i_dir_metrix_nxt[counter][i] = PE_enable[i] ? i_dir_nxt[i] : 1'b0;
                d_dir_metrix_nxt[counter][i] = PE_enable[i] ? d_dir_nxt[i] : 1'b0;
            end
            // min & max will delay one cycle
            if (counter != 0) begin
                // Save min score after 64 cycles
                if (counter[9:6] != 4'b0) begin
                    min_array_nxt[counter-64] = min_in_PEs; // minimum of 64'th step should be put in first position
                    // start position for next stripe
                    if (($signed(min_array[start_position]) <= $signed(stop_threshold)) & (min_array[start_position] != -14'd4096)) begin
                        start_position_nxt = start_position + 1;
                    end
                end
                // if stop
                if ($signed(local_max) > $signed(max_in_PEs)) begin
                    local_max_nxt = local_max;
                    x_max_nxt = x_max;
                    y_max_nxt = y_max;
                end
                else begin
                    local_max_nxt = max_in_PEs;
                    x_max_nxt = counter;
                    y_max_nxt = max_y_temp;
                end

                if ($signed(max_in_PEs) < $signed(stop_threshold)) begin
                    state_nxt = EVAL;
                    counter_nxt = 10'b0;
                    dia_score_first_PE_nxt = 14'b11000000000000; // if next stripe start from left boundary
                    end_position_nxt = counter;
                end
            end
            // score for next stripe
            if (PE_enable[63] == 1) begin
                score_last_PE_nxt[counter-63] = v_score_out[63];
                d_last_PE_nxt[counter-63] = d_score_out[63];
            end
            if (counter < 10'd63) begin
                left_bound_init_nxt = left_bound_init + $signed(g_e_penalty);
                if (start_on_bound) v_score_array_nxt[counter+1] = left_bound_init;
            end
        end
        EVAL: begin // find next start column
            // Trace back
            if (stripe_count == 4'd15) begin
                state_nxt = TRAC;
            end
            else begin
                state_nxt = IDLE;
            end
            finish_nxt = 1'b1;
            stripe_count_nxt = stripe_count + 1;
            if (start_position != 0) begin
                start_on_bound_nxt = 1'b0;
                dia_score_first_PE_nxt = score_last_PE[start_position-1];
            end
            start_position_old_nxt = start_position;
        end
        TRAC: begin
            if ((x_max == 0) | (y_max == 0)) begin
                state_nxt = IDLE;
            end
            else begin
                state_nxt = state;
                if (v_dir_metrix[y_max][x_max] == 2'd0) begin
                    y_max_nxt = y_max - 1;
                    x_max_nxt = x_max - 1;
                end
                else if (v_dir_metrix[y_max][x_max] == 2'd1) begin
                    y_max_nxt = y_max - 1;
                    x_max_nxt = x_max;
                end
                else if (v_dir_metrix[y_max][x_max] == 2'd2) begin
                    y_max_nxt = y_max;
                    x_max_nxt = x_max - 1;
                end
                else begin
                    y_max_nxt = y_max - 1;
                    x_max_nxt = x_max - 1;
                end
            end
        end
    endcase
end

// store scores into matrix
// always @(*) begin
//     for (i=0; i<64; i=i+1) begin
//         for (j=0; j<200; j=j+1) begin
//             v_score_metrix_nxt[i][j] = v_score_metrix[i][j];
//             i_score_metrix_nxt[i][j] = i_score_metrix[i][j];
//             d_score_metrix_nxt[i][j] = d_score_metrix[i][j];
//         end
//     end
//     if (state == CALC) begin
//         for (i=0; i<64; i=i+1) begin
//             v_score_metrix_nxt[i][counter-i] = PE_enable[i] ? v_score_out[i] : v_score_metrix[i][counter-i];
//             i_score_metrix_nxt[i][counter-i] = PE_enable[i] ? i_score_out[i] : i_score_metrix[i][counter-i];
//             d_score_metrix_nxt[i][counter-i] = PE_enable[i] ? d_score_out[i] : d_score_metrix[i][counter-i];
//         end
//     end
// end

always @(posedge i_clk or posedge i_rst) begin
	// reset
	if (i_rst) begin
        state <= IDLE;
        counter <= 10'b0;
        stripe_count<= 4'b0;
        PE_enable <= 64'b0;
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
        dia_score_first_PE <= 14'd0;
        top_score_first_PE <= g_o_penalty;
        top_d_first_PE <= 14'b11000000000000;
        for (j=0; j<mem_length; j=j+1) begin
            min_array[j] <= 14'b0;
            score_last_PE[j] <= $signed(g_o_penalty) + $signed(g_e_penalty) * $signed(j);
            d_last_PE[j] <= 14'b11000000000000;
            for (i=0; i<64; i=i+1) begin
                v_dir_metrix[j][i] <= 2'b0;
                i_dir_metrix[j][i] <= 1'b0;
                d_dir_metrix[j][i] <= 1'b0;
            end
        end
        local_max <= 14'b11000000000000;
        finish <= 1'b0;
        start_position <= 10'b0;
        start_position_old <= 10'b0;
        end_position <= 10'b0;
        left_bound_init <= $signed(g_o_penalty);
        start_on_bound <= 1'b1;
        x_max <= 10'b0;
        y_max <= 6'b0;
	end
	// clock edge
	else begin
        state <= state_nxt;
        counter <= counter_nxt;
        stripe_count <= stripe_count_nxt;
        PE_enable <= PE_enable_nxt;
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
        dia_score_first_PE <= dia_score_first_PE_nxt;
        top_score_first_PE <= top_score_first_PE_nxt;
        top_d_first_PE <= top_d_first_PE_nxt;
        for (j=0; j<mem_length; j=j+1) begin
            min_array[j] <= min_array_nxt[j];
            score_last_PE[j] <= score_last_PE_nxt[j];
            d_last_PE[j] <= d_last_PE_nxt[j];
            for (i=0; i<64; i=i+1) begin
                v_dir_metrix[j][i] <= v_dir_metrix_nxt[j][i];
                i_dir_metrix[j][i] <= i_dir_metrix_nxt[j][i];
                d_dir_metrix[j][i] <= d_dir_metrix_nxt[j][i];
            end
        end
        local_max <= local_max_nxt;
        finish <= finish_nxt;
        start_position <= start_position_nxt;
        start_position_old <= start_position_old_nxt;
        end_position <= end_position_nxt;
        left_bound_init <= left_bound_init_nxt;
        start_on_bound <= start_on_bound_nxt;
        x_max <= x_max_nxt;
        y_max <= y_max_nxt;
	end
end
endmodule

module max_n_min(
    input [14*64-1:0] v_score_merge,
    output [13:0] o_max,
    output [13:0] o_min,
    output [5:0]  o_x
);

integer i;

reg [13:0] v_score [0:63];
always @(*) begin
    for (i=0; i<64; i=i+1) begin
        v_score[i] = v_score_merge[i*14+:14];
    end
end

// layer 1, 32 comparators
reg [13:0] min_temp_l1 [0:31];
reg [13:0] max_temp_l1 [0:31];
reg [5:0] x_l1 [0:31];
always @(*) begin
    for (i=0; i<32; i=i+1) begin
        min_temp_l1[i] = ($signed(v_score[2*i]) > $signed(v_score[2*i+1])) ? v_score[2*i+1] : v_score[2*i];
        max_temp_l1[i] = ($signed(v_score[2*i]) > $signed(v_score[2*i+1])) ? v_score[2*i] : v_score[2*i+1];
        x_l1[i] = ($signed(v_score[2*i]) > $signed(v_score[2*i+1])) ? (2*i) : (2*i+1);
    end
end
// layer 2, 16 comparators
reg [13:0] min_temp_l2 [0:15];
reg [13:0] max_temp_l2 [0:15];
reg [5:0] x_l2 [0:15];
always @(*) begin
    for (i=0; i<16; i=i+1) begin
        min_temp_l2[i] = ($signed(min_temp_l1[2*i]) < $signed(min_temp_l1[2*i+1])) ? min_temp_l1[2*i] : min_temp_l1[2*i+1];
        max_temp_l2[i] = ($signed(max_temp_l1[2*i]) > $signed(max_temp_l1[2*i+1])) ? max_temp_l1[2*i] : max_temp_l1[2*i+1];
        x_l2[i] = ($signed(max_temp_l1[2*i]) > $signed(max_temp_l1[2*i+1])) ? x_l1[2*i] : x_l1[2*i+1];
    end
end
// layer 3, 8 comparators
reg [13:0] min_temp_l3 [0:7];
reg [13:0] max_temp_l3 [0:7];
reg [5:0] x_l3 [0:7];
always @(*) begin
    for (i=0; i<8; i=i+1) begin
        min_temp_l3[i] = ($signed(min_temp_l2[2*i]) < $signed(min_temp_l2[2*i+1])) ? min_temp_l2[2*i] : min_temp_l2[2*i+1];
        max_temp_l3[i] = ($signed(max_temp_l2[2*i]) > $signed(max_temp_l2[2*i+1])) ? max_temp_l2[2*i] : max_temp_l2[2*i+1];
        x_l3[i] = ($signed(max_temp_l2[2*i]) > $signed(max_temp_l2[2*i+1])) ? x_l2[2*i] : x_l2[2*i+1];
    end
end
// layer 4, 4 comparators
reg [13:0] min_temp_l4 [0:3];
reg [13:0] max_temp_l4 [0:3];
reg [5:0] x_l4 [0:3];
always @(*) begin
    for (i=0; i<4; i=i+1) begin
        min_temp_l4[i] = ($signed(min_temp_l3[2*i]) < $signed(min_temp_l3[2*i+1])) ? min_temp_l3[2*i] : min_temp_l3[2*i+1];
        max_temp_l4[i] = ($signed(max_temp_l3[2*i]) > $signed(max_temp_l3[2*i+1])) ? max_temp_l3[2*i] : max_temp_l3[2*i+1];
        x_l4[i] = ($signed(max_temp_l3[2*i]) > $signed(max_temp_l3[2*i+1])) ? x_l3[2*i] : x_l3[2*i+1];
    end
end
// layer 5, 2 comparators
reg [13:0] min_temp_l5 [0:1];
reg [13:0] max_temp_l5 [0:1];
reg [5:0] x_l5 [0:1];
always @(*) begin
    for (i=0; i<2; i=i+1) begin
        min_temp_l5[i] = ($signed(min_temp_l4[2*i]) < $signed(min_temp_l4[2*i+1])) ? min_temp_l4[2*i] : min_temp_l4[2*i+1];
        max_temp_l5[i] = ($signed(max_temp_l4[2*i]) > $signed(max_temp_l4[2*i+1])) ? max_temp_l4[2*i] : max_temp_l4[2*i+1];
        x_l5[i] = ($signed(max_temp_l4[2*i]) > $signed(max_temp_l4[2*i+1])) ? x_l4[2*i] : x_l4[2*i+1];
    end
end
// layer 6, final output
assign o_min = ($signed(min_temp_l5[0]) < $signed(min_temp_l5[1])) ? min_temp_l5[0] : min_temp_l5[1];
assign o_max = ($signed(max_temp_l5[0]) > $signed(max_temp_l5[1])) ? max_temp_l5[0] : max_temp_l5[1];
assign o_x = ($signed(max_temp_l5[0]) > $signed(max_temp_l5[1])) ? x_l5[0] : x_l5[1];

endmodule