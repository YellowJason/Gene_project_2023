module Mem_control (
    input i_clk,
    input cen,
    input wen,
    input [3:0] bank,
    input [8:0] address,
    // 4'b direction
    input [63:0] i_v_0,
    input [63:0] i_v_1,
    input [63:0] i_i,
    input [63:0] i_d,

    output reg [63:0] o_v_0,
    output reg [63:0] o_v_1,
    output reg [63:0] o_i,
    output reg [63:0] o_d
);
integer i;

reg [15:0] wen_bank;
reg [63:0] v_mem_out_0 [0:15], v_mem_out_1 [0:15], i_mem_out [0:15], d_mem_out [0:15];

always @(*) begin
    for (i=0; i<16; i=i+1) begin
        wen_bank[i] = wen | (bank != i[3:0]);
    end
    o_v_0 = v_mem_out_0[bank];
    o_v_1 = v_mem_out_1[bank];
    o_i = i_mem_out[bank];
    o_d = d_mem_out[bank];
end

genvar gv;
generate
    for (gv=0; gv<16; gv=gv+1) begin: V_mem_0
        sram_sp_512x64 V_mem_0(
            .CLK(i_clk),
            .CEN(cen),
            .WEN(wen_bank[gv]),
            .A(address),
            .D(i_v_0),
            .Q(v_mem_out_0[gv]),

            .EMA(3'b0),
            .EMAW(2'b0),
            .EMAS(1'b0),
            .TEN(1'b1),
            .BEN(1'b1),
            .TCEN(1'b1),
            .TWEN(1'b1),
            .TA(9'b0),
            .TD(64'b0),
            .TQ(64'b0),
            .RET1N(1'b1),
            .STOV(1'b0)
        );
    end
    for (gv=0; gv<16; gv=gv+1) begin: V_mem_1
        sram_sp_512x64 V_mem_1(
            .CLK(i_clk),
            .CEN(cen),
            .WEN(wen_bank[gv]),
            .A(address),
            .D(i_v_1),
            .Q(v_mem_out_1[gv]),

            .EMA(3'b0),
            .EMAW(2'b0),
            .EMAS(1'b0),
            .TEN(1'b1),
            .BEN(1'b1),
            .TCEN(1'b1),
            .TWEN(1'b1),
            .TA(9'b0),
            .TD(64'b0),
            .TQ(64'b0),
            .RET1N(1'b1),
            .STOV(1'b0)
        );
    end
    for (gv=0; gv<16; gv=gv+1) begin: I_mem
        sram_sp_512x64 I_mem(
            .CLK(i_clk),
            .CEN(cen),
            .WEN(wen_bank[gv]),
            .A(address),
            .D(i_i),
            .Q(i_mem_out[gv]),

            .EMA(3'b0),
            .EMAW(2'b0),
            .EMAS(1'b0),
            .TEN(1'b1),
            .BEN(1'b1),
            .TCEN(1'b1),
            .TWEN(1'b1),
            .TA(9'b0),
            .TD(64'b0),
            .TQ(64'b0),
            .RET1N(1'b1),
            .STOV(1'b0)
        );
    end
    for (gv=0; gv<16; gv=gv+1) begin: D_mem
        sram_sp_512x64 D_mem(
            .CLK(i_clk),
            .CEN(cen),
            .WEN(wen_bank[gv]),
            .A(address),
            .D(i_d),
            .Q(d_mem_out[gv]),

            .EMA(3'b0),
            .EMAW(2'b0),
            .EMAS(1'b0),
            .TEN(1'b1),
            .BEN(1'b1),
            .TCEN(1'b1),
            .TWEN(1'b1),
            .TA(9'b0),
            .TD(64'b0),
            .TQ(64'b0),
            .RET1N(1'b1),
            .STOV(1'b0)
        );
    end
endgenerate

endmodule