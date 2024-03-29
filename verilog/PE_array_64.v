module PE_array_64 (
    input i_clk,
    input i_rst,
    input i_start,
    input [127:0] i_B,
    input [1:0]   i_A,

    output o_stripe_end,
    output [9:0] o_start_position,
    output [9:0] o_end_position,
    output [13:0] o_max_score_stripe,
    output [1:0] o_trace_dir
);

integer i, j, k;

parameter g_o_penalty = -11'd12;
parameter g_e_penalty = -11'd1;
parameter mem_length = 512;
parameter threshold = 11'd240;
parameter default_shift = 9'd32;

// ***************for test***************
reg [19:0] align_count;

// states
reg [1:0] state, state_nxt;
parameter IDLE = 2'd0;
parameter CALC = 2'd1;
parameter EVAL = 2'd2;
parameter TRAC = 2'd3;

// counter
reg [9:0] counter, counter_nxt;
reg [3:0] stripe_count, stripe_count_nxt;

// save start position shift of every stripe
reg [9:0] start_shift[0:15], start_shift_nxt[0:15];

// 2 input sequence
reg [1:0] A_array[63:0], A_array_nxt[63:0];
reg [1:0] B_array[63:0], B_array_nxt[63:0];

// save score or not
reg [63:0] PE_enable, PE_enable_nxt;

// score feed into PEs
reg [10:0] v_score_array[0:63]    , v_score_array_nxt[0:63];
reg [10:0] v_score_dia_array[0:63], v_score_dia_array_nxt[0:63]; // v_score delay one cycle
reg [10:0] i_score_lef_array[0:63], i_score_lef_array_nxt[0:63];
reg [10:0] d_score_top_array[0:63], d_score_top_array_nxt[0:63];

// score for left boundary initial
reg [10:0] left_bound_init, left_bound_init_nxt;
reg [10:0] top_bound_init;

// if stripe start from left boundary
reg start_on_bound, start_on_bound_nxt;

// PEs output
wire [10:0] v_score_out[0:63];
wire [10:0] i_score_out[0:63];
wire [10:0] d_score_out[0:63];

// directions
reg  [1:0] v_dir[0:63], v_dir_dia[0:63];
wire [1:0] v_dir_nxt[0:63];
reg  [63:0] i_dir;
wire [63:0] i_dir_nxt;
reg  [63:0] d_dir;
wire [63:0] d_dir_nxt;

// dia & top score of first PE
reg [10:0] dia_score_first_PE, dia_score_first_PE_nxt;

// min & max of PEs
wire [10:0] max_in_PEs, min_in_PEs;
wire [5:0] max_y_temp;
reg [11*64-1:0] v_score_merge;
always @(*) begin
    for (i=0; i<64; i=i+1) begin
        v_score_merge[i*11+:11] = v_score_array[i];
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
reg [10:0] min_array [0:mem_length-1], min_array_nxt [0:mem_length-1];
reg [10:0] local_max, local_max_nxt, local_min, local_min_nxt, bias, bias_nxt; // max & min score in the stripe
wire [10:0] stop_threshold;
assign stop_threshold = local_max - threshold;
assign o_max_score_stripe = local_max;

// max position
reg [9:0] x_max, x_max_nxt;
reg [5:0] y_max, y_max_nxt;

// trace result
reg [1:0] trace_dir, trace_dir_nxt;
assign o_trace_dir = trace_dir;

// trace gap open, 0:no, 1:trace D (top), 2:trace I (left)
reg [1:0] trace_open, trace_open_nxt;

// Memory banks
reg wen, cen, cen_nxt;
reg [63:0] v_0, v_1;
wire [63:0] mem_out_v_0, mem_out_v_1, mem_out_i, mem_out_d;
reg [8:0] address;
wire [1:0] v_trace_mem = {mem_out_v_1[y_max], mem_out_v_0[y_max]};

always @(*) begin
    for (i=0; i<64; i=i+1) begin
        {v_1[i], v_0[i]} = v_dir_nxt[i] & {2{PE_enable[i]}};
    end
    // address setting
    wen = (state != CALC);
    address = (state == CALC) ? counter : x_max_nxt;
end

Mem_control mem_banks(
    .i_clk(i_clk),
    .cen(cen),
    .wen(wen),
    .bank(stripe_count),
    .address(address),
    // 4'b direction
    .i_v_0(v_0),
    .i_v_1(v_1),
    .i_i(i_dir_nxt),
    .i_d(d_dir_nxt),

    .o_v_0(mem_out_v_0),
    .o_v_1(mem_out_v_1),
    .o_i(mem_out_i),
    .o_d(mem_out_d)
);

// save score of last PE for next stripe
// last saved value = [end_position - 63]
reg wen_a;
reg [21:0] score_sram_last_PE;
reg [8:0] last_PE_waddr, last_PE_raddr;
wire [10:0] last_PE_out_d_score, last_PE_out_v_score;
reg [10:0] top_score_first_PE, top_d_first_PE;

always @(*) begin
    score_sram_last_PE = {d_score_out[63], v_score_out[63]};
    last_PE_waddr = (PE_enable[63] == 1) ? (counter - 6'd63) : 9'b0;
    if (state_nxt == EVAL) begin
        last_PE_raddr = start_position - 1;
    end
    else begin
        last_PE_raddr = (state == CALC) ? (start_position_old+counter+1) : start_position_old;
    end
    wen_a = ~((state == CALC) & (PE_enable[63] == 1));
    top_score_first_PE = (stripe_count == 4'b0) ? top_bound_init : 
                         ((start_position_old+counter+63) <= end_position) ? last_PE_out_v_score : 11'b11000000000;
    top_d_first_PE = (stripe_count == 4'b0) ? 11'b11000000000 : 
                     ((start_position_old+counter+63) <= end_position) ? last_PE_out_d_score : 11'b11000000000;
end

//******************need modify to 22'b SRAM******************
sram_dp_512_22 sram_last_PE( 
    .CLKA(i_clk),
    .CLKB(i_clk),
    .CENA(cen),
    .CENB(cen),
    .WENA(wen_a), // port A is used to store
    .WENB(1'b1),  // port B is used to read
    .AA(last_PE_waddr),
    .AB(last_PE_raddr),
    .DA(score_sram_last_PE),
    .DB(22'b0),
    // output
    // .QA(),
    .QB({last_PE_out_d_score, last_PE_out_v_score}),
    .EMAA(3'b0), 
    .EMAB(3'b0), 
    .EMASA(1'b0), 
    .EMASB(1'b0), 
    .EMAWA(2'b0), 
    .EMAWB(2'b0), 
    .BENA(1'b1), 
    .BENB(1'b1), 
    .STOVA(1'b0), 
    .STOVB(1'b0), 
    .TENA(1'b1),
    .TENB(1'b1),
    .RET1N(1'b1) 
);

// 64 PEs
genvar gv;
generate
    for (gv=0; gv<64; gv=gv+1) begin: PEs
        if (gv==0) begin
            PE single_PE(
                .i_A(A_array[gv]),
                .i_B(B_array[gv]),
                .i_v_diagonal_score(dia_score_first_PE-bias),
                .i_v_top_score(top_score_first_PE-bias),
                .i_v_left_score(v_score_array[gv]),
                .i_i_left_score(i_score_lef_array[gv]),
                .i_d_top_score(top_d_first_PE-bias),
                .i_dia_dir(2'd2),
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
                .i_dia_dir(v_dir_dia[gv-1]),
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
    for (i=0; i<16; i=i+1) begin
        start_shift_nxt[i] = start_shift[i];
    end
    for (j=0; j<mem_length; j=j+1) begin
        min_array_nxt[j] = min_array[j];
    end
    local_max_nxt = local_max;
    local_min_nxt = local_min;
    bias_nxt = bias;
    // PE enable is a shift register
    for (i=0; i<64; i=i+1) begin
        PE_enable_nxt[i] = PE_enable[i];
    end
    dia_score_first_PE_nxt = dia_score_first_PE;
    finish_nxt = 1'b0;
    start_position_nxt = start_position;
    start_position_old_nxt = start_position_old;
    end_position_nxt = end_position;
    left_bound_init_nxt = left_bound_init;
    start_on_bound_nxt = start_on_bound;
    x_max_nxt = x_max;
    y_max_nxt = y_max;
    trace_dir_nxt = trace_dir;
    trace_open_nxt = trace_open;
    cen_nxt = 1'b0;
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
                v_score_array_nxt[i] = 11'b11000000000;
                v_score_dia_array_nxt[i] = 11'b11000000000;
                i_score_lef_array_nxt[i] = 11'b11000000000;
                d_score_top_array_nxt[i] = 11'b11000000000;
            end
            for (j=0; j<mem_length; j=j+1) begin
                min_array_nxt[j] = 11'b11000000000;
            end
            if (start_on_bound) begin
                v_score_array_nxt[0] = left_bound_init;
            end
            dia_score_first_PE_nxt = dia_score_first_PE;
            local_max_nxt = 11'b11000000000;
            local_min_nxt = 11'b01000000000;
            start_position_nxt = 10'b0;
        end
        CALC: begin
            PE_enable_nxt[0] = i_start;
            counter_nxt = counter + 1;
            for (i=1; i<64; i=i+1) begin
                PE_enable_nxt[i] = PE_enable[i-1];
            end
            A_array_nxt[0] = i_A;
            v_score_array_nxt[0] = PE_enable[0] ? v_score_out[0] : v_score_array[0];
            v_score_dia_array_nxt[0] = PE_enable[0] ? v_score_array[0] : v_score_dia_array[0];
            i_score_lef_array_nxt[0] = PE_enable[0] ? i_score_out[0] : i_score_lef_array[0];
            d_score_top_array_nxt[0] = PE_enable[0] ? d_score_out[0] : 11'b11000000000;
            for (i=1; i<64; i=i+1) begin
                A_array_nxt[i] = A_array[i-1];
                v_score_array_nxt[i] = PE_enable[i] ? v_score_out[i] : v_score_array[i];
                v_score_dia_array_nxt[i] = v_score_array[i];
                i_score_lef_array_nxt[i] = PE_enable[i] ? i_score_out[i] : i_score_lef_array[i];
                d_score_top_array_nxt[i] = PE_enable[i] ? d_score_out[i] : d_score_top_array[i];
            end
            dia_score_first_PE_nxt = top_score_first_PE;
            if (counter < 10'd63) begin
                left_bound_init_nxt = left_bound_init + $signed(g_e_penalty);
                if (start_on_bound) v_score_array_nxt[counter+1] = left_bound_init;
            end
            // min & max will delay one cycle
            if (counter != 0) begin
                // Save min score after 64 cycles
                if (counter[9:6] != 4'b0) begin
                    min_array_nxt[counter-64] = min_in_PEs; // minimum of 64'th step should be put in first position
                    local_min_nxt = ($signed(min_in_PEs) < $signed(local_min)) ? min_in_PEs : local_min;
                    // start position for next stripe
                    if (($signed(min_array[start_position]) <= $signed(stop_threshold)) &
                        (min_array[start_position] != -11'd512) &
                        (start_position <= counter - 7'd70)) begin
                        start_position_nxt = start_position + 2'd2;
                    end
                end
                // save local maximum
                if ($signed(local_max) >= $signed(max_in_PEs)) begin
                    local_max_nxt = local_max;
                    x_max_nxt = x_max;
                    y_max_nxt = y_max;
                end
                else begin
                    local_max_nxt = max_in_PEs;
                    x_max_nxt = counter - 1;
                    y_max_nxt = max_y_temp;
                end
            end
            // stop stripe
            if (((PE_enable[63] == 1) & (PE_enable[62] == 0)) | ($signed(max_in_PEs) < $signed(stop_threshold)) | (counter == 10'd511)) begin
                state_nxt = EVAL;
                counter_nxt = 10'b0;
                dia_score_first_PE_nxt = 11'b11000000000; // if next stripe start from left boundary
                end_position_nxt = counter;
                start_position_nxt = ($signed(min_array[start_position]) <= $signed(stop_threshold)) ? default_shift : start_position;
                start_shift_nxt[stripe_count] = start_position_nxt;
            end
        end
        EVAL: begin // find next start column
            // Trace back
            if (stripe_count == 4'd15) begin
                state_nxt = TRAC;
                stripe_count_nxt = stripe_count;
            end
            else begin
                state_nxt = IDLE;
                stripe_count_nxt = stripe_count + 1;
            end
            finish_nxt = 1'b1;
            if (start_position != 0) begin
                start_on_bound_nxt = 1'b0;
                dia_score_first_PE_nxt = last_PE_out_v_score;
            end
            start_position_old_nxt = start_position;
            bias_nxt = $signed(local_max[10:1]) + $signed(local_min[10:1]);
        end
        TRAC: begin
            trace_dir_nxt = v_trace_mem;
            counter_nxt = counter + 1;
            // reach bigining (up bound, left bound)
            if ((((x_max == y_max) & (v_trace_mem != 2'd2)) |
                 ((y_max == 0) & (v_trace_mem != 2'd3)) |
                 ((y_max >= 1) & (v_trace_mem != 2'd3)) |
                 (({x_max,y_max} == {2'd3,2'd2}) & (v_trace_mem == 2'd0))) & (stripe_count == 0)) begin
                state_nxt = IDLE;
                finish_nxt = 1'b1;
            end
            // change stripe
            else if ((y_max == 0)) begin
                // trace on T metrix
                if (trace_open == 2'd0) begin
                    case (v_trace_mem)
                        2'd1: begin // dia
                            stripe_count_nxt = stripe_count - 1;
                            y_max_nxt = 6'd63;
                            x_max_nxt = x_max + start_shift[stripe_count-1] - 2'd1 + 7'd63;
                            trace_open_nxt = 2'd0;
                        end
                        2'd2: begin // top
                            stripe_count_nxt = stripe_count - 1;
                            y_max_nxt = 6'd63;
                            x_max_nxt = x_max + start_shift[stripe_count-1] + 7'd63;
                            if (mem_out_d[y_max] == 1'b0) begin
                                trace_open_nxt = 2'd1;
                            end
                            else begin
                                trace_open_nxt = 2'd0;
                            end
                        end 
                        2'd3: begin // left
                            y_max_nxt = y_max;
                            x_max_nxt = x_max - 1'b1;
                            trace_open_nxt = 2'd2;
                            if (mem_out_i[y_max] == 1'b0) begin
                                trace_open_nxt = 2'd2;
                            end
                            else begin
                                trace_open_nxt = 2'd0;
                            end
                        end
                    endcase
                end
                // Trace on D
                else if (trace_open == 2'd1) begin
                    trace_dir_nxt = 2'd2;
                    stripe_count_nxt = stripe_count - 1;
                    y_max_nxt = 6'd63;
                    x_max_nxt = x_max + start_shift[stripe_count-1] + 7'd63;
                    if (mem_out_d[y_max] == 1'b0) begin
                        trace_open_nxt = 2'd1;
                    end
                    else begin
                        trace_open_nxt = 2'd0;
                    end
                end
                // Trace on I
                else if (trace_open == 2'd2) begin
                    trace_dir_nxt = 2'd3;
                    y_max_nxt = y_max;
                    x_max_nxt = x_max - 1'b1;
                    if (mem_out_i[y_max] == 1'b0) begin
                        trace_open_nxt = 2'd2;
                    end
                    else begin
                        trace_open_nxt = 2'd0;
                    end
                end
            end
            // regular trace
            else begin
                state_nxt = state;
                // trace on T metrix
                if (trace_open == 2'd0) begin
                    case (v_trace_mem)
                        2'd0: begin // dia 2 step
                            y_max_nxt = y_max - 2'd2;
                            // dia two step may cross stripe
                            x_max_nxt = (y_max == 6'd1) ? (x_max + start_shift[stripe_count-1] - 2'd3 + 7'd63) : (x_max - 3'd4);
                            stripe_count_nxt = (y_max == 6'd1) ? (stripe_count-1) : stripe_count;
                            trace_open_nxt = 2'd0;
                        end
                        2'd1: begin // dia
                            y_max_nxt = y_max - 1'b1;
                            x_max_nxt = x_max - 2'd2;
                            trace_open_nxt = 2'd0;
                        end
                        2'd2: begin // top
                            y_max_nxt = y_max - 1'b1;
                            x_max_nxt = x_max - 1'b1;
                            if (mem_out_d[y_max] == 1'b0) begin
                                trace_open_nxt = 2'd1;
                            end
                            else begin
                                trace_open_nxt = 2'd0;
                            end
                        end 
                        2'd3: begin // left
                            y_max_nxt = y_max;
                            x_max_nxt = x_max - 1'b1;
                            if (mem_out_i[y_max] == 1'b0) begin
                                trace_open_nxt = 2'd2;
                            end
                            else begin
                                trace_open_nxt = 2'd0;
                            end
                        end
                    endcase
                end
                // Trace on D
                else if (trace_open == 2'd1) begin
                    trace_dir_nxt = 2'd2;
                    y_max_nxt = y_max - 1'b1;
                    x_max_nxt = x_max - 1'b1;
                    if (mem_out_d[y_max] == 1'b0) begin
                        trace_open_nxt = 2'd1;
                    end
                    else begin
                        trace_open_nxt = 2'd0;
                    end
                end
                // Trace on I
                else if (trace_open == 2'd2) begin
                    trace_dir_nxt = 2'd3;
                    y_max_nxt = y_max;
                    x_max_nxt = x_max - 1'b1;
                    if (mem_out_i[y_max] == 1'b0) begin
                        trace_open_nxt = 2'd2;
                    end
                    else begin
                        trace_open_nxt = 2'd0;
                    end
                end
            end
        end
    endcase
end

always @(posedge i_clk or posedge i_rst) begin
	// reset
	if (i_rst) begin
        align_count <= 20'b0;
        state <= IDLE;
        counter <= 10'b0;
        stripe_count<= 4'b0;
        PE_enable <= 64'b0;
        for (i=0; i<64; i=i+1) begin
            A_array[i] <= 2'b0;
            B_array[i] <= 2'b0;
            v_score_array[i] <= 11'b0;
            v_score_dia_array[i] <= 11'b0;
            i_score_lef_array[i] <= 11'b0;
            d_score_top_array[i] <= 11'b0;
            v_dir[i] <= 2'd2;
            v_dir_dia[i] <= 2'd2;
            i_dir[i] <= 1'b0;
            d_dir[i] <= 1'b0;
        end
        for (i=0; i<16; i=i+1) begin
            start_shift[i] <= 10'b0;
        end
        dia_score_first_PE <= 14'd0;
        for (j=0; j<mem_length; j=j+1) begin
            min_array[j] <= 11'b0;
        end
        local_max <= 11'b11000000000;
        local_min <= 11'b01000000000;
        bias <= 11'b0;
        finish <= 1'b0;
        start_position <= 10'b0;
        start_position_old <= 10'b0;
        end_position <= 10'b0;
        left_bound_init <= $signed(g_o_penalty);
        top_bound_init <= $signed(g_o_penalty);
        start_on_bound <= 1'b1;
        x_max <= 10'b0;
        y_max <= 6'b0;
        trace_dir <= 2'b0;
        trace_open <= 2'b0;
        cen <= 1'b1;
	end
	// clock edge
	else begin
        if (state == 2'd3) align_count <= align_count + 1;
        else align_count <= align_count;
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
            v_dir[i] <= PE_enable[i] ? v_dir_nxt[i] : 2'd2;
            v_dir_dia[i] <= v_dir[i];
            i_dir[i] <= i_dir_nxt[i];
            d_dir[i] <= d_dir_nxt[i];
        end
        for (i=0; i<16; i=i+1) begin
            start_shift[i] <= start_shift_nxt[i];
        end
        dia_score_first_PE <= dia_score_first_PE_nxt;
        for (j=0; j<mem_length; j=j+1) begin
            min_array[j] <= min_array_nxt[j];
        end
        local_max <= local_max_nxt;
        local_min <= local_min_nxt;
        bias <= bias_nxt;
        finish <= finish_nxt;
        start_position <= start_position_nxt;
        start_position_old <= start_position_old_nxt;
        end_position <= end_position_nxt;
        left_bound_init <= left_bound_init_nxt;
        top_bound_init <= (state == CALC) ? ($signed(top_bound_init) + $signed(g_e_penalty)) : top_bound_init;
        start_on_bound <= start_on_bound_nxt;
        x_max <= x_max_nxt;
        y_max <= y_max_nxt;
        trace_dir <= trace_dir_nxt;
        trace_open <= trace_open_nxt;
        cen <= cen_nxt;
	end
end
endmodule

module max_n_min(
    input [11*64-1:0] v_score_merge,
    output [10:0] o_max,
    output [10:0] o_min,
    output [5:0]  o_x
);

integer i;

reg [10:0] v_score [0:63];
always @(*) begin
    for (i=0; i<64; i=i+1) begin
        v_score[i] = v_score_merge[i*11+:11];
    end
end

// layer 1, 32 comparators
reg [10:0] min_temp_l1 [0:31];
reg [10:0] max_temp_l1 [0:31];
reg [5:0] x_l1 [0:31];
always @(*) begin
    for (i=0; i<32; i=i+1) begin
        min_temp_l1[i] = ($signed(v_score[2*i]) > $signed(v_score[2*i+1])) ? v_score[2*i+1] : v_score[2*i];
        max_temp_l1[i] = ($signed(v_score[2*i]) > $signed(v_score[2*i+1])) ? v_score[2*i] : v_score[2*i+1];
        x_l1[i] = ($signed(v_score[2*i]) > $signed(v_score[2*i+1])) ? (2*i) : (2*i+1);
    end
end
// layer 2, 16 comparators
reg [10:0] min_temp_l2 [0:15];
reg [10:0] max_temp_l2 [0:15];
reg [5:0] x_l2 [0:15];
always @(*) begin
    for (i=0; i<16; i=i+1) begin
        min_temp_l2[i] = ($signed(min_temp_l1[2*i]) < $signed(min_temp_l1[2*i+1])) ? min_temp_l1[2*i] : min_temp_l1[2*i+1];
        max_temp_l2[i] = ($signed(max_temp_l1[2*i]) > $signed(max_temp_l1[2*i+1])) ? max_temp_l1[2*i] : max_temp_l1[2*i+1];
        x_l2[i] = ($signed(max_temp_l1[2*i]) > $signed(max_temp_l1[2*i+1])) ? x_l1[2*i] : x_l1[2*i+1];
    end
end
// layer 3, 8 comparators
reg [10:0] min_temp_l3 [0:7];
reg [10:0] max_temp_l3 [0:7];
reg [5:0] x_l3 [0:7];
always @(*) begin
    for (i=0; i<8; i=i+1) begin
        min_temp_l3[i] = ($signed(min_temp_l2[2*i]) < $signed(min_temp_l2[2*i+1])) ? min_temp_l2[2*i] : min_temp_l2[2*i+1];
        max_temp_l3[i] = ($signed(max_temp_l2[2*i]) > $signed(max_temp_l2[2*i+1])) ? max_temp_l2[2*i] : max_temp_l2[2*i+1];
        x_l3[i] = ($signed(max_temp_l2[2*i]) > $signed(max_temp_l2[2*i+1])) ? x_l2[2*i] : x_l2[2*i+1];
    end
end
// layer 4, 4 comparators
reg [10:0] min_temp_l4 [0:3];
reg [10:0] max_temp_l4 [0:3];
reg [5:0] x_l4 [0:3];
always @(*) begin
    for (i=0; i<4; i=i+1) begin
        min_temp_l4[i] = ($signed(min_temp_l3[2*i]) < $signed(min_temp_l3[2*i+1])) ? min_temp_l3[2*i] : min_temp_l3[2*i+1];
        max_temp_l4[i] = ($signed(max_temp_l3[2*i]) > $signed(max_temp_l3[2*i+1])) ? max_temp_l3[2*i] : max_temp_l3[2*i+1];
        x_l4[i] = ($signed(max_temp_l3[2*i]) > $signed(max_temp_l3[2*i+1])) ? x_l3[2*i] : x_l3[2*i+1];
    end
end
// layer 5, 2 comparators
reg [10:0] min_temp_l5 [0:1];
reg [10:0] max_temp_l5 [0:1];
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