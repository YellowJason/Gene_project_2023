`timescale 1ns/1ps
`define CYCLE 10
`define SDFFILE "./synthesis/Netlist/PE_array_64_syn.sdf"

`ifdef tb0
    `define GENE1 "./test_data/gene_1_array_10.txt"
    `define GENE2 "./test_data/gene_2_array_10.txt"
    `define ALIGN "./test_data/align_10.txt"
`elsif tb1
    `define GENE1 "./test_data/gene_1_array_1.txt"
    `define GENE2 "./test_data/gene_2_array_1.txt"
    `define ALIGN "./test_data/align_1.txt"
`elsif tb2
    `define GENE1 "./test_data/gene_1_array_2.txt"
    `define GENE2 "./test_data/gene_2_array_2.txt"
    `define ALIGN "./test_data/align_2.txt"
`elsif tb3
    `define GENE1 "./test_data/gene_1_array_3.txt"
    `define GENE2 "./test_data/gene_2_array_3.txt"
    `define ALIGN "./test_data/align_3.txt"
`elsif tb4
    `define GENE1 "./test_data/gene_1_array_4.txt"
    `define GENE2 "./test_data/gene_2_array_4.txt"
    `define ALIGN "./test_data/align_4.txt"
`else
    `define GENE1 "./test_data/gene_1_array_10.txt"
    `define GENE2 "./test_data/gene_2_array_10.txt"
    `define ALIGN "./test_data/align_10.txt"
`endif

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

logic [8:0] error_count;
// always @(*) begin
//     for (i=0; i<64; i=i+1) begin
//         i_i_B[2*i+:2] = i_B[i]; 
//     end
// end

`ifdef SDF
    initial $sdf_annotate(`SDFFILE, PE0);
    initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

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
    input [5:0] k; // num of stripe

    i_start = 1'b0;

    for (i=0; i<64; i=i+1) begin
        i_i_B[2*i+:2] = i_B[i+(k*64)];
    end
    #(`CYCLE*1);

    $display("----------stripe ", k, "----------");
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

    $readmemh(`GENE2, i_A);
    $readmemh(`GENE1, i_B);
    $readmemh(`ALIGN, align_gold);

    clk = 1'b0;
    rst = 1'b0;
    i_start = 1'b0;
    start_position_reg = 10'b0;
    #(`CYCLE*1);
    rst = 1'b1;
    #(`CYCLE*2);
    rst = 1'b0;
    error_count = 9'b0;

    for (k=0; k<16; k=k+1) begin
        run_new_stripe(k);
    end

    // Trace back
    @(negedge stripe_end);
    for (i=0; i<2048; i=i+1) begin
        @(negedge clk);
        if (align_gold[i] === trace_dir) begin
            $display(i[10:0], " Trace currect ! ", trace_dir);
        end
        else begin
            $display(i[10:0], " Trace wrong ! Answer: ", align_gold[i], ", Yours: ", trace_dir);
            error_count = error_count + 1;
        end
        if (stripe_end) begin
            break;
        end
        #(`CYCLE*0.5);
    end

    $display("Total errors:", error_count);

    #(`CYCLE*10);
    $finish;
end

endmodule