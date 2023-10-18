`timescale 1ns/10ps
`define CYCLE 100

module tb;

integer i, j, k;

logic clk, rst, i_start;
logic stripe_end;
logic [9:0] start_position, start_position_reg, end_position;

logic [1:0] i_A [0:1023], i_i_A;
logic [1:0] i_B [0:1023];
logic [1:0] align_gold [0:2047];

logic [127:0] i_i_B;

logic [13:0] max;
logic [1:0] trace_dir;

// always @(*) begin
//     for (i=0; i<64; i=i+1) begin
//         i_i_B[2*i+:2] = i_B[i]; 
//     end
// end

always begin
  #(`CYCLE/2) clk=~clk;
end

PE_array_64 PE0(
    .i_clk(clk),
    .i_rst(rst),
    .i_start(i_start),

    .i_B(i_i_B),
    .i_A(i_i_A),
    .o_stripe_end(stripe_end),
    .o_start_position(start_position),
    .o_end_position(end_position),
    .o_max_score_stripe(max),
    .o_trace_dir(trace_dir)
);

task run_new_stripe;
    input [9:0] k; // num of stripe

    i_start = 1'b0;

    for (i=0; i<64; i=i+1) begin
        i_i_B[2*i+:2] = i_B[i+(k*64)];
    end
    #(`CYCLE*1);

    $display("----------stripe", k, "----------");
    $display("start position:", start_position_reg);
    // j may > 1024 when state == EVAL
    for (j = start_position_reg; j < 2000; j=j+1) begin
        if (stripe_end == 1'b1) begin
            start_position_reg <= start_position_reg + start_position;
            $display("end position:", {1'b0, end_position}+{1'b0, start_position_reg});
            $display("max score:", max);
            break;
        end
        
        i_start = (j < 1024) ? 1'b1 : 1'b0;
        i_i_A = (j < 1024) ? i_A[j] : 2'b0;
        #(`CYCLE*0.1);
        @(negedge clk);
    end
endtask

initial begin     
    $fsdbDumpfile("PE_array.fsdb");
    $fsdbDumpvars();
    $fsdbDumpMDA;

    $readmemh("./gene_2_array.txt", i_A);
    $readmemh("./gene_1_array.txt", i_B);
    $readmemh("./align.txt", align_gold);

    clk = 1'b0;
    rst = 1'b0;
    i_start = 1'b0;
    start_position_reg = 10'b0;
    #(`CYCLE*1);
    rst = 1'b1;
    #(`CYCLE*2);
    rst = 1'b0;

    for (k=0; k<16; k=k+1) begin
        run_new_stripe(k);
    end

    // Trace back
    @(negedge stripe_end);
    for (i=0; i<2048; i=i+1) begin
        @(negedge clk);
        if (stripe_end) begin
            break;
        end
        if (align_gold[i] === trace_dir) begin
            $display("Trace currect ! ", trace_dir);
        end
        else begin
            $display("Trace wrong ! Answer: ", align_gold[i], ", Yours: ", trace_dir);
        end
        #(`CYCLE*0.5);
    end

    #(`CYCLE*10);
    $finish;
end

endmodule