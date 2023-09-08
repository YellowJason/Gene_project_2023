`timescale 1ns/10ps
`define CYCLE 100

module tb;

integer i;
integer j;

logic clk, rst, i_start;
logic stripe_end;
logic [9:0] start_position, start_position_reg;

logic [1:0] i_A [0:1023], i_i_A;
logic [1:0] i_B [0:1023];

logic [127:0] i_i_B;

logic [13:0] max;

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
    .o_max_score_stripe(max)
);

initial begin     
    $fsdbDumpfile("PE_array.fsdb");
    $fsdbDumpvars();
    $fsdbDumpMDA;

    $readmemh("./gene_2_array.txt", i_A);
    $readmemh("./gene_1_array.txt", i_B);

    clk = 1'b0;
    rst = 1'b0;
    i_start = 1'b0;
    #(`CYCLE*1);
    rst = 1'b1;
    #(`CYCLE*2);
    rst = 1'b0;
    for (i=0; i<64; i=i+1) begin
        i_i_B[2*i+:2] = i_B[i]; 
    end
    #(`CYCLE*1);

    $display("start position: ", start_position_reg);
    for (j = 0; j < 1024; j=j+1) begin
        if (stripe_end == 1'b1) begin
            start_position_reg = start_position+1;
            $display("end position: ", j);
            $display("max score: ", max);
            break;
        end
        $display(j);
        i_start = 1'b1;
        i_i_A = i_A[j];
        #(`CYCLE*0.1);
        @(negedge clk);
    end

    i_start = 1'b0;
    for (i=0; i<64; i=i+1) begin
        i_i_B[2*i+:2] = i_B[i+64]; 
    end
    #(`CYCLE*5);

    $display("start position: ", start_position_reg);
    for (j = start_position_reg; j < 1024; j=j+1) begin
        if (stripe_end == 1'b1) begin
            start_position_reg = start_position;
            $display("end position: ", j);
            $display("max score: ", max);
            break;
        end
        $display(j);
        i_start = 1'b1;
        i_i_A = i_A[j];
        #(`CYCLE*0.1);
        @(negedge clk);
    end

    #(`CYCLE*100);
    $finish;
end

endmodule