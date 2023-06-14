`timescale 1ns/10ps
`define CYCLE 10

module tb();

integer i;
reg clk, rst, i_start;

reg [1:0] i_A [0:64], i_i_A;
reg [1:0] i_B [0:64];

reg [127:0] i_i_B;
always @(*) begin
    for (i=0; i<64; i=i+1) begin
        i_i_B[2*i+:2] = i_B[i]; 
    end
end

always begin
  #(`CYCLE/2) clk=~clk;
end

PE_array PE0(
    .i_clk(clk),
    .i_rst(rst),
    .i_start(i_start),
    .i_B(i_i_B),
    .i_A(i_i_A)
);

initial begin     
    $fsdbDumpfile("PE_array.fsdb");
    $fsdbDumpvars();
    $fsdbDumpMDA;

    $readmemh("./gene_1_array.txt", i_A);
    $readmemh("./gene_2_array.txt", i_B);

    clk = 1'b0;
    rst = 1'b0;
    i_start = 1'b0;
    #(`CYCLE*1);
    rst = 1'b1;
    #(`CYCLE*2);
    rst = 1'b0;
    #(`CYCLE*1);

    for (i = 0; i < 64; i=i+1) begin
        i_start = 1'b1;
        i_i_A = i_A[i];
        #(`CYCLE*0.1);
        @(negedge clk);
    end
    i_start = 1'b0;

    #(`CYCLE*20);
    $finish;
end

endmodule