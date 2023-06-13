`timescale 1ns/10ps
`define CYCLE 10

module tb();

integer i;
reg clk;

reg [1:0]  i_A [0:20], i_i_A;
reg [1:0]  i_B [0:20], i_i_B;
reg [13:0] v_d [0:20], i_v_d;
reg [13:0] v_t [0:20], i_v_t;
reg [13:0] v_l [0:20], i_v_l;
reg [13:0] i_l [0:20], i_i_l;
reg [13:0] d_t [0:20], i_d_t;

always begin
  #(`CYCLE/2) clk=~clk;
end

wire [13:0] v_score, i_score, d_score;
wire [1:0] v_direc;
wire i_direc, d_direc;

PE single_PE(
    .i_A(i_i_A),
    .i_B(i_i_B),
    .i_v_diagonal_score(i_v_d), 
    .i_v_top_score(i_v_t),
    .i_v_left_score(i_v_l), 
    .i_i_left_score(i_i_l),
    .i_d_top_score(i_d_t),
    .o_v_score(v_score),
    .o_i_score(i_score),
    .o_d_score(d_score),
    .o_v_direct(v_direc),
    .o_i_direct(i_direc),
    .o_d_direct(d_direc)
);

initial begin     
    $fsdbDumpfile("PE.fsdb");
    $fsdbDumpvars();
    $fsdbDumpMDA;

    $readmemh("./gene_1.txt", i_A);
    $readmemh("./gene_2.txt", i_B);
    $readmemb("./v_d.txt", v_d);
    $readmemb("./v_t.txt", v_t);
    $readmemb("./v_l.txt", v_l);
    $readmemb("./i_l.txt", i_l);
    $readmemb("./d_t.txt", d_t);

    clk = 1'b0;
    #(`CYCLE*2);

    for (i = 0; i < 20; i=i+1) begin
        i_i_A = i_A[i];
        i_i_B = i_B[i];
        i_v_d = v_d[i];
        i_v_t = v_t[i];
        i_v_l = v_l[i];
        i_i_l = i_l[i];
        i_d_t = d_t[i];
        #(`CYCLE*0.5);
        $display($signed(v_score));
        @(negedge clk);
    end

    #(`CYCLE*20);
    $finish;
end

endmodule