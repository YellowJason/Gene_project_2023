/* FE Release Version: 3.4.22 */
/* lang compiler Version: 3.0.4 */
//
//       CONFIDENTIAL AND PROPRIETARY SOFTWARE OF ARM PHYSICAL IP, INC.
//      
//       Copyright (c) 1993 - 2023 ARM Physical IP, Inc.  All Rights Reserved.
//      
//       Use of this Software is subject to the terms and conditions of the
//       applicable license agreement with ARM Physical IP, Inc.
//       In addition, this Software is protected by patents, copyright law 
//       and international treaties.
//      
//       The copyright notice(s) in this Software does not indicate actual or
//       intended publication of this Software.
//
//      Verilog model for Synchronous Single-Port Ram
//
//       Instance Name:              sram_sp_512x64
//       Words:                      512
//       Bits:                       64
//       Mux:                        16
//       Drive:                      6
//       Write Mask:                 Off
//       Write Thru:                 On
//       Extra Margin Adjustment:    On
//       Redundant Rows:             0
//       Redundant Columns:          0
//       Test Muxes                  On
//       Power Gating:               Off
//       Retention:                  On
//       Pipeline:                   Off
//       Weak Bit Test:	        Off
//       Read Disturb Test:	        Off
//       
//       Creation Date:  Mon Oct 23 16:32:02 2023
//       Version: 	r11p2
//
//      Modeling Assumptions: This model supports full gate level simulation
//          including proper x-handling and timing check behavior.  Unit
//          delay timing is included in the model. Back-annotation of SDF
//          (v3.0 or v2.1) is supported.  SDF can be created utilyzing the delay
//          calculation views provided with this generator and supported
//          delay calculators.  All buses are modeled [MSB:LSB].  All 
//          ports are padded with Verilog primitives.
//
//      Modeling Limitations: None.
//
//      Known Bugs: None.
//
//      Known Work Arounds: N/A
//
`timescale 1 ns/1 ps
// If ARM_UD_MODEL is defined at Simulator Command Line, it Selects the Fast Functional Model
`ifdef ARM_UD_MODEL

// Following parameter Values can be overridden at Simulator Command Line.

// ARM_UD_DP Defines the delay through Data Paths, for Memory Models it represents BIST MUX output delays.
`ifdef ARM_UD_DP
`else
`define ARM_UD_DP #0.001
`endif
// ARM_UD_CP Defines the delay through Clock Path Cells, for Memory Models it is not used.
`ifdef ARM_UD_CP
`else
`define ARM_UD_CP
`endif
// ARM_UD_SEQ Defines the delay through the Memory, for Memory Models it is used for CLK->Q delays.
`ifdef ARM_UD_SEQ
`else
`define ARM_UD_SEQ #0.01
`endif

`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module sram_sp_512x64 (VDDCE, VDDPE, VSSE, CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A,
    D, EMA, EMAW, EMAS, TEN, BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`else
module sram_sp_512x64 (CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A, D, EMA, EMAW, EMAS,
    TEN, BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 64;
  parameter WORDS = 512;
  parameter MUX = 16;
  parameter MEM_WIDTH = 1024; // redun block size 4, 512 on left, 512 on right
  parameter MEM_HEIGHT = 32;
  parameter WP_SIZE = 64 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 1;

  output  CENY;
  output  WENY;
  output [8:0] AY;
  output [63:0] DY;
  output [63:0] Q;
  input  CLK;
  input  CEN;
  input  WEN;
  input [8:0] A;
  input [63:0] D;
  input [2:0] EMA;
  input [1:0] EMAW;
  input  EMAS;
  input  TEN;
  input  BEN;
  input  TCEN;
  input  TWEN;
  input [8:0] TA;
  input [63:0] TD;
  input [63:0] TQ;
  input  RET1N;
  input  STOV;
`ifdef POWER_PINS
  inout VDDCE;
  inout VDDPE;
  inout VSSE;
`endif

  integer row_address;
  integer mux_address;
  reg [1023:0] mem [0:31];
  reg [1023:0] row;
  reg LAST_CLK;
  reg [1023:0] row_mask;
  reg [1023:0] new_data;
  reg [1023:0] data_out;
  reg [255:0] readLatch0;
  reg [255:0] shifted_readLatch0;
  reg [1:0] read_mux_sel0;
  reg [63:0] Q_int;
  reg [63:0] Q_int_delayed;
  reg [63:0] writeEnable;

  reg NOT_CEN, NOT_WEN, NOT_A8, NOT_A7, NOT_A6, NOT_A5, NOT_A4, NOT_A3, NOT_A2, NOT_A1;
  reg NOT_A0, NOT_D63, NOT_D62, NOT_D61, NOT_D60, NOT_D59, NOT_D58, NOT_D57, NOT_D56;
  reg NOT_D55, NOT_D54, NOT_D53, NOT_D52, NOT_D51, NOT_D50, NOT_D49, NOT_D48, NOT_D47;
  reg NOT_D46, NOT_D45, NOT_D44, NOT_D43, NOT_D42, NOT_D41, NOT_D40, NOT_D39, NOT_D38;
  reg NOT_D37, NOT_D36, NOT_D35, NOT_D34, NOT_D33, NOT_D32, NOT_D31, NOT_D30, NOT_D29;
  reg NOT_D28, NOT_D27, NOT_D26, NOT_D25, NOT_D24, NOT_D23, NOT_D22, NOT_D21, NOT_D20;
  reg NOT_D19, NOT_D18, NOT_D17, NOT_D16, NOT_D15, NOT_D14, NOT_D13, NOT_D12, NOT_D11;
  reg NOT_D10, NOT_D9, NOT_D8, NOT_D7, NOT_D6, NOT_D5, NOT_D4, NOT_D3, NOT_D2, NOT_D1;
  reg NOT_D0, NOT_EMA2, NOT_EMA1, NOT_EMA0, NOT_EMAW1, NOT_EMAW0, NOT_EMAS, NOT_TEN;
  reg NOT_TCEN, NOT_TWEN, NOT_TA8, NOT_TA7, NOT_TA6, NOT_TA5, NOT_TA4, NOT_TA3, NOT_TA2;
  reg NOT_TA1, NOT_TA0, NOT_TD63, NOT_TD62, NOT_TD61, NOT_TD60, NOT_TD59, NOT_TD58;
  reg NOT_TD57, NOT_TD56, NOT_TD55, NOT_TD54, NOT_TD53, NOT_TD52, NOT_TD51, NOT_TD50;
  reg NOT_TD49, NOT_TD48, NOT_TD47, NOT_TD46, NOT_TD45, NOT_TD44, NOT_TD43, NOT_TD42;
  reg NOT_TD41, NOT_TD40, NOT_TD39, NOT_TD38, NOT_TD37, NOT_TD36, NOT_TD35, NOT_TD34;
  reg NOT_TD33, NOT_TD32, NOT_TD31, NOT_TD30, NOT_TD29, NOT_TD28, NOT_TD27, NOT_TD26;
  reg NOT_TD25, NOT_TD24, NOT_TD23, NOT_TD22, NOT_TD21, NOT_TD20, NOT_TD19, NOT_TD18;
  reg NOT_TD17, NOT_TD16, NOT_TD15, NOT_TD14, NOT_TD13, NOT_TD12, NOT_TD11, NOT_TD10;
  reg NOT_TD9, NOT_TD8, NOT_TD7, NOT_TD6, NOT_TD5, NOT_TD4, NOT_TD3, NOT_TD2, NOT_TD1;
  reg NOT_TD0, NOT_RET1N, NOT_STOV;
  reg NOT_CLK_PER, NOT_CLK_MINH, NOT_CLK_MINL;
  reg clk0_int;

  wire  CENY_;
  wire  WENY_;
  wire [8:0] AY_;
  wire [63:0] DY_;
  wire [63:0] Q_;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire  WEN_;
  reg  WEN_int;
  wire [8:0] A_;
  reg [8:0] A_int;
  wire [63:0] D_;
  reg [63:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  EMAS_;
  reg  EMAS_int;
  wire  TEN_;
  reg  TEN_int;
  wire  BEN_;
  reg  BEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire  TWEN_;
  reg  TWEN_int;
  wire [8:0] TA_;
  reg [8:0] TA_int;
  wire [63:0] TD_;
  reg [63:0] TD_int;
  wire [63:0] TQ_;
  reg [63:0] TQ_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire  STOV_;
  reg  STOV_int;

  assign CENY = CENY_; 
  assign WENY = WENY_; 
  assign AY[0] = AY_[0]; 
  assign AY[1] = AY_[1]; 
  assign AY[2] = AY_[2]; 
  assign AY[3] = AY_[3]; 
  assign AY[4] = AY_[4]; 
  assign AY[5] = AY_[5]; 
  assign AY[6] = AY_[6]; 
  assign AY[7] = AY_[7]; 
  assign AY[8] = AY_[8]; 
  assign DY[0] = DY_[0]; 
  assign DY[1] = DY_[1]; 
  assign DY[2] = DY_[2]; 
  assign DY[3] = DY_[3]; 
  assign DY[4] = DY_[4]; 
  assign DY[5] = DY_[5]; 
  assign DY[6] = DY_[6]; 
  assign DY[7] = DY_[7]; 
  assign DY[8] = DY_[8]; 
  assign DY[9] = DY_[9]; 
  assign DY[10] = DY_[10]; 
  assign DY[11] = DY_[11]; 
  assign DY[12] = DY_[12]; 
  assign DY[13] = DY_[13]; 
  assign DY[14] = DY_[14]; 
  assign DY[15] = DY_[15]; 
  assign DY[16] = DY_[16]; 
  assign DY[17] = DY_[17]; 
  assign DY[18] = DY_[18]; 
  assign DY[19] = DY_[19]; 
  assign DY[20] = DY_[20]; 
  assign DY[21] = DY_[21]; 
  assign DY[22] = DY_[22]; 
  assign DY[23] = DY_[23]; 
  assign DY[24] = DY_[24]; 
  assign DY[25] = DY_[25]; 
  assign DY[26] = DY_[26]; 
  assign DY[27] = DY_[27]; 
  assign DY[28] = DY_[28]; 
  assign DY[29] = DY_[29]; 
  assign DY[30] = DY_[30]; 
  assign DY[31] = DY_[31]; 
  assign DY[32] = DY_[32]; 
  assign DY[33] = DY_[33]; 
  assign DY[34] = DY_[34]; 
  assign DY[35] = DY_[35]; 
  assign DY[36] = DY_[36]; 
  assign DY[37] = DY_[37]; 
  assign DY[38] = DY_[38]; 
  assign DY[39] = DY_[39]; 
  assign DY[40] = DY_[40]; 
  assign DY[41] = DY_[41]; 
  assign DY[42] = DY_[42]; 
  assign DY[43] = DY_[43]; 
  assign DY[44] = DY_[44]; 
  assign DY[45] = DY_[45]; 
  assign DY[46] = DY_[46]; 
  assign DY[47] = DY_[47]; 
  assign DY[48] = DY_[48]; 
  assign DY[49] = DY_[49]; 
  assign DY[50] = DY_[50]; 
  assign DY[51] = DY_[51]; 
  assign DY[52] = DY_[52]; 
  assign DY[53] = DY_[53]; 
  assign DY[54] = DY_[54]; 
  assign DY[55] = DY_[55]; 
  assign DY[56] = DY_[56]; 
  assign DY[57] = DY_[57]; 
  assign DY[58] = DY_[58]; 
  assign DY[59] = DY_[59]; 
  assign DY[60] = DY_[60]; 
  assign DY[61] = DY_[61]; 
  assign DY[62] = DY_[62]; 
  assign DY[63] = DY_[63]; 
  assign Q[0] = Q_[0]; 
  assign Q[1] = Q_[1]; 
  assign Q[2] = Q_[2]; 
  assign Q[3] = Q_[3]; 
  assign Q[4] = Q_[4]; 
  assign Q[5] = Q_[5]; 
  assign Q[6] = Q_[6]; 
  assign Q[7] = Q_[7]; 
  assign Q[8] = Q_[8]; 
  assign Q[9] = Q_[9]; 
  assign Q[10] = Q_[10]; 
  assign Q[11] = Q_[11]; 
  assign Q[12] = Q_[12]; 
  assign Q[13] = Q_[13]; 
  assign Q[14] = Q_[14]; 
  assign Q[15] = Q_[15]; 
  assign Q[16] = Q_[16]; 
  assign Q[17] = Q_[17]; 
  assign Q[18] = Q_[18]; 
  assign Q[19] = Q_[19]; 
  assign Q[20] = Q_[20]; 
  assign Q[21] = Q_[21]; 
  assign Q[22] = Q_[22]; 
  assign Q[23] = Q_[23]; 
  assign Q[24] = Q_[24]; 
  assign Q[25] = Q_[25]; 
  assign Q[26] = Q_[26]; 
  assign Q[27] = Q_[27]; 
  assign Q[28] = Q_[28]; 
  assign Q[29] = Q_[29]; 
  assign Q[30] = Q_[30]; 
  assign Q[31] = Q_[31]; 
  assign Q[32] = Q_[32]; 
  assign Q[33] = Q_[33]; 
  assign Q[34] = Q_[34]; 
  assign Q[35] = Q_[35]; 
  assign Q[36] = Q_[36]; 
  assign Q[37] = Q_[37]; 
  assign Q[38] = Q_[38]; 
  assign Q[39] = Q_[39]; 
  assign Q[40] = Q_[40]; 
  assign Q[41] = Q_[41]; 
  assign Q[42] = Q_[42]; 
  assign Q[43] = Q_[43]; 
  assign Q[44] = Q_[44]; 
  assign Q[45] = Q_[45]; 
  assign Q[46] = Q_[46]; 
  assign Q[47] = Q_[47]; 
  assign Q[48] = Q_[48]; 
  assign Q[49] = Q_[49]; 
  assign Q[50] = Q_[50]; 
  assign Q[51] = Q_[51]; 
  assign Q[52] = Q_[52]; 
  assign Q[53] = Q_[53]; 
  assign Q[54] = Q_[54]; 
  assign Q[55] = Q_[55]; 
  assign Q[56] = Q_[56]; 
  assign Q[57] = Q_[57]; 
  assign Q[58] = Q_[58]; 
  assign Q[59] = Q_[59]; 
  assign Q[60] = Q_[60]; 
  assign Q[61] = Q_[61]; 
  assign Q[62] = Q_[62]; 
  assign Q[63] = Q_[63]; 
  assign CLK_ = CLK;
  assign CEN_ = CEN;
  assign WEN_ = WEN;
  assign A_[0] = A[0];
  assign A_[1] = A[1];
  assign A_[2] = A[2];
  assign A_[3] = A[3];
  assign A_[4] = A[4];
  assign A_[5] = A[5];
  assign A_[6] = A[6];
  assign A_[7] = A[7];
  assign A_[8] = A[8];
  assign D_[0] = D[0];
  assign D_[1] = D[1];
  assign D_[2] = D[2];
  assign D_[3] = D[3];
  assign D_[4] = D[4];
  assign D_[5] = D[5];
  assign D_[6] = D[6];
  assign D_[7] = D[7];
  assign D_[8] = D[8];
  assign D_[9] = D[9];
  assign D_[10] = D[10];
  assign D_[11] = D[11];
  assign D_[12] = D[12];
  assign D_[13] = D[13];
  assign D_[14] = D[14];
  assign D_[15] = D[15];
  assign D_[16] = D[16];
  assign D_[17] = D[17];
  assign D_[18] = D[18];
  assign D_[19] = D[19];
  assign D_[20] = D[20];
  assign D_[21] = D[21];
  assign D_[22] = D[22];
  assign D_[23] = D[23];
  assign D_[24] = D[24];
  assign D_[25] = D[25];
  assign D_[26] = D[26];
  assign D_[27] = D[27];
  assign D_[28] = D[28];
  assign D_[29] = D[29];
  assign D_[30] = D[30];
  assign D_[31] = D[31];
  assign D_[32] = D[32];
  assign D_[33] = D[33];
  assign D_[34] = D[34];
  assign D_[35] = D[35];
  assign D_[36] = D[36];
  assign D_[37] = D[37];
  assign D_[38] = D[38];
  assign D_[39] = D[39];
  assign D_[40] = D[40];
  assign D_[41] = D[41];
  assign D_[42] = D[42];
  assign D_[43] = D[43];
  assign D_[44] = D[44];
  assign D_[45] = D[45];
  assign D_[46] = D[46];
  assign D_[47] = D[47];
  assign D_[48] = D[48];
  assign D_[49] = D[49];
  assign D_[50] = D[50];
  assign D_[51] = D[51];
  assign D_[52] = D[52];
  assign D_[53] = D[53];
  assign D_[54] = D[54];
  assign D_[55] = D[55];
  assign D_[56] = D[56];
  assign D_[57] = D[57];
  assign D_[58] = D[58];
  assign D_[59] = D[59];
  assign D_[60] = D[60];
  assign D_[61] = D[61];
  assign D_[62] = D[62];
  assign D_[63] = D[63];
  assign EMA_[0] = EMA[0];
  assign EMA_[1] = EMA[1];
  assign EMA_[2] = EMA[2];
  assign EMAW_[0] = EMAW[0];
  assign EMAW_[1] = EMAW[1];
  assign EMAS_ = EMAS;
  assign TEN_ = TEN;
  assign BEN_ = BEN;
  assign TCEN_ = TCEN;
  assign TWEN_ = TWEN;
  assign TA_[0] = TA[0];
  assign TA_[1] = TA[1];
  assign TA_[2] = TA[2];
  assign TA_[3] = TA[3];
  assign TA_[4] = TA[4];
  assign TA_[5] = TA[5];
  assign TA_[6] = TA[6];
  assign TA_[7] = TA[7];
  assign TA_[8] = TA[8];
  assign TD_[0] = TD[0];
  assign TD_[1] = TD[1];
  assign TD_[2] = TD[2];
  assign TD_[3] = TD[3];
  assign TD_[4] = TD[4];
  assign TD_[5] = TD[5];
  assign TD_[6] = TD[6];
  assign TD_[7] = TD[7];
  assign TD_[8] = TD[8];
  assign TD_[9] = TD[9];
  assign TD_[10] = TD[10];
  assign TD_[11] = TD[11];
  assign TD_[12] = TD[12];
  assign TD_[13] = TD[13];
  assign TD_[14] = TD[14];
  assign TD_[15] = TD[15];
  assign TD_[16] = TD[16];
  assign TD_[17] = TD[17];
  assign TD_[18] = TD[18];
  assign TD_[19] = TD[19];
  assign TD_[20] = TD[20];
  assign TD_[21] = TD[21];
  assign TD_[22] = TD[22];
  assign TD_[23] = TD[23];
  assign TD_[24] = TD[24];
  assign TD_[25] = TD[25];
  assign TD_[26] = TD[26];
  assign TD_[27] = TD[27];
  assign TD_[28] = TD[28];
  assign TD_[29] = TD[29];
  assign TD_[30] = TD[30];
  assign TD_[31] = TD[31];
  assign TD_[32] = TD[32];
  assign TD_[33] = TD[33];
  assign TD_[34] = TD[34];
  assign TD_[35] = TD[35];
  assign TD_[36] = TD[36];
  assign TD_[37] = TD[37];
  assign TD_[38] = TD[38];
  assign TD_[39] = TD[39];
  assign TD_[40] = TD[40];
  assign TD_[41] = TD[41];
  assign TD_[42] = TD[42];
  assign TD_[43] = TD[43];
  assign TD_[44] = TD[44];
  assign TD_[45] = TD[45];
  assign TD_[46] = TD[46];
  assign TD_[47] = TD[47];
  assign TD_[48] = TD[48];
  assign TD_[49] = TD[49];
  assign TD_[50] = TD[50];
  assign TD_[51] = TD[51];
  assign TD_[52] = TD[52];
  assign TD_[53] = TD[53];
  assign TD_[54] = TD[54];
  assign TD_[55] = TD[55];
  assign TD_[56] = TD[56];
  assign TD_[57] = TD[57];
  assign TD_[58] = TD[58];
  assign TD_[59] = TD[59];
  assign TD_[60] = TD[60];
  assign TD_[61] = TD[61];
  assign TD_[62] = TD[62];
  assign TD_[63] = TD[63];
  assign TQ_[0] = TQ[0];
  assign TQ_[1] = TQ[1];
  assign TQ_[2] = TQ[2];
  assign TQ_[3] = TQ[3];
  assign TQ_[4] = TQ[4];
  assign TQ_[5] = TQ[5];
  assign TQ_[6] = TQ[6];
  assign TQ_[7] = TQ[7];
  assign TQ_[8] = TQ[8];
  assign TQ_[9] = TQ[9];
  assign TQ_[10] = TQ[10];
  assign TQ_[11] = TQ[11];
  assign TQ_[12] = TQ[12];
  assign TQ_[13] = TQ[13];
  assign TQ_[14] = TQ[14];
  assign TQ_[15] = TQ[15];
  assign TQ_[16] = TQ[16];
  assign TQ_[17] = TQ[17];
  assign TQ_[18] = TQ[18];
  assign TQ_[19] = TQ[19];
  assign TQ_[20] = TQ[20];
  assign TQ_[21] = TQ[21];
  assign TQ_[22] = TQ[22];
  assign TQ_[23] = TQ[23];
  assign TQ_[24] = TQ[24];
  assign TQ_[25] = TQ[25];
  assign TQ_[26] = TQ[26];
  assign TQ_[27] = TQ[27];
  assign TQ_[28] = TQ[28];
  assign TQ_[29] = TQ[29];
  assign TQ_[30] = TQ[30];
  assign TQ_[31] = TQ[31];
  assign TQ_[32] = TQ[32];
  assign TQ_[33] = TQ[33];
  assign TQ_[34] = TQ[34];
  assign TQ_[35] = TQ[35];
  assign TQ_[36] = TQ[36];
  assign TQ_[37] = TQ[37];
  assign TQ_[38] = TQ[38];
  assign TQ_[39] = TQ[39];
  assign TQ_[40] = TQ[40];
  assign TQ_[41] = TQ[41];
  assign TQ_[42] = TQ[42];
  assign TQ_[43] = TQ[43];
  assign TQ_[44] = TQ[44];
  assign TQ_[45] = TQ[45];
  assign TQ_[46] = TQ[46];
  assign TQ_[47] = TQ[47];
  assign TQ_[48] = TQ[48];
  assign TQ_[49] = TQ[49];
  assign TQ_[50] = TQ[50];
  assign TQ_[51] = TQ[51];
  assign TQ_[52] = TQ[52];
  assign TQ_[53] = TQ[53];
  assign TQ_[54] = TQ[54];
  assign TQ_[55] = TQ[55];
  assign TQ_[56] = TQ[56];
  assign TQ_[57] = TQ[57];
  assign TQ_[58] = TQ[58];
  assign TQ_[59] = TQ[59];
  assign TQ_[60] = TQ[60];
  assign TQ_[61] = TQ[61];
  assign TQ_[62] = TQ[62];
  assign TQ_[63] = TQ[63];
  assign RET1N_ = RET1N;
  assign STOV_ = STOV;

  assign `ARM_UD_DP CENY_ = RET1N_ ? (TEN_ ? CEN_ : TCEN_) : 1'bx;
  assign `ARM_UD_DP WENY_ = RET1N_ ? (TEN_ ? WEN_ : TWEN_) : 1'bx;
  assign `ARM_UD_DP AY_ = RET1N_ ? (TEN_ ? A_ : TA_) : {9{1'bx}};
  assign `ARM_UD_DP DY_ = RET1N_ ? (TEN_ ? D_ : TD_) : {64{1'bx}};
  assign `ARM_UD_SEQ Q_ = RET1N_ ? (BEN_ ? ((STOV_ ? (Q_int_delayed) : (Q_int))) : TQ_) : {64{1'bx}};

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
`endif

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval==1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction


task loadmem;
	input [1000*8-1:0] filename;
	reg [BITS-1:0] memld [0:WORDS-1];
	integer i;
	reg [BITS-1:0] wordtemp;
	reg [8:0] Atemp;
  begin
	$readmemb(filename, memld);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  wordtemp = memld[i];
	  Atemp = i;
	  mux_address = (Atemp & 4'b1111);
      row_address = (Atemp >> 4);
      row = mem[row_address];
        writeEnable = {64{1'b1}};
        row_mask =  ( {15'b000000000000000, writeEnable[63], 15'b000000000000000, writeEnable[62],
          15'b000000000000000, writeEnable[61], 15'b000000000000000, writeEnable[60],
          15'b000000000000000, writeEnable[59], 15'b000000000000000, writeEnable[58],
          15'b000000000000000, writeEnable[57], 15'b000000000000000, writeEnable[56],
          15'b000000000000000, writeEnable[55], 15'b000000000000000, writeEnable[54],
          15'b000000000000000, writeEnable[53], 15'b000000000000000, writeEnable[52],
          15'b000000000000000, writeEnable[51], 15'b000000000000000, writeEnable[50],
          15'b000000000000000, writeEnable[49], 15'b000000000000000, writeEnable[48],
          15'b000000000000000, writeEnable[47], 15'b000000000000000, writeEnable[46],
          15'b000000000000000, writeEnable[45], 15'b000000000000000, writeEnable[44],
          15'b000000000000000, writeEnable[43], 15'b000000000000000, writeEnable[42],
          15'b000000000000000, writeEnable[41], 15'b000000000000000, writeEnable[40],
          15'b000000000000000, writeEnable[39], 15'b000000000000000, writeEnable[38],
          15'b000000000000000, writeEnable[37], 15'b000000000000000, writeEnable[36],
          15'b000000000000000, writeEnable[35], 15'b000000000000000, writeEnable[34],
          15'b000000000000000, writeEnable[33], 15'b000000000000000, writeEnable[32],
          15'b000000000000000, writeEnable[31], 15'b000000000000000, writeEnable[30],
          15'b000000000000000, writeEnable[29], 15'b000000000000000, writeEnable[28],
          15'b000000000000000, writeEnable[27], 15'b000000000000000, writeEnable[26],
          15'b000000000000000, writeEnable[25], 15'b000000000000000, writeEnable[24],
          15'b000000000000000, writeEnable[23], 15'b000000000000000, writeEnable[22],
          15'b000000000000000, writeEnable[21], 15'b000000000000000, writeEnable[20],
          15'b000000000000000, writeEnable[19], 15'b000000000000000, writeEnable[18],
          15'b000000000000000, writeEnable[17], 15'b000000000000000, writeEnable[16],
          15'b000000000000000, writeEnable[15], 15'b000000000000000, writeEnable[14],
          15'b000000000000000, writeEnable[13], 15'b000000000000000, writeEnable[12],
          15'b000000000000000, writeEnable[11], 15'b000000000000000, writeEnable[10],
          15'b000000000000000, writeEnable[9], 15'b000000000000000, writeEnable[8],
          15'b000000000000000, writeEnable[7], 15'b000000000000000, writeEnable[6],
          15'b000000000000000, writeEnable[5], 15'b000000000000000, writeEnable[4],
          15'b000000000000000, writeEnable[3], 15'b000000000000000, writeEnable[2],
          15'b000000000000000, writeEnable[1], 15'b000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {15'b000000000000000, wordtemp[63], 15'b000000000000000, wordtemp[62],
          15'b000000000000000, wordtemp[61], 15'b000000000000000, wordtemp[60], 15'b000000000000000, wordtemp[59],
          15'b000000000000000, wordtemp[58], 15'b000000000000000, wordtemp[57], 15'b000000000000000, wordtemp[56],
          15'b000000000000000, wordtemp[55], 15'b000000000000000, wordtemp[54], 15'b000000000000000, wordtemp[53],
          15'b000000000000000, wordtemp[52], 15'b000000000000000, wordtemp[51], 15'b000000000000000, wordtemp[50],
          15'b000000000000000, wordtemp[49], 15'b000000000000000, wordtemp[48], 15'b000000000000000, wordtemp[47],
          15'b000000000000000, wordtemp[46], 15'b000000000000000, wordtemp[45], 15'b000000000000000, wordtemp[44],
          15'b000000000000000, wordtemp[43], 15'b000000000000000, wordtemp[42], 15'b000000000000000, wordtemp[41],
          15'b000000000000000, wordtemp[40], 15'b000000000000000, wordtemp[39], 15'b000000000000000, wordtemp[38],
          15'b000000000000000, wordtemp[37], 15'b000000000000000, wordtemp[36], 15'b000000000000000, wordtemp[35],
          15'b000000000000000, wordtemp[34], 15'b000000000000000, wordtemp[33], 15'b000000000000000, wordtemp[32],
          15'b000000000000000, wordtemp[31], 15'b000000000000000, wordtemp[30], 15'b000000000000000, wordtemp[29],
          15'b000000000000000, wordtemp[28], 15'b000000000000000, wordtemp[27], 15'b000000000000000, wordtemp[26],
          15'b000000000000000, wordtemp[25], 15'b000000000000000, wordtemp[24], 15'b000000000000000, wordtemp[23],
          15'b000000000000000, wordtemp[22], 15'b000000000000000, wordtemp[21], 15'b000000000000000, wordtemp[20],
          15'b000000000000000, wordtemp[19], 15'b000000000000000, wordtemp[18], 15'b000000000000000, wordtemp[17],
          15'b000000000000000, wordtemp[16], 15'b000000000000000, wordtemp[15], 15'b000000000000000, wordtemp[14],
          15'b000000000000000, wordtemp[13], 15'b000000000000000, wordtemp[12], 15'b000000000000000, wordtemp[11],
          15'b000000000000000, wordtemp[10], 15'b000000000000000, wordtemp[9], 15'b000000000000000, wordtemp[8],
          15'b000000000000000, wordtemp[7], 15'b000000000000000, wordtemp[6], 15'b000000000000000, wordtemp[5],
          15'b000000000000000, wordtemp[4], 15'b000000000000000, wordtemp[3], 15'b000000000000000, wordtemp[2],
          15'b000000000000000, wordtemp[1], 15'b000000000000000, wordtemp[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
  	end
  end
  end
  endtask

task dumpmem;
	input [1000*8-1:0] filename_dump;
	integer i, dump_file_desc;
	reg [BITS-1:0] wordtemp;
	reg [8:0] Atemp;
  begin
	dump_file_desc = $fopen(filename_dump);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  Atemp = i;
	  mux_address = (Atemp & 4'b1111);
      row_address = (Atemp >> 4);
      row = mem[row_address];
        writeEnable = {64{1'b1}};
        data_out = (row >> (mux_address));
        readLatch0 = {data_out[1020], data_out[1016], data_out[1012], data_out[1008],
          data_out[1004], data_out[1000], data_out[996], data_out[992], data_out[988],
          data_out[984], data_out[980], data_out[976], data_out[972], data_out[968],
          data_out[964], data_out[960], data_out[956], data_out[952], data_out[948],
          data_out[944], data_out[940], data_out[936], data_out[932], data_out[928],
          data_out[924], data_out[920], data_out[916], data_out[912], data_out[908],
          data_out[904], data_out[900], data_out[896], data_out[892], data_out[888],
          data_out[884], data_out[880], data_out[876], data_out[872], data_out[868],
          data_out[864], data_out[860], data_out[856], data_out[852], data_out[848],
          data_out[844], data_out[840], data_out[836], data_out[832], data_out[828],
          data_out[824], data_out[820], data_out[816], data_out[812], data_out[808],
          data_out[804], data_out[800], data_out[796], data_out[792], data_out[788],
          data_out[784], data_out[780], data_out[776], data_out[772], data_out[768],
          data_out[764], data_out[760], data_out[756], data_out[752], data_out[748],
          data_out[744], data_out[740], data_out[736], data_out[732], data_out[728],
          data_out[724], data_out[720], data_out[716], data_out[712], data_out[708],
          data_out[704], data_out[700], data_out[696], data_out[692], data_out[688],
          data_out[684], data_out[680], data_out[676], data_out[672], data_out[668],
          data_out[664], data_out[660], data_out[656], data_out[652], data_out[648],
          data_out[644], data_out[640], data_out[636], data_out[632], data_out[628],
          data_out[624], data_out[620], data_out[616], data_out[612], data_out[608],
          data_out[604], data_out[600], data_out[596], data_out[592], data_out[588],
          data_out[584], data_out[580], data_out[576], data_out[572], data_out[568],
          data_out[564], data_out[560], data_out[556], data_out[552], data_out[548],
          data_out[544], data_out[540], data_out[536], data_out[532], data_out[528],
          data_out[524], data_out[520], data_out[516], data_out[512], data_out[508],
          data_out[504], data_out[500], data_out[496], data_out[492], data_out[488],
          data_out[484], data_out[480], data_out[476], data_out[472], data_out[468],
          data_out[464], data_out[460], data_out[456], data_out[452], data_out[448],
          data_out[444], data_out[440], data_out[436], data_out[432], data_out[428],
          data_out[424], data_out[420], data_out[416], data_out[412], data_out[408],
          data_out[404], data_out[400], data_out[396], data_out[392], data_out[388],
          data_out[384], data_out[380], data_out[376], data_out[372], data_out[368],
          data_out[364], data_out[360], data_out[356], data_out[352], data_out[348],
          data_out[344], data_out[340], data_out[336], data_out[332], data_out[328],
          data_out[324], data_out[320], data_out[316], data_out[312], data_out[308],
          data_out[304], data_out[300], data_out[296], data_out[292], data_out[288],
          data_out[284], data_out[280], data_out[276], data_out[272], data_out[268],
          data_out[264], data_out[260], data_out[256], data_out[252], data_out[248],
          data_out[244], data_out[240], data_out[236], data_out[232], data_out[228],
          data_out[224], data_out[220], data_out[216], data_out[212], data_out[208],
          data_out[204], data_out[200], data_out[196], data_out[192], data_out[188],
          data_out[184], data_out[180], data_out[176], data_out[172], data_out[168],
          data_out[164], data_out[160], data_out[156], data_out[152], data_out[148],
          data_out[144], data_out[140], data_out[136], data_out[132], data_out[128],
          data_out[124], data_out[120], data_out[116], data_out[112], data_out[108],
          data_out[104], data_out[100], data_out[96], data_out[92], data_out[88], data_out[84],
          data_out[80], data_out[76], data_out[72], data_out[68], data_out[64], data_out[60],
          data_out[56], data_out[52], data_out[48], data_out[44], data_out[40], data_out[36],
          data_out[32], data_out[28], data_out[24], data_out[20], data_out[16], data_out[12],
          data_out[8], data_out[4], data_out[0]};
        shifted_readLatch0 = readLatch0;
        Q_int = {shifted_readLatch0[252], shifted_readLatch0[248], shifted_readLatch0[244],
          shifted_readLatch0[240], shifted_readLatch0[236], shifted_readLatch0[232],
          shifted_readLatch0[228], shifted_readLatch0[224], shifted_readLatch0[220],
          shifted_readLatch0[216], shifted_readLatch0[212], shifted_readLatch0[208],
          shifted_readLatch0[204], shifted_readLatch0[200], shifted_readLatch0[196],
          shifted_readLatch0[192], shifted_readLatch0[188], shifted_readLatch0[184],
          shifted_readLatch0[180], shifted_readLatch0[176], shifted_readLatch0[172],
          shifted_readLatch0[168], shifted_readLatch0[164], shifted_readLatch0[160],
          shifted_readLatch0[156], shifted_readLatch0[152], shifted_readLatch0[148],
          shifted_readLatch0[144], shifted_readLatch0[140], shifted_readLatch0[136],
          shifted_readLatch0[132], shifted_readLatch0[128], shifted_readLatch0[124],
          shifted_readLatch0[120], shifted_readLatch0[116], shifted_readLatch0[112],
          shifted_readLatch0[108], shifted_readLatch0[104], shifted_readLatch0[100],
          shifted_readLatch0[96], shifted_readLatch0[92], shifted_readLatch0[88], shifted_readLatch0[84],
          shifted_readLatch0[80], shifted_readLatch0[76], shifted_readLatch0[72], shifted_readLatch0[68],
          shifted_readLatch0[64], shifted_readLatch0[60], shifted_readLatch0[56], shifted_readLatch0[52],
          shifted_readLatch0[48], shifted_readLatch0[44], shifted_readLatch0[40], shifted_readLatch0[36],
          shifted_readLatch0[32], shifted_readLatch0[28], shifted_readLatch0[24], shifted_readLatch0[20],
          shifted_readLatch0[16], shifted_readLatch0[12], shifted_readLatch0[8], shifted_readLatch0[4],
          shifted_readLatch0[0]};
   	$fdisplay(dump_file_desc, "%b", Q_int);
  end
  	end
//    $fclose(filename_dump);
  end
  endtask


  task readWrite;
  begin
    if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0 && CEN_int === 1'b0) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{CEN_int, EMA_int, EMAW_int, EMAS_int, RET1N_int, (STOV_int && !CEN_int)} 
     === 1'bx) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0)) begin
      Q_int = WEN_int !== 1'b1 ? D_int : {64{1'bx}};
      Q_int_delayed = WEN_int !== 1'b1 ? D_int : {64{1'bx}};
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (CEN_int === 1'b0) begin
      mux_address = (A_int & 4'b1111);
      row_address = (A_int >> 4);
      if (row_address > 31)
        row = {1024{1'bx}};
      else
        row = mem[row_address];
      writeEnable = ~{64{WEN_int}};
      if (WEN_int !== 1'b1) begin
        row_mask =  ( {15'b000000000000000, writeEnable[63], 15'b000000000000000, writeEnable[62],
          15'b000000000000000, writeEnable[61], 15'b000000000000000, writeEnable[60],
          15'b000000000000000, writeEnable[59], 15'b000000000000000, writeEnable[58],
          15'b000000000000000, writeEnable[57], 15'b000000000000000, writeEnable[56],
          15'b000000000000000, writeEnable[55], 15'b000000000000000, writeEnable[54],
          15'b000000000000000, writeEnable[53], 15'b000000000000000, writeEnable[52],
          15'b000000000000000, writeEnable[51], 15'b000000000000000, writeEnable[50],
          15'b000000000000000, writeEnable[49], 15'b000000000000000, writeEnable[48],
          15'b000000000000000, writeEnable[47], 15'b000000000000000, writeEnable[46],
          15'b000000000000000, writeEnable[45], 15'b000000000000000, writeEnable[44],
          15'b000000000000000, writeEnable[43], 15'b000000000000000, writeEnable[42],
          15'b000000000000000, writeEnable[41], 15'b000000000000000, writeEnable[40],
          15'b000000000000000, writeEnable[39], 15'b000000000000000, writeEnable[38],
          15'b000000000000000, writeEnable[37], 15'b000000000000000, writeEnable[36],
          15'b000000000000000, writeEnable[35], 15'b000000000000000, writeEnable[34],
          15'b000000000000000, writeEnable[33], 15'b000000000000000, writeEnable[32],
          15'b000000000000000, writeEnable[31], 15'b000000000000000, writeEnable[30],
          15'b000000000000000, writeEnable[29], 15'b000000000000000, writeEnable[28],
          15'b000000000000000, writeEnable[27], 15'b000000000000000, writeEnable[26],
          15'b000000000000000, writeEnable[25], 15'b000000000000000, writeEnable[24],
          15'b000000000000000, writeEnable[23], 15'b000000000000000, writeEnable[22],
          15'b000000000000000, writeEnable[21], 15'b000000000000000, writeEnable[20],
          15'b000000000000000, writeEnable[19], 15'b000000000000000, writeEnable[18],
          15'b000000000000000, writeEnable[17], 15'b000000000000000, writeEnable[16],
          15'b000000000000000, writeEnable[15], 15'b000000000000000, writeEnable[14],
          15'b000000000000000, writeEnable[13], 15'b000000000000000, writeEnable[12],
          15'b000000000000000, writeEnable[11], 15'b000000000000000, writeEnable[10],
          15'b000000000000000, writeEnable[9], 15'b000000000000000, writeEnable[8],
          15'b000000000000000, writeEnable[7], 15'b000000000000000, writeEnable[6],
          15'b000000000000000, writeEnable[5], 15'b000000000000000, writeEnable[4],
          15'b000000000000000, writeEnable[3], 15'b000000000000000, writeEnable[2],
          15'b000000000000000, writeEnable[1], 15'b000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {15'b000000000000000, D_int[63], 15'b000000000000000, D_int[62],
          15'b000000000000000, D_int[61], 15'b000000000000000, D_int[60], 15'b000000000000000, D_int[59],
          15'b000000000000000, D_int[58], 15'b000000000000000, D_int[57], 15'b000000000000000, D_int[56],
          15'b000000000000000, D_int[55], 15'b000000000000000, D_int[54], 15'b000000000000000, D_int[53],
          15'b000000000000000, D_int[52], 15'b000000000000000, D_int[51], 15'b000000000000000, D_int[50],
          15'b000000000000000, D_int[49], 15'b000000000000000, D_int[48], 15'b000000000000000, D_int[47],
          15'b000000000000000, D_int[46], 15'b000000000000000, D_int[45], 15'b000000000000000, D_int[44],
          15'b000000000000000, D_int[43], 15'b000000000000000, D_int[42], 15'b000000000000000, D_int[41],
          15'b000000000000000, D_int[40], 15'b000000000000000, D_int[39], 15'b000000000000000, D_int[38],
          15'b000000000000000, D_int[37], 15'b000000000000000, D_int[36], 15'b000000000000000, D_int[35],
          15'b000000000000000, D_int[34], 15'b000000000000000, D_int[33], 15'b000000000000000, D_int[32],
          15'b000000000000000, D_int[31], 15'b000000000000000, D_int[30], 15'b000000000000000, D_int[29],
          15'b000000000000000, D_int[28], 15'b000000000000000, D_int[27], 15'b000000000000000, D_int[26],
          15'b000000000000000, D_int[25], 15'b000000000000000, D_int[24], 15'b000000000000000, D_int[23],
          15'b000000000000000, D_int[22], 15'b000000000000000, D_int[21], 15'b000000000000000, D_int[20],
          15'b000000000000000, D_int[19], 15'b000000000000000, D_int[18], 15'b000000000000000, D_int[17],
          15'b000000000000000, D_int[16], 15'b000000000000000, D_int[15], 15'b000000000000000, D_int[14],
          15'b000000000000000, D_int[13], 15'b000000000000000, D_int[12], 15'b000000000000000, D_int[11],
          15'b000000000000000, D_int[10], 15'b000000000000000, D_int[9], 15'b000000000000000, D_int[8],
          15'b000000000000000, D_int[7], 15'b000000000000000, D_int[6], 15'b000000000000000, D_int[5],
          15'b000000000000000, D_int[4], 15'b000000000000000, D_int[3], 15'b000000000000000, D_int[2],
          15'b000000000000000, D_int[1], 15'b000000000000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
      end else begin
        data_out = (row >> (mux_address%4));
        readLatch0 = {data_out[1020], data_out[1016], data_out[1012], data_out[1008],
          data_out[1004], data_out[1000], data_out[996], data_out[992], data_out[988],
          data_out[984], data_out[980], data_out[976], data_out[972], data_out[968],
          data_out[964], data_out[960], data_out[956], data_out[952], data_out[948],
          data_out[944], data_out[940], data_out[936], data_out[932], data_out[928],
          data_out[924], data_out[920], data_out[916], data_out[912], data_out[908],
          data_out[904], data_out[900], data_out[896], data_out[892], data_out[888],
          data_out[884], data_out[880], data_out[876], data_out[872], data_out[868],
          data_out[864], data_out[860], data_out[856], data_out[852], data_out[848],
          data_out[844], data_out[840], data_out[836], data_out[832], data_out[828],
          data_out[824], data_out[820], data_out[816], data_out[812], data_out[808],
          data_out[804], data_out[800], data_out[796], data_out[792], data_out[788],
          data_out[784], data_out[780], data_out[776], data_out[772], data_out[768],
          data_out[764], data_out[760], data_out[756], data_out[752], data_out[748],
          data_out[744], data_out[740], data_out[736], data_out[732], data_out[728],
          data_out[724], data_out[720], data_out[716], data_out[712], data_out[708],
          data_out[704], data_out[700], data_out[696], data_out[692], data_out[688],
          data_out[684], data_out[680], data_out[676], data_out[672], data_out[668],
          data_out[664], data_out[660], data_out[656], data_out[652], data_out[648],
          data_out[644], data_out[640], data_out[636], data_out[632], data_out[628],
          data_out[624], data_out[620], data_out[616], data_out[612], data_out[608],
          data_out[604], data_out[600], data_out[596], data_out[592], data_out[588],
          data_out[584], data_out[580], data_out[576], data_out[572], data_out[568],
          data_out[564], data_out[560], data_out[556], data_out[552], data_out[548],
          data_out[544], data_out[540], data_out[536], data_out[532], data_out[528],
          data_out[524], data_out[520], data_out[516], data_out[512], data_out[508],
          data_out[504], data_out[500], data_out[496], data_out[492], data_out[488],
          data_out[484], data_out[480], data_out[476], data_out[472], data_out[468],
          data_out[464], data_out[460], data_out[456], data_out[452], data_out[448],
          data_out[444], data_out[440], data_out[436], data_out[432], data_out[428],
          data_out[424], data_out[420], data_out[416], data_out[412], data_out[408],
          data_out[404], data_out[400], data_out[396], data_out[392], data_out[388],
          data_out[384], data_out[380], data_out[376], data_out[372], data_out[368],
          data_out[364], data_out[360], data_out[356], data_out[352], data_out[348],
          data_out[344], data_out[340], data_out[336], data_out[332], data_out[328],
          data_out[324], data_out[320], data_out[316], data_out[312], data_out[308],
          data_out[304], data_out[300], data_out[296], data_out[292], data_out[288],
          data_out[284], data_out[280], data_out[276], data_out[272], data_out[268],
          data_out[264], data_out[260], data_out[256], data_out[252], data_out[248],
          data_out[244], data_out[240], data_out[236], data_out[232], data_out[228],
          data_out[224], data_out[220], data_out[216], data_out[212], data_out[208],
          data_out[204], data_out[200], data_out[196], data_out[192], data_out[188],
          data_out[184], data_out[180], data_out[176], data_out[172], data_out[168],
          data_out[164], data_out[160], data_out[156], data_out[152], data_out[148],
          data_out[144], data_out[140], data_out[136], data_out[132], data_out[128],
          data_out[124], data_out[120], data_out[116], data_out[112], data_out[108],
          data_out[104], data_out[100], data_out[96], data_out[92], data_out[88], data_out[84],
          data_out[80], data_out[76], data_out[72], data_out[68], data_out[64], data_out[60],
          data_out[56], data_out[52], data_out[48], data_out[44], data_out[40], data_out[36],
          data_out[32], data_out[28], data_out[24], data_out[20], data_out[16], data_out[12],
          data_out[8], data_out[4], data_out[0]};
      end
      if (WEN_int !== 1'b1) begin
        Q_int = D_int;
        Q_int_delayed = D_int;
      end else begin
        shifted_readLatch0 = (readLatch0 >> A_int[3:2]);
        Q_int = {shifted_readLatch0[252], shifted_readLatch0[248], shifted_readLatch0[244],
          shifted_readLatch0[240], shifted_readLatch0[236], shifted_readLatch0[232],
          shifted_readLatch0[228], shifted_readLatch0[224], shifted_readLatch0[220],
          shifted_readLatch0[216], shifted_readLatch0[212], shifted_readLatch0[208],
          shifted_readLatch0[204], shifted_readLatch0[200], shifted_readLatch0[196],
          shifted_readLatch0[192], shifted_readLatch0[188], shifted_readLatch0[184],
          shifted_readLatch0[180], shifted_readLatch0[176], shifted_readLatch0[172],
          shifted_readLatch0[168], shifted_readLatch0[164], shifted_readLatch0[160],
          shifted_readLatch0[156], shifted_readLatch0[152], shifted_readLatch0[148],
          shifted_readLatch0[144], shifted_readLatch0[140], shifted_readLatch0[136],
          shifted_readLatch0[132], shifted_readLatch0[128], shifted_readLatch0[124],
          shifted_readLatch0[120], shifted_readLatch0[116], shifted_readLatch0[112],
          shifted_readLatch0[108], shifted_readLatch0[104], shifted_readLatch0[100],
          shifted_readLatch0[96], shifted_readLatch0[92], shifted_readLatch0[88], shifted_readLatch0[84],
          shifted_readLatch0[80], shifted_readLatch0[76], shifted_readLatch0[72], shifted_readLatch0[68],
          shifted_readLatch0[64], shifted_readLatch0[60], shifted_readLatch0[56], shifted_readLatch0[52],
          shifted_readLatch0[48], shifted_readLatch0[44], shifted_readLatch0[40], shifted_readLatch0[36],
          shifted_readLatch0[32], shifted_readLatch0[28], shifted_readLatch0[24], shifted_readLatch0[20],
          shifted_readLatch0[16], shifted_readLatch0[12], shifted_readLatch0[8], shifted_readLatch0[4],
          shifted_readLatch0[0]};
      end
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  	end
  end

  always @ RET1N_ begin
    if (CLK_ == 1'b1) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end
    if (RET1N_ == 1'b0) begin
      Q_int = {64{1'bx}};
      Q_int_delayed = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {9{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {9{1'bx}};
      TD_int = {64{1'bx}};
      TQ_int = {64{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end else begin
      Q_int = {64{1'bx}};
      Q_int_delayed = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {9{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {9{1'bx}};
      TD_int = {64{1'bx}};
      TQ_int = {64{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end
    RET1N_int = RET1N_;
  end


  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDDCE === 1'bx || VDDCE === 1'bz)
      $display("ERROR: Illegal value for VDDCE %b", VDDCE);
    if (VDDPE === 1'bx || VDDPE === 1'bz)
      $display("ERROR: Illegal value for VDDPE %b", VDDPE);
    if (VSSE === 1'bx || VSSE === 1'bz)
      $display("ERROR: Illegal value for VSSE %b", VSSE);
`endif
  if (RET1N_ == 1'b0) begin
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      EMAS_int = EMAS_;
      TEN_int = TEN_;
      BEN_int = BEN_;
      TWEN_int = TWEN_;
      TQ_int = TQ_;
      RET1N_int = RET1N_;
      STOV_int = STOV_;
      if (CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        if (WEN_int === 1'b1)
          read_mux_sel0 = (TEN_ ? A_[3:2] : TA_[3:2] );
      end
      clk0_int = 1'b0;
      if (CEN_int === 1'b0 && WEN_int === 1'b1) 
         Q_int_delayed = {64{1'bx}};
    readWrite;
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
      Q_int_delayed = Q_int;
    end
    LAST_CLK = CLK_;
  end
  end

endmodule
`endcelldefine
`else
`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module sram_sp_512x64 (VDDCE, VDDPE, VSSE, CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A,
    D, EMA, EMAW, EMAS, TEN, BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`else
module sram_sp_512x64 (CENY, WENY, AY, DY, Q, CLK, CEN, WEN, A, D, EMA, EMAW, EMAS,
    TEN, BEN, TCEN, TWEN, TA, TD, TQ, RET1N, STOV);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 64;
  parameter WORDS = 512;
  parameter MUX = 16;
  parameter MEM_WIDTH = 1024; // redun block size 4, 512 on left, 512 on right
  parameter MEM_HEIGHT = 32;
  parameter WP_SIZE = 64 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 1;

  output  CENY;
  output  WENY;
  output [8:0] AY;
  output [63:0] DY;
  output [63:0] Q;
  input  CLK;
  input  CEN;
  input  WEN;
  input [8:0] A;
  input [63:0] D;
  input [2:0] EMA;
  input [1:0] EMAW;
  input  EMAS;
  input  TEN;
  input  BEN;
  input  TCEN;
  input  TWEN;
  input [8:0] TA;
  input [63:0] TD;
  input [63:0] TQ;
  input  RET1N;
  input  STOV;
`ifdef POWER_PINS
  inout VDDCE;
  inout VDDPE;
  inout VSSE;
`endif

  integer row_address;
  integer mux_address;
  reg [1023:0] mem [0:31];
  reg [1023:0] row;
  reg LAST_CLK;
  reg [1023:0] row_mask;
  reg [1023:0] new_data;
  reg [1023:0] data_out;
  reg [255:0] readLatch0;
  reg [255:0] shifted_readLatch0;
  reg [1:0] read_mux_sel0;
  reg [63:0] Q_int;
  reg [63:0] Q_int_delayed;
  reg [63:0] writeEnable;

  reg NOT_CEN, NOT_WEN, NOT_A8, NOT_A7, NOT_A6, NOT_A5, NOT_A4, NOT_A3, NOT_A2, NOT_A1;
  reg NOT_A0, NOT_D63, NOT_D62, NOT_D61, NOT_D60, NOT_D59, NOT_D58, NOT_D57, NOT_D56;
  reg NOT_D55, NOT_D54, NOT_D53, NOT_D52, NOT_D51, NOT_D50, NOT_D49, NOT_D48, NOT_D47;
  reg NOT_D46, NOT_D45, NOT_D44, NOT_D43, NOT_D42, NOT_D41, NOT_D40, NOT_D39, NOT_D38;
  reg NOT_D37, NOT_D36, NOT_D35, NOT_D34, NOT_D33, NOT_D32, NOT_D31, NOT_D30, NOT_D29;
  reg NOT_D28, NOT_D27, NOT_D26, NOT_D25, NOT_D24, NOT_D23, NOT_D22, NOT_D21, NOT_D20;
  reg NOT_D19, NOT_D18, NOT_D17, NOT_D16, NOT_D15, NOT_D14, NOT_D13, NOT_D12, NOT_D11;
  reg NOT_D10, NOT_D9, NOT_D8, NOT_D7, NOT_D6, NOT_D5, NOT_D4, NOT_D3, NOT_D2, NOT_D1;
  reg NOT_D0, NOT_EMA2, NOT_EMA1, NOT_EMA0, NOT_EMAW1, NOT_EMAW0, NOT_EMAS, NOT_TEN;
  reg NOT_TCEN, NOT_TWEN, NOT_TA8, NOT_TA7, NOT_TA6, NOT_TA5, NOT_TA4, NOT_TA3, NOT_TA2;
  reg NOT_TA1, NOT_TA0, NOT_TD63, NOT_TD62, NOT_TD61, NOT_TD60, NOT_TD59, NOT_TD58;
  reg NOT_TD57, NOT_TD56, NOT_TD55, NOT_TD54, NOT_TD53, NOT_TD52, NOT_TD51, NOT_TD50;
  reg NOT_TD49, NOT_TD48, NOT_TD47, NOT_TD46, NOT_TD45, NOT_TD44, NOT_TD43, NOT_TD42;
  reg NOT_TD41, NOT_TD40, NOT_TD39, NOT_TD38, NOT_TD37, NOT_TD36, NOT_TD35, NOT_TD34;
  reg NOT_TD33, NOT_TD32, NOT_TD31, NOT_TD30, NOT_TD29, NOT_TD28, NOT_TD27, NOT_TD26;
  reg NOT_TD25, NOT_TD24, NOT_TD23, NOT_TD22, NOT_TD21, NOT_TD20, NOT_TD19, NOT_TD18;
  reg NOT_TD17, NOT_TD16, NOT_TD15, NOT_TD14, NOT_TD13, NOT_TD12, NOT_TD11, NOT_TD10;
  reg NOT_TD9, NOT_TD8, NOT_TD7, NOT_TD6, NOT_TD5, NOT_TD4, NOT_TD3, NOT_TD2, NOT_TD1;
  reg NOT_TD0, NOT_RET1N, NOT_STOV;
  reg NOT_CLK_PER, NOT_CLK_MINH, NOT_CLK_MINL;
  reg clk0_int;

  wire  CENY_;
  wire  WENY_;
  wire [8:0] AY_;
  wire [63:0] DY_;
  wire [63:0] Q_;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire  WEN_;
  reg  WEN_int;
  wire [8:0] A_;
  reg [8:0] A_int;
  wire [63:0] D_;
  reg [63:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  EMAS_;
  reg  EMAS_int;
  wire  TEN_;
  reg  TEN_int;
  wire  BEN_;
  reg  BEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire  TWEN_;
  reg  TWEN_int;
  wire [8:0] TA_;
  reg [8:0] TA_int;
  wire [63:0] TD_;
  reg [63:0] TD_int;
  wire [63:0] TQ_;
  reg [63:0] TQ_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire  STOV_;
  reg  STOV_int;

  buf B0(CENY, CENY_);
  buf B1(WENY, WENY_);
  buf B2(AY[0], AY_[0]);
  buf B3(AY[1], AY_[1]);
  buf B4(AY[2], AY_[2]);
  buf B5(AY[3], AY_[3]);
  buf B6(AY[4], AY_[4]);
  buf B7(AY[5], AY_[5]);
  buf B8(AY[6], AY_[6]);
  buf B9(AY[7], AY_[7]);
  buf B10(AY[8], AY_[8]);
  buf B11(DY[0], DY_[0]);
  buf B12(DY[1], DY_[1]);
  buf B13(DY[2], DY_[2]);
  buf B14(DY[3], DY_[3]);
  buf B15(DY[4], DY_[4]);
  buf B16(DY[5], DY_[5]);
  buf B17(DY[6], DY_[6]);
  buf B18(DY[7], DY_[7]);
  buf B19(DY[8], DY_[8]);
  buf B20(DY[9], DY_[9]);
  buf B21(DY[10], DY_[10]);
  buf B22(DY[11], DY_[11]);
  buf B23(DY[12], DY_[12]);
  buf B24(DY[13], DY_[13]);
  buf B25(DY[14], DY_[14]);
  buf B26(DY[15], DY_[15]);
  buf B27(DY[16], DY_[16]);
  buf B28(DY[17], DY_[17]);
  buf B29(DY[18], DY_[18]);
  buf B30(DY[19], DY_[19]);
  buf B31(DY[20], DY_[20]);
  buf B32(DY[21], DY_[21]);
  buf B33(DY[22], DY_[22]);
  buf B34(DY[23], DY_[23]);
  buf B35(DY[24], DY_[24]);
  buf B36(DY[25], DY_[25]);
  buf B37(DY[26], DY_[26]);
  buf B38(DY[27], DY_[27]);
  buf B39(DY[28], DY_[28]);
  buf B40(DY[29], DY_[29]);
  buf B41(DY[30], DY_[30]);
  buf B42(DY[31], DY_[31]);
  buf B43(DY[32], DY_[32]);
  buf B44(DY[33], DY_[33]);
  buf B45(DY[34], DY_[34]);
  buf B46(DY[35], DY_[35]);
  buf B47(DY[36], DY_[36]);
  buf B48(DY[37], DY_[37]);
  buf B49(DY[38], DY_[38]);
  buf B50(DY[39], DY_[39]);
  buf B51(DY[40], DY_[40]);
  buf B52(DY[41], DY_[41]);
  buf B53(DY[42], DY_[42]);
  buf B54(DY[43], DY_[43]);
  buf B55(DY[44], DY_[44]);
  buf B56(DY[45], DY_[45]);
  buf B57(DY[46], DY_[46]);
  buf B58(DY[47], DY_[47]);
  buf B59(DY[48], DY_[48]);
  buf B60(DY[49], DY_[49]);
  buf B61(DY[50], DY_[50]);
  buf B62(DY[51], DY_[51]);
  buf B63(DY[52], DY_[52]);
  buf B64(DY[53], DY_[53]);
  buf B65(DY[54], DY_[54]);
  buf B66(DY[55], DY_[55]);
  buf B67(DY[56], DY_[56]);
  buf B68(DY[57], DY_[57]);
  buf B69(DY[58], DY_[58]);
  buf B70(DY[59], DY_[59]);
  buf B71(DY[60], DY_[60]);
  buf B72(DY[61], DY_[61]);
  buf B73(DY[62], DY_[62]);
  buf B74(DY[63], DY_[63]);
  buf B75(Q[0], Q_[0]);
  buf B76(Q[1], Q_[1]);
  buf B77(Q[2], Q_[2]);
  buf B78(Q[3], Q_[3]);
  buf B79(Q[4], Q_[4]);
  buf B80(Q[5], Q_[5]);
  buf B81(Q[6], Q_[6]);
  buf B82(Q[7], Q_[7]);
  buf B83(Q[8], Q_[8]);
  buf B84(Q[9], Q_[9]);
  buf B85(Q[10], Q_[10]);
  buf B86(Q[11], Q_[11]);
  buf B87(Q[12], Q_[12]);
  buf B88(Q[13], Q_[13]);
  buf B89(Q[14], Q_[14]);
  buf B90(Q[15], Q_[15]);
  buf B91(Q[16], Q_[16]);
  buf B92(Q[17], Q_[17]);
  buf B93(Q[18], Q_[18]);
  buf B94(Q[19], Q_[19]);
  buf B95(Q[20], Q_[20]);
  buf B96(Q[21], Q_[21]);
  buf B97(Q[22], Q_[22]);
  buf B98(Q[23], Q_[23]);
  buf B99(Q[24], Q_[24]);
  buf B100(Q[25], Q_[25]);
  buf B101(Q[26], Q_[26]);
  buf B102(Q[27], Q_[27]);
  buf B103(Q[28], Q_[28]);
  buf B104(Q[29], Q_[29]);
  buf B105(Q[30], Q_[30]);
  buf B106(Q[31], Q_[31]);
  buf B107(Q[32], Q_[32]);
  buf B108(Q[33], Q_[33]);
  buf B109(Q[34], Q_[34]);
  buf B110(Q[35], Q_[35]);
  buf B111(Q[36], Q_[36]);
  buf B112(Q[37], Q_[37]);
  buf B113(Q[38], Q_[38]);
  buf B114(Q[39], Q_[39]);
  buf B115(Q[40], Q_[40]);
  buf B116(Q[41], Q_[41]);
  buf B117(Q[42], Q_[42]);
  buf B118(Q[43], Q_[43]);
  buf B119(Q[44], Q_[44]);
  buf B120(Q[45], Q_[45]);
  buf B121(Q[46], Q_[46]);
  buf B122(Q[47], Q_[47]);
  buf B123(Q[48], Q_[48]);
  buf B124(Q[49], Q_[49]);
  buf B125(Q[50], Q_[50]);
  buf B126(Q[51], Q_[51]);
  buf B127(Q[52], Q_[52]);
  buf B128(Q[53], Q_[53]);
  buf B129(Q[54], Q_[54]);
  buf B130(Q[55], Q_[55]);
  buf B131(Q[56], Q_[56]);
  buf B132(Q[57], Q_[57]);
  buf B133(Q[58], Q_[58]);
  buf B134(Q[59], Q_[59]);
  buf B135(Q[60], Q_[60]);
  buf B136(Q[61], Q_[61]);
  buf B137(Q[62], Q_[62]);
  buf B138(Q[63], Q_[63]);
  buf B139(CLK_, CLK);
  buf B140(CEN_, CEN);
  buf B141(WEN_, WEN);
  buf B142(A_[0], A[0]);
  buf B143(A_[1], A[1]);
  buf B144(A_[2], A[2]);
  buf B145(A_[3], A[3]);
  buf B146(A_[4], A[4]);
  buf B147(A_[5], A[5]);
  buf B148(A_[6], A[6]);
  buf B149(A_[7], A[7]);
  buf B150(A_[8], A[8]);
  buf B151(D_[0], D[0]);
  buf B152(D_[1], D[1]);
  buf B153(D_[2], D[2]);
  buf B154(D_[3], D[3]);
  buf B155(D_[4], D[4]);
  buf B156(D_[5], D[5]);
  buf B157(D_[6], D[6]);
  buf B158(D_[7], D[7]);
  buf B159(D_[8], D[8]);
  buf B160(D_[9], D[9]);
  buf B161(D_[10], D[10]);
  buf B162(D_[11], D[11]);
  buf B163(D_[12], D[12]);
  buf B164(D_[13], D[13]);
  buf B165(D_[14], D[14]);
  buf B166(D_[15], D[15]);
  buf B167(D_[16], D[16]);
  buf B168(D_[17], D[17]);
  buf B169(D_[18], D[18]);
  buf B170(D_[19], D[19]);
  buf B171(D_[20], D[20]);
  buf B172(D_[21], D[21]);
  buf B173(D_[22], D[22]);
  buf B174(D_[23], D[23]);
  buf B175(D_[24], D[24]);
  buf B176(D_[25], D[25]);
  buf B177(D_[26], D[26]);
  buf B178(D_[27], D[27]);
  buf B179(D_[28], D[28]);
  buf B180(D_[29], D[29]);
  buf B181(D_[30], D[30]);
  buf B182(D_[31], D[31]);
  buf B183(D_[32], D[32]);
  buf B184(D_[33], D[33]);
  buf B185(D_[34], D[34]);
  buf B186(D_[35], D[35]);
  buf B187(D_[36], D[36]);
  buf B188(D_[37], D[37]);
  buf B189(D_[38], D[38]);
  buf B190(D_[39], D[39]);
  buf B191(D_[40], D[40]);
  buf B192(D_[41], D[41]);
  buf B193(D_[42], D[42]);
  buf B194(D_[43], D[43]);
  buf B195(D_[44], D[44]);
  buf B196(D_[45], D[45]);
  buf B197(D_[46], D[46]);
  buf B198(D_[47], D[47]);
  buf B199(D_[48], D[48]);
  buf B200(D_[49], D[49]);
  buf B201(D_[50], D[50]);
  buf B202(D_[51], D[51]);
  buf B203(D_[52], D[52]);
  buf B204(D_[53], D[53]);
  buf B205(D_[54], D[54]);
  buf B206(D_[55], D[55]);
  buf B207(D_[56], D[56]);
  buf B208(D_[57], D[57]);
  buf B209(D_[58], D[58]);
  buf B210(D_[59], D[59]);
  buf B211(D_[60], D[60]);
  buf B212(D_[61], D[61]);
  buf B213(D_[62], D[62]);
  buf B214(D_[63], D[63]);
  buf B215(EMA_[0], EMA[0]);
  buf B216(EMA_[1], EMA[1]);
  buf B217(EMA_[2], EMA[2]);
  buf B218(EMAW_[0], EMAW[0]);
  buf B219(EMAW_[1], EMAW[1]);
  buf B220(EMAS_, EMAS);
  buf B221(TEN_, TEN);
  buf B222(BEN_, BEN);
  buf B223(TCEN_, TCEN);
  buf B224(TWEN_, TWEN);
  buf B225(TA_[0], TA[0]);
  buf B226(TA_[1], TA[1]);
  buf B227(TA_[2], TA[2]);
  buf B228(TA_[3], TA[3]);
  buf B229(TA_[4], TA[4]);
  buf B230(TA_[5], TA[5]);
  buf B231(TA_[6], TA[6]);
  buf B232(TA_[7], TA[7]);
  buf B233(TA_[8], TA[8]);
  buf B234(TD_[0], TD[0]);
  buf B235(TD_[1], TD[1]);
  buf B236(TD_[2], TD[2]);
  buf B237(TD_[3], TD[3]);
  buf B238(TD_[4], TD[4]);
  buf B239(TD_[5], TD[5]);
  buf B240(TD_[6], TD[6]);
  buf B241(TD_[7], TD[7]);
  buf B242(TD_[8], TD[8]);
  buf B243(TD_[9], TD[9]);
  buf B244(TD_[10], TD[10]);
  buf B245(TD_[11], TD[11]);
  buf B246(TD_[12], TD[12]);
  buf B247(TD_[13], TD[13]);
  buf B248(TD_[14], TD[14]);
  buf B249(TD_[15], TD[15]);
  buf B250(TD_[16], TD[16]);
  buf B251(TD_[17], TD[17]);
  buf B252(TD_[18], TD[18]);
  buf B253(TD_[19], TD[19]);
  buf B254(TD_[20], TD[20]);
  buf B255(TD_[21], TD[21]);
  buf B256(TD_[22], TD[22]);
  buf B257(TD_[23], TD[23]);
  buf B258(TD_[24], TD[24]);
  buf B259(TD_[25], TD[25]);
  buf B260(TD_[26], TD[26]);
  buf B261(TD_[27], TD[27]);
  buf B262(TD_[28], TD[28]);
  buf B263(TD_[29], TD[29]);
  buf B264(TD_[30], TD[30]);
  buf B265(TD_[31], TD[31]);
  buf B266(TD_[32], TD[32]);
  buf B267(TD_[33], TD[33]);
  buf B268(TD_[34], TD[34]);
  buf B269(TD_[35], TD[35]);
  buf B270(TD_[36], TD[36]);
  buf B271(TD_[37], TD[37]);
  buf B272(TD_[38], TD[38]);
  buf B273(TD_[39], TD[39]);
  buf B274(TD_[40], TD[40]);
  buf B275(TD_[41], TD[41]);
  buf B276(TD_[42], TD[42]);
  buf B277(TD_[43], TD[43]);
  buf B278(TD_[44], TD[44]);
  buf B279(TD_[45], TD[45]);
  buf B280(TD_[46], TD[46]);
  buf B281(TD_[47], TD[47]);
  buf B282(TD_[48], TD[48]);
  buf B283(TD_[49], TD[49]);
  buf B284(TD_[50], TD[50]);
  buf B285(TD_[51], TD[51]);
  buf B286(TD_[52], TD[52]);
  buf B287(TD_[53], TD[53]);
  buf B288(TD_[54], TD[54]);
  buf B289(TD_[55], TD[55]);
  buf B290(TD_[56], TD[56]);
  buf B291(TD_[57], TD[57]);
  buf B292(TD_[58], TD[58]);
  buf B293(TD_[59], TD[59]);
  buf B294(TD_[60], TD[60]);
  buf B295(TD_[61], TD[61]);
  buf B296(TD_[62], TD[62]);
  buf B297(TD_[63], TD[63]);
  buf B298(TQ_[0], TQ[0]);
  buf B299(TQ_[1], TQ[1]);
  buf B300(TQ_[2], TQ[2]);
  buf B301(TQ_[3], TQ[3]);
  buf B302(TQ_[4], TQ[4]);
  buf B303(TQ_[5], TQ[5]);
  buf B304(TQ_[6], TQ[6]);
  buf B305(TQ_[7], TQ[7]);
  buf B306(TQ_[8], TQ[8]);
  buf B307(TQ_[9], TQ[9]);
  buf B308(TQ_[10], TQ[10]);
  buf B309(TQ_[11], TQ[11]);
  buf B310(TQ_[12], TQ[12]);
  buf B311(TQ_[13], TQ[13]);
  buf B312(TQ_[14], TQ[14]);
  buf B313(TQ_[15], TQ[15]);
  buf B314(TQ_[16], TQ[16]);
  buf B315(TQ_[17], TQ[17]);
  buf B316(TQ_[18], TQ[18]);
  buf B317(TQ_[19], TQ[19]);
  buf B318(TQ_[20], TQ[20]);
  buf B319(TQ_[21], TQ[21]);
  buf B320(TQ_[22], TQ[22]);
  buf B321(TQ_[23], TQ[23]);
  buf B322(TQ_[24], TQ[24]);
  buf B323(TQ_[25], TQ[25]);
  buf B324(TQ_[26], TQ[26]);
  buf B325(TQ_[27], TQ[27]);
  buf B326(TQ_[28], TQ[28]);
  buf B327(TQ_[29], TQ[29]);
  buf B328(TQ_[30], TQ[30]);
  buf B329(TQ_[31], TQ[31]);
  buf B330(TQ_[32], TQ[32]);
  buf B331(TQ_[33], TQ[33]);
  buf B332(TQ_[34], TQ[34]);
  buf B333(TQ_[35], TQ[35]);
  buf B334(TQ_[36], TQ[36]);
  buf B335(TQ_[37], TQ[37]);
  buf B336(TQ_[38], TQ[38]);
  buf B337(TQ_[39], TQ[39]);
  buf B338(TQ_[40], TQ[40]);
  buf B339(TQ_[41], TQ[41]);
  buf B340(TQ_[42], TQ[42]);
  buf B341(TQ_[43], TQ[43]);
  buf B342(TQ_[44], TQ[44]);
  buf B343(TQ_[45], TQ[45]);
  buf B344(TQ_[46], TQ[46]);
  buf B345(TQ_[47], TQ[47]);
  buf B346(TQ_[48], TQ[48]);
  buf B347(TQ_[49], TQ[49]);
  buf B348(TQ_[50], TQ[50]);
  buf B349(TQ_[51], TQ[51]);
  buf B350(TQ_[52], TQ[52]);
  buf B351(TQ_[53], TQ[53]);
  buf B352(TQ_[54], TQ[54]);
  buf B353(TQ_[55], TQ[55]);
  buf B354(TQ_[56], TQ[56]);
  buf B355(TQ_[57], TQ[57]);
  buf B356(TQ_[58], TQ[58]);
  buf B357(TQ_[59], TQ[59]);
  buf B358(TQ_[60], TQ[60]);
  buf B359(TQ_[61], TQ[61]);
  buf B360(TQ_[62], TQ[62]);
  buf B361(TQ_[63], TQ[63]);
  buf B362(RET1N_, RET1N);
  buf B363(STOV_, STOV);

  assign CENY_ = RET1N_ ? (TEN_ ? CEN_ : TCEN_) : 1'bx;
  assign WENY_ = RET1N_ ? (TEN_ ? WEN_ : TWEN_) : 1'bx;
  assign AY_ = RET1N_ ? (TEN_ ? A_ : TA_) : {9{1'bx}};
  assign DY_ = RET1N_ ? (TEN_ ? D_ : TD_) : {64{1'bx}};
   `ifdef ARM_FAULT_MODELING
     sram_sp_512x64_error_injection u1(.CLK(CLK_), .Q_out(Q_), .A(A_int), .CEN(CEN_int), .TQ(TQ_), .BEN(BEN_), .WEN(WEN_int), .Q_in(Q_int));
  `else
  assign Q_ = RET1N_ ? (BEN_ ? ((STOV_ ? (Q_int_delayed) : (Q_int))) : TQ_) : {64{1'bx}};
  `endif

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
`endif

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval==1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction


task loadmem;
	input [1000*8-1:0] filename;
	reg [BITS-1:0] memld [0:WORDS-1];
	integer i;
	reg [BITS-1:0] wordtemp;
	reg [8:0] Atemp;
  begin
	$readmemb(filename, memld);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  wordtemp = memld[i];
	  Atemp = i;
	  mux_address = (Atemp & 4'b1111);
      row_address = (Atemp >> 4);
      row = mem[row_address];
        writeEnable = {64{1'b1}};
        row_mask =  ( {15'b000000000000000, writeEnable[63], 15'b000000000000000, writeEnable[62],
          15'b000000000000000, writeEnable[61], 15'b000000000000000, writeEnable[60],
          15'b000000000000000, writeEnable[59], 15'b000000000000000, writeEnable[58],
          15'b000000000000000, writeEnable[57], 15'b000000000000000, writeEnable[56],
          15'b000000000000000, writeEnable[55], 15'b000000000000000, writeEnable[54],
          15'b000000000000000, writeEnable[53], 15'b000000000000000, writeEnable[52],
          15'b000000000000000, writeEnable[51], 15'b000000000000000, writeEnable[50],
          15'b000000000000000, writeEnable[49], 15'b000000000000000, writeEnable[48],
          15'b000000000000000, writeEnable[47], 15'b000000000000000, writeEnable[46],
          15'b000000000000000, writeEnable[45], 15'b000000000000000, writeEnable[44],
          15'b000000000000000, writeEnable[43], 15'b000000000000000, writeEnable[42],
          15'b000000000000000, writeEnable[41], 15'b000000000000000, writeEnable[40],
          15'b000000000000000, writeEnable[39], 15'b000000000000000, writeEnable[38],
          15'b000000000000000, writeEnable[37], 15'b000000000000000, writeEnable[36],
          15'b000000000000000, writeEnable[35], 15'b000000000000000, writeEnable[34],
          15'b000000000000000, writeEnable[33], 15'b000000000000000, writeEnable[32],
          15'b000000000000000, writeEnable[31], 15'b000000000000000, writeEnable[30],
          15'b000000000000000, writeEnable[29], 15'b000000000000000, writeEnable[28],
          15'b000000000000000, writeEnable[27], 15'b000000000000000, writeEnable[26],
          15'b000000000000000, writeEnable[25], 15'b000000000000000, writeEnable[24],
          15'b000000000000000, writeEnable[23], 15'b000000000000000, writeEnable[22],
          15'b000000000000000, writeEnable[21], 15'b000000000000000, writeEnable[20],
          15'b000000000000000, writeEnable[19], 15'b000000000000000, writeEnable[18],
          15'b000000000000000, writeEnable[17], 15'b000000000000000, writeEnable[16],
          15'b000000000000000, writeEnable[15], 15'b000000000000000, writeEnable[14],
          15'b000000000000000, writeEnable[13], 15'b000000000000000, writeEnable[12],
          15'b000000000000000, writeEnable[11], 15'b000000000000000, writeEnable[10],
          15'b000000000000000, writeEnable[9], 15'b000000000000000, writeEnable[8],
          15'b000000000000000, writeEnable[7], 15'b000000000000000, writeEnable[6],
          15'b000000000000000, writeEnable[5], 15'b000000000000000, writeEnable[4],
          15'b000000000000000, writeEnable[3], 15'b000000000000000, writeEnable[2],
          15'b000000000000000, writeEnable[1], 15'b000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {15'b000000000000000, wordtemp[63], 15'b000000000000000, wordtemp[62],
          15'b000000000000000, wordtemp[61], 15'b000000000000000, wordtemp[60], 15'b000000000000000, wordtemp[59],
          15'b000000000000000, wordtemp[58], 15'b000000000000000, wordtemp[57], 15'b000000000000000, wordtemp[56],
          15'b000000000000000, wordtemp[55], 15'b000000000000000, wordtemp[54], 15'b000000000000000, wordtemp[53],
          15'b000000000000000, wordtemp[52], 15'b000000000000000, wordtemp[51], 15'b000000000000000, wordtemp[50],
          15'b000000000000000, wordtemp[49], 15'b000000000000000, wordtemp[48], 15'b000000000000000, wordtemp[47],
          15'b000000000000000, wordtemp[46], 15'b000000000000000, wordtemp[45], 15'b000000000000000, wordtemp[44],
          15'b000000000000000, wordtemp[43], 15'b000000000000000, wordtemp[42], 15'b000000000000000, wordtemp[41],
          15'b000000000000000, wordtemp[40], 15'b000000000000000, wordtemp[39], 15'b000000000000000, wordtemp[38],
          15'b000000000000000, wordtemp[37], 15'b000000000000000, wordtemp[36], 15'b000000000000000, wordtemp[35],
          15'b000000000000000, wordtemp[34], 15'b000000000000000, wordtemp[33], 15'b000000000000000, wordtemp[32],
          15'b000000000000000, wordtemp[31], 15'b000000000000000, wordtemp[30], 15'b000000000000000, wordtemp[29],
          15'b000000000000000, wordtemp[28], 15'b000000000000000, wordtemp[27], 15'b000000000000000, wordtemp[26],
          15'b000000000000000, wordtemp[25], 15'b000000000000000, wordtemp[24], 15'b000000000000000, wordtemp[23],
          15'b000000000000000, wordtemp[22], 15'b000000000000000, wordtemp[21], 15'b000000000000000, wordtemp[20],
          15'b000000000000000, wordtemp[19], 15'b000000000000000, wordtemp[18], 15'b000000000000000, wordtemp[17],
          15'b000000000000000, wordtemp[16], 15'b000000000000000, wordtemp[15], 15'b000000000000000, wordtemp[14],
          15'b000000000000000, wordtemp[13], 15'b000000000000000, wordtemp[12], 15'b000000000000000, wordtemp[11],
          15'b000000000000000, wordtemp[10], 15'b000000000000000, wordtemp[9], 15'b000000000000000, wordtemp[8],
          15'b000000000000000, wordtemp[7], 15'b000000000000000, wordtemp[6], 15'b000000000000000, wordtemp[5],
          15'b000000000000000, wordtemp[4], 15'b000000000000000, wordtemp[3], 15'b000000000000000, wordtemp[2],
          15'b000000000000000, wordtemp[1], 15'b000000000000000, wordtemp[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
  	end
  end
  end
  endtask

task dumpmem;
	input [1000*8-1:0] filename_dump;
	integer i, dump_file_desc;
	reg [BITS-1:0] wordtemp;
	reg [8:0] Atemp;
  begin
	dump_file_desc = $fopen(filename_dump);
     if (CEN_ === 1'b1) begin
	  for (i=0;i<WORDS;i=i+1) begin
	  Atemp = i;
	  mux_address = (Atemp & 4'b1111);
      row_address = (Atemp >> 4);
      row = mem[row_address];
        writeEnable = {64{1'b1}};
        data_out = (row >> (mux_address));
        readLatch0 = {data_out[1020], data_out[1016], data_out[1012], data_out[1008],
          data_out[1004], data_out[1000], data_out[996], data_out[992], data_out[988],
          data_out[984], data_out[980], data_out[976], data_out[972], data_out[968],
          data_out[964], data_out[960], data_out[956], data_out[952], data_out[948],
          data_out[944], data_out[940], data_out[936], data_out[932], data_out[928],
          data_out[924], data_out[920], data_out[916], data_out[912], data_out[908],
          data_out[904], data_out[900], data_out[896], data_out[892], data_out[888],
          data_out[884], data_out[880], data_out[876], data_out[872], data_out[868],
          data_out[864], data_out[860], data_out[856], data_out[852], data_out[848],
          data_out[844], data_out[840], data_out[836], data_out[832], data_out[828],
          data_out[824], data_out[820], data_out[816], data_out[812], data_out[808],
          data_out[804], data_out[800], data_out[796], data_out[792], data_out[788],
          data_out[784], data_out[780], data_out[776], data_out[772], data_out[768],
          data_out[764], data_out[760], data_out[756], data_out[752], data_out[748],
          data_out[744], data_out[740], data_out[736], data_out[732], data_out[728],
          data_out[724], data_out[720], data_out[716], data_out[712], data_out[708],
          data_out[704], data_out[700], data_out[696], data_out[692], data_out[688],
          data_out[684], data_out[680], data_out[676], data_out[672], data_out[668],
          data_out[664], data_out[660], data_out[656], data_out[652], data_out[648],
          data_out[644], data_out[640], data_out[636], data_out[632], data_out[628],
          data_out[624], data_out[620], data_out[616], data_out[612], data_out[608],
          data_out[604], data_out[600], data_out[596], data_out[592], data_out[588],
          data_out[584], data_out[580], data_out[576], data_out[572], data_out[568],
          data_out[564], data_out[560], data_out[556], data_out[552], data_out[548],
          data_out[544], data_out[540], data_out[536], data_out[532], data_out[528],
          data_out[524], data_out[520], data_out[516], data_out[512], data_out[508],
          data_out[504], data_out[500], data_out[496], data_out[492], data_out[488],
          data_out[484], data_out[480], data_out[476], data_out[472], data_out[468],
          data_out[464], data_out[460], data_out[456], data_out[452], data_out[448],
          data_out[444], data_out[440], data_out[436], data_out[432], data_out[428],
          data_out[424], data_out[420], data_out[416], data_out[412], data_out[408],
          data_out[404], data_out[400], data_out[396], data_out[392], data_out[388],
          data_out[384], data_out[380], data_out[376], data_out[372], data_out[368],
          data_out[364], data_out[360], data_out[356], data_out[352], data_out[348],
          data_out[344], data_out[340], data_out[336], data_out[332], data_out[328],
          data_out[324], data_out[320], data_out[316], data_out[312], data_out[308],
          data_out[304], data_out[300], data_out[296], data_out[292], data_out[288],
          data_out[284], data_out[280], data_out[276], data_out[272], data_out[268],
          data_out[264], data_out[260], data_out[256], data_out[252], data_out[248],
          data_out[244], data_out[240], data_out[236], data_out[232], data_out[228],
          data_out[224], data_out[220], data_out[216], data_out[212], data_out[208],
          data_out[204], data_out[200], data_out[196], data_out[192], data_out[188],
          data_out[184], data_out[180], data_out[176], data_out[172], data_out[168],
          data_out[164], data_out[160], data_out[156], data_out[152], data_out[148],
          data_out[144], data_out[140], data_out[136], data_out[132], data_out[128],
          data_out[124], data_out[120], data_out[116], data_out[112], data_out[108],
          data_out[104], data_out[100], data_out[96], data_out[92], data_out[88], data_out[84],
          data_out[80], data_out[76], data_out[72], data_out[68], data_out[64], data_out[60],
          data_out[56], data_out[52], data_out[48], data_out[44], data_out[40], data_out[36],
          data_out[32], data_out[28], data_out[24], data_out[20], data_out[16], data_out[12],
          data_out[8], data_out[4], data_out[0]};
        shifted_readLatch0 = readLatch0;
        Q_int = {shifted_readLatch0[252], shifted_readLatch0[248], shifted_readLatch0[244],
          shifted_readLatch0[240], shifted_readLatch0[236], shifted_readLatch0[232],
          shifted_readLatch0[228], shifted_readLatch0[224], shifted_readLatch0[220],
          shifted_readLatch0[216], shifted_readLatch0[212], shifted_readLatch0[208],
          shifted_readLatch0[204], shifted_readLatch0[200], shifted_readLatch0[196],
          shifted_readLatch0[192], shifted_readLatch0[188], shifted_readLatch0[184],
          shifted_readLatch0[180], shifted_readLatch0[176], shifted_readLatch0[172],
          shifted_readLatch0[168], shifted_readLatch0[164], shifted_readLatch0[160],
          shifted_readLatch0[156], shifted_readLatch0[152], shifted_readLatch0[148],
          shifted_readLatch0[144], shifted_readLatch0[140], shifted_readLatch0[136],
          shifted_readLatch0[132], shifted_readLatch0[128], shifted_readLatch0[124],
          shifted_readLatch0[120], shifted_readLatch0[116], shifted_readLatch0[112],
          shifted_readLatch0[108], shifted_readLatch0[104], shifted_readLatch0[100],
          shifted_readLatch0[96], shifted_readLatch0[92], shifted_readLatch0[88], shifted_readLatch0[84],
          shifted_readLatch0[80], shifted_readLatch0[76], shifted_readLatch0[72], shifted_readLatch0[68],
          shifted_readLatch0[64], shifted_readLatch0[60], shifted_readLatch0[56], shifted_readLatch0[52],
          shifted_readLatch0[48], shifted_readLatch0[44], shifted_readLatch0[40], shifted_readLatch0[36],
          shifted_readLatch0[32], shifted_readLatch0[28], shifted_readLatch0[24], shifted_readLatch0[20],
          shifted_readLatch0[16], shifted_readLatch0[12], shifted_readLatch0[8], shifted_readLatch0[4],
          shifted_readLatch0[0]};
   	$fdisplay(dump_file_desc, "%b", Q_int);
  end
  	end
//    $fclose(filename_dump);
  end
  endtask


  task readWrite;
  begin
    if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0 && CEN_int === 1'b0) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{CEN_int, EMA_int, EMAW_int, EMAS_int, RET1N_int, (STOV_int && !CEN_int)} 
     === 1'bx) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0)) begin
      Q_int = WEN_int !== 1'b1 ? D_int : {64{1'bx}};
      Q_int_delayed = WEN_int !== 1'b1 ? D_int : {64{1'bx}};
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (CEN_int === 1'b0) begin
      mux_address = (A_int & 4'b1111);
      row_address = (A_int >> 4);
      if (row_address > 31)
        row = {1024{1'bx}};
      else
        row = mem[row_address];
      writeEnable = ~{64{WEN_int}};
      if (WEN_int !== 1'b1) begin
        row_mask =  ( {15'b000000000000000, writeEnable[63], 15'b000000000000000, writeEnable[62],
          15'b000000000000000, writeEnable[61], 15'b000000000000000, writeEnable[60],
          15'b000000000000000, writeEnable[59], 15'b000000000000000, writeEnable[58],
          15'b000000000000000, writeEnable[57], 15'b000000000000000, writeEnable[56],
          15'b000000000000000, writeEnable[55], 15'b000000000000000, writeEnable[54],
          15'b000000000000000, writeEnable[53], 15'b000000000000000, writeEnable[52],
          15'b000000000000000, writeEnable[51], 15'b000000000000000, writeEnable[50],
          15'b000000000000000, writeEnable[49], 15'b000000000000000, writeEnable[48],
          15'b000000000000000, writeEnable[47], 15'b000000000000000, writeEnable[46],
          15'b000000000000000, writeEnable[45], 15'b000000000000000, writeEnable[44],
          15'b000000000000000, writeEnable[43], 15'b000000000000000, writeEnable[42],
          15'b000000000000000, writeEnable[41], 15'b000000000000000, writeEnable[40],
          15'b000000000000000, writeEnable[39], 15'b000000000000000, writeEnable[38],
          15'b000000000000000, writeEnable[37], 15'b000000000000000, writeEnable[36],
          15'b000000000000000, writeEnable[35], 15'b000000000000000, writeEnable[34],
          15'b000000000000000, writeEnable[33], 15'b000000000000000, writeEnable[32],
          15'b000000000000000, writeEnable[31], 15'b000000000000000, writeEnable[30],
          15'b000000000000000, writeEnable[29], 15'b000000000000000, writeEnable[28],
          15'b000000000000000, writeEnable[27], 15'b000000000000000, writeEnable[26],
          15'b000000000000000, writeEnable[25], 15'b000000000000000, writeEnable[24],
          15'b000000000000000, writeEnable[23], 15'b000000000000000, writeEnable[22],
          15'b000000000000000, writeEnable[21], 15'b000000000000000, writeEnable[20],
          15'b000000000000000, writeEnable[19], 15'b000000000000000, writeEnable[18],
          15'b000000000000000, writeEnable[17], 15'b000000000000000, writeEnable[16],
          15'b000000000000000, writeEnable[15], 15'b000000000000000, writeEnable[14],
          15'b000000000000000, writeEnable[13], 15'b000000000000000, writeEnable[12],
          15'b000000000000000, writeEnable[11], 15'b000000000000000, writeEnable[10],
          15'b000000000000000, writeEnable[9], 15'b000000000000000, writeEnable[8],
          15'b000000000000000, writeEnable[7], 15'b000000000000000, writeEnable[6],
          15'b000000000000000, writeEnable[5], 15'b000000000000000, writeEnable[4],
          15'b000000000000000, writeEnable[3], 15'b000000000000000, writeEnable[2],
          15'b000000000000000, writeEnable[1], 15'b000000000000000, writeEnable[0]} << mux_address);
        new_data =  ( {15'b000000000000000, D_int[63], 15'b000000000000000, D_int[62],
          15'b000000000000000, D_int[61], 15'b000000000000000, D_int[60], 15'b000000000000000, D_int[59],
          15'b000000000000000, D_int[58], 15'b000000000000000, D_int[57], 15'b000000000000000, D_int[56],
          15'b000000000000000, D_int[55], 15'b000000000000000, D_int[54], 15'b000000000000000, D_int[53],
          15'b000000000000000, D_int[52], 15'b000000000000000, D_int[51], 15'b000000000000000, D_int[50],
          15'b000000000000000, D_int[49], 15'b000000000000000, D_int[48], 15'b000000000000000, D_int[47],
          15'b000000000000000, D_int[46], 15'b000000000000000, D_int[45], 15'b000000000000000, D_int[44],
          15'b000000000000000, D_int[43], 15'b000000000000000, D_int[42], 15'b000000000000000, D_int[41],
          15'b000000000000000, D_int[40], 15'b000000000000000, D_int[39], 15'b000000000000000, D_int[38],
          15'b000000000000000, D_int[37], 15'b000000000000000, D_int[36], 15'b000000000000000, D_int[35],
          15'b000000000000000, D_int[34], 15'b000000000000000, D_int[33], 15'b000000000000000, D_int[32],
          15'b000000000000000, D_int[31], 15'b000000000000000, D_int[30], 15'b000000000000000, D_int[29],
          15'b000000000000000, D_int[28], 15'b000000000000000, D_int[27], 15'b000000000000000, D_int[26],
          15'b000000000000000, D_int[25], 15'b000000000000000, D_int[24], 15'b000000000000000, D_int[23],
          15'b000000000000000, D_int[22], 15'b000000000000000, D_int[21], 15'b000000000000000, D_int[20],
          15'b000000000000000, D_int[19], 15'b000000000000000, D_int[18], 15'b000000000000000, D_int[17],
          15'b000000000000000, D_int[16], 15'b000000000000000, D_int[15], 15'b000000000000000, D_int[14],
          15'b000000000000000, D_int[13], 15'b000000000000000, D_int[12], 15'b000000000000000, D_int[11],
          15'b000000000000000, D_int[10], 15'b000000000000000, D_int[9], 15'b000000000000000, D_int[8],
          15'b000000000000000, D_int[7], 15'b000000000000000, D_int[6], 15'b000000000000000, D_int[5],
          15'b000000000000000, D_int[4], 15'b000000000000000, D_int[3], 15'b000000000000000, D_int[2],
          15'b000000000000000, D_int[1], 15'b000000000000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        mem[row_address] = row;
      end else begin
        data_out = (row >> (mux_address%4));
        readLatch0 = {data_out[1020], data_out[1016], data_out[1012], data_out[1008],
          data_out[1004], data_out[1000], data_out[996], data_out[992], data_out[988],
          data_out[984], data_out[980], data_out[976], data_out[972], data_out[968],
          data_out[964], data_out[960], data_out[956], data_out[952], data_out[948],
          data_out[944], data_out[940], data_out[936], data_out[932], data_out[928],
          data_out[924], data_out[920], data_out[916], data_out[912], data_out[908],
          data_out[904], data_out[900], data_out[896], data_out[892], data_out[888],
          data_out[884], data_out[880], data_out[876], data_out[872], data_out[868],
          data_out[864], data_out[860], data_out[856], data_out[852], data_out[848],
          data_out[844], data_out[840], data_out[836], data_out[832], data_out[828],
          data_out[824], data_out[820], data_out[816], data_out[812], data_out[808],
          data_out[804], data_out[800], data_out[796], data_out[792], data_out[788],
          data_out[784], data_out[780], data_out[776], data_out[772], data_out[768],
          data_out[764], data_out[760], data_out[756], data_out[752], data_out[748],
          data_out[744], data_out[740], data_out[736], data_out[732], data_out[728],
          data_out[724], data_out[720], data_out[716], data_out[712], data_out[708],
          data_out[704], data_out[700], data_out[696], data_out[692], data_out[688],
          data_out[684], data_out[680], data_out[676], data_out[672], data_out[668],
          data_out[664], data_out[660], data_out[656], data_out[652], data_out[648],
          data_out[644], data_out[640], data_out[636], data_out[632], data_out[628],
          data_out[624], data_out[620], data_out[616], data_out[612], data_out[608],
          data_out[604], data_out[600], data_out[596], data_out[592], data_out[588],
          data_out[584], data_out[580], data_out[576], data_out[572], data_out[568],
          data_out[564], data_out[560], data_out[556], data_out[552], data_out[548],
          data_out[544], data_out[540], data_out[536], data_out[532], data_out[528],
          data_out[524], data_out[520], data_out[516], data_out[512], data_out[508],
          data_out[504], data_out[500], data_out[496], data_out[492], data_out[488],
          data_out[484], data_out[480], data_out[476], data_out[472], data_out[468],
          data_out[464], data_out[460], data_out[456], data_out[452], data_out[448],
          data_out[444], data_out[440], data_out[436], data_out[432], data_out[428],
          data_out[424], data_out[420], data_out[416], data_out[412], data_out[408],
          data_out[404], data_out[400], data_out[396], data_out[392], data_out[388],
          data_out[384], data_out[380], data_out[376], data_out[372], data_out[368],
          data_out[364], data_out[360], data_out[356], data_out[352], data_out[348],
          data_out[344], data_out[340], data_out[336], data_out[332], data_out[328],
          data_out[324], data_out[320], data_out[316], data_out[312], data_out[308],
          data_out[304], data_out[300], data_out[296], data_out[292], data_out[288],
          data_out[284], data_out[280], data_out[276], data_out[272], data_out[268],
          data_out[264], data_out[260], data_out[256], data_out[252], data_out[248],
          data_out[244], data_out[240], data_out[236], data_out[232], data_out[228],
          data_out[224], data_out[220], data_out[216], data_out[212], data_out[208],
          data_out[204], data_out[200], data_out[196], data_out[192], data_out[188],
          data_out[184], data_out[180], data_out[176], data_out[172], data_out[168],
          data_out[164], data_out[160], data_out[156], data_out[152], data_out[148],
          data_out[144], data_out[140], data_out[136], data_out[132], data_out[128],
          data_out[124], data_out[120], data_out[116], data_out[112], data_out[108],
          data_out[104], data_out[100], data_out[96], data_out[92], data_out[88], data_out[84],
          data_out[80], data_out[76], data_out[72], data_out[68], data_out[64], data_out[60],
          data_out[56], data_out[52], data_out[48], data_out[44], data_out[40], data_out[36],
          data_out[32], data_out[28], data_out[24], data_out[20], data_out[16], data_out[12],
          data_out[8], data_out[4], data_out[0]};
      end
      if (WEN_int !== 1'b1) begin
        Q_int = D_int;
        Q_int_delayed = D_int;
      end else begin
        shifted_readLatch0 = (readLatch0 >> A_int[3:2]);
        Q_int = {shifted_readLatch0[252], shifted_readLatch0[248], shifted_readLatch0[244],
          shifted_readLatch0[240], shifted_readLatch0[236], shifted_readLatch0[232],
          shifted_readLatch0[228], shifted_readLatch0[224], shifted_readLatch0[220],
          shifted_readLatch0[216], shifted_readLatch0[212], shifted_readLatch0[208],
          shifted_readLatch0[204], shifted_readLatch0[200], shifted_readLatch0[196],
          shifted_readLatch0[192], shifted_readLatch0[188], shifted_readLatch0[184],
          shifted_readLatch0[180], shifted_readLatch0[176], shifted_readLatch0[172],
          shifted_readLatch0[168], shifted_readLatch0[164], shifted_readLatch0[160],
          shifted_readLatch0[156], shifted_readLatch0[152], shifted_readLatch0[148],
          shifted_readLatch0[144], shifted_readLatch0[140], shifted_readLatch0[136],
          shifted_readLatch0[132], shifted_readLatch0[128], shifted_readLatch0[124],
          shifted_readLatch0[120], shifted_readLatch0[116], shifted_readLatch0[112],
          shifted_readLatch0[108], shifted_readLatch0[104], shifted_readLatch0[100],
          shifted_readLatch0[96], shifted_readLatch0[92], shifted_readLatch0[88], shifted_readLatch0[84],
          shifted_readLatch0[80], shifted_readLatch0[76], shifted_readLatch0[72], shifted_readLatch0[68],
          shifted_readLatch0[64], shifted_readLatch0[60], shifted_readLatch0[56], shifted_readLatch0[52],
          shifted_readLatch0[48], shifted_readLatch0[44], shifted_readLatch0[40], shifted_readLatch0[36],
          shifted_readLatch0[32], shifted_readLatch0[28], shifted_readLatch0[24], shifted_readLatch0[20],
          shifted_readLatch0[16], shifted_readLatch0[12], shifted_readLatch0[8], shifted_readLatch0[4],
          shifted_readLatch0[0]};
      end
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  	end
  end

  always @ RET1N_ begin
    if (CLK_ == 1'b1) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0) ) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end
    if (RET1N_ == 1'b0) begin
      Q_int = {64{1'bx}};
      Q_int_delayed = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {9{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {9{1'bx}};
      TD_int = {64{1'bx}};
      TQ_int = {64{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end else begin
      Q_int = {64{1'bx}};
      Q_int_delayed = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = 1'bx;
      A_int = {9{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      EMAS_int = 1'bx;
      TEN_int = 1'bx;
      BEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = 1'bx;
      TA_int = {9{1'bx}};
      TD_int = {64{1'bx}};
      TQ_int = {64{1'bx}};
      RET1N_int = 1'bx;
      STOV_int = 1'bx;
    end
    RET1N_int = RET1N_;
  end


  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDDCE === 1'bx || VDDCE === 1'bz)
      $display("ERROR: Illegal value for VDDCE %b", VDDCE);
    if (VDDPE === 1'bx || VDDPE === 1'bz)
      $display("ERROR: Illegal value for VDDPE %b", VDDPE);
    if (VSSE === 1'bx || VSSE === 1'bz)
      $display("ERROR: Illegal value for VSSE %b", VSSE);
`endif
  if (RET1N_ == 1'b0) begin
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
      Q_int = {64{1'bx}};
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      EMAS_int = EMAS_;
      TEN_int = TEN_;
      BEN_int = BEN_;
      TWEN_int = TWEN_;
      TQ_int = TQ_;
      RET1N_int = RET1N_;
      STOV_int = STOV_;
      if (CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        if (WEN_int === 1'b1)
          read_mux_sel0 = (TEN_ ? A_[3:2] : TA_[3:2] );
      end
      clk0_int = 1'b0;
      if (CEN_int === 1'b0 && WEN_int === 1'b1) 
         Q_int_delayed = {64{1'bx}};
    readWrite;
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
      Q_int_delayed = Q_int;
    end
    LAST_CLK = CLK_;
  end
  end

  reg globalNotifier0;
  initial globalNotifier0 = 1'b0;

  always @ globalNotifier0 begin
    if ($realtime == 0) begin
    end else if (CEN_int === 1'bx || EMAS_int === 1'bx || EMAW_int[0] === 1'bx || 
      EMAW_int[1] === 1'bx || EMA_int[0] === 1'bx || EMA_int[1] === 1'bx || EMA_int[2] === 1'bx || 
      RET1N_int === 1'bx || (STOV_int && !CEN_int) === 1'bx || TEN_int === 1'bx || 
      clk0_int === 1'bx) begin
      Q_int = {64{1'bx}};
    if (clk0_int === 1'bx || CEN_int === 1'bx) begin
      D_int = {64{1'bx}};
    end
      failedWrite(0);
    end else begin
      readWrite;
   end
    globalNotifier0 = 1'b0;
  end

  always @ NOT_CEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN begin
    WEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D63 begin
    D_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D62 begin
    D_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D61 begin
    D_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D60 begin
    D_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D59 begin
    D_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D58 begin
    D_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D57 begin
    D_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D56 begin
    D_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D55 begin
    D_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D54 begin
    D_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D53 begin
    D_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D52 begin
    D_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D51 begin
    D_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D50 begin
    D_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D49 begin
    D_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D48 begin
    D_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D47 begin
    D_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D46 begin
    D_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D45 begin
    D_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D44 begin
    D_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D43 begin
    D_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D42 begin
    D_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D41 begin
    D_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D40 begin
    D_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D39 begin
    D_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D38 begin
    D_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D37 begin
    D_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D36 begin
    D_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D35 begin
    D_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D34 begin
    D_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D33 begin
    D_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D32 begin
    D_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D31 begin
    D_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D30 begin
    D_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D29 begin
    D_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D28 begin
    D_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D27 begin
    D_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D26 begin
    D_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D25 begin
    D_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D24 begin
    D_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D23 begin
    D_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D22 begin
    D_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D21 begin
    D_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D20 begin
    D_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D19 begin
    D_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D18 begin
    D_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D17 begin
    D_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D16 begin
    D_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D15 begin
    D_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D14 begin
    D_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D13 begin
    D_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D12 begin
    D_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D11 begin
    D_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D10 begin
    D_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D9 begin
    D_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D8 begin
    D_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA2 begin
    EMA_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA1 begin
    EMA_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA0 begin
    EMA_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW1 begin
    EMAW_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW0 begin
    EMAW_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAS begin
    EMAS_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TEN begin
    TEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TCEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN begin
    WEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD63 begin
    D_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD62 begin
    D_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD61 begin
    D_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD60 begin
    D_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD59 begin
    D_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD58 begin
    D_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD57 begin
    D_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD56 begin
    D_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD55 begin
    D_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD54 begin
    D_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD53 begin
    D_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD52 begin
    D_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD51 begin
    D_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD50 begin
    D_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD49 begin
    D_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD48 begin
    D_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD47 begin
    D_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD46 begin
    D_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD45 begin
    D_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD44 begin
    D_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD43 begin
    D_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD42 begin
    D_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD41 begin
    D_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD40 begin
    D_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD39 begin
    D_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD38 begin
    D_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD37 begin
    D_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD36 begin
    D_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD35 begin
    D_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD34 begin
    D_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD33 begin
    D_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD32 begin
    D_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD31 begin
    D_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD30 begin
    D_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD29 begin
    D_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD28 begin
    D_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD27 begin
    D_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD26 begin
    D_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD25 begin
    D_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD24 begin
    D_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD23 begin
    D_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD22 begin
    D_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD21 begin
    D_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD20 begin
    D_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD19 begin
    D_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD18 begin
    D_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD17 begin
    D_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD16 begin
    D_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD15 begin
    D_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD14 begin
    D_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD13 begin
    D_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD12 begin
    D_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD11 begin
    D_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD10 begin
    D_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD9 begin
    D_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD8 begin
    D_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_RET1N begin
    RET1N_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_STOV begin
    STOV_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end

  always @ NOT_CLK_PER begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINH begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINL begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end


  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire STOVeq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp;
  wire opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp;
  wire opTENeq1andCENeq0cporopTENeq0andTCENeq0cp;

  wire STOVeq0, STOVeq1andEMASeq0, STOVeq1andEMASeq1, TENeq1andCENeq0, TENeq1andCENeq0andWENeq0;
  wire TENeq0andTCENeq0, TENeq0andTCENeq0andTWENeq0, TENeq1, TENeq0;

  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (STOV) && (!EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp = 
         (STOV) && (EMAS) && ((TEN && WEN) || (!TEN && TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (!EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (!EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (!EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (!EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (!EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (!STOV) && (EMA[2]) && (EMA[1]) && (EMA[0]) && (EMAW[1]) && (EMAW[0]) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp = 
         (STOV) && ((TEN && !WEN) || (!TEN && !TWEN)) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq0 = 
         (STOV) && (!EMAS) && !(TEN ? CEN : TCEN);
  assign STOVeq1andEMASeq1 = 
         (STOV) && (EMAS) && !(TEN ? CEN : TCEN);
  assign TENeq1andCENeq0 = 
         !(!TEN || CEN);
  assign TENeq1andCENeq0andWENeq0 = 
         !(!TEN ||  CEN || WEN);
  assign TENeq0andTCENeq0 = 
         !(TEN || TCEN);
  assign TENeq0andTCENeq0andTWENeq0 = 
         !(TEN ||  TCEN || TWEN);
  assign opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp = 
         ((TEN ? CEN : TCEN));
  assign opTENeq1andCENeq0cporopTENeq0andTCENeq0cp = 
         !(TEN ? CEN : TCEN);

  assign STOVeq0 = (!STOV) && !(TEN ? CEN : TCEN);
  assign TENeq1 = TEN;
  assign TENeq0 = !TEN;

  specify
    if (CEN == 1'b0 && TCEN == 1'b1)
       (TEN => CENY) = (1.000, 1.000);
    if (CEN == 1'b1 && TCEN == 1'b0)
       (TEN => CENY) = (1.000, 1.000);
    if (TEN == 1'b1)
       (CEN => CENY) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TCEN => CENY) = (1.000, 1.000);
    if (WEN == 1'b0 && TWEN == 1'b1)
       (TEN => WENY) = (1.000, 1.000);
    if (WEN == 1'b1 && TWEN == 1'b0)
       (TEN => WENY) = (1.000, 1.000);
    if (TEN == 1'b1)
       (WEN => WENY) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TWEN => WENY) = (1.000, 1.000);
    if (A[8] == 1'b0 && TA[8] == 1'b1)
       (TEN => AY[8]) = (1.000, 1.000);
    if (A[8] == 1'b1 && TA[8] == 1'b0)
       (TEN => AY[8]) = (1.000, 1.000);
    if (A[7] == 1'b0 && TA[7] == 1'b1)
       (TEN => AY[7]) = (1.000, 1.000);
    if (A[7] == 1'b1 && TA[7] == 1'b0)
       (TEN => AY[7]) = (1.000, 1.000);
    if (A[6] == 1'b0 && TA[6] == 1'b1)
       (TEN => AY[6]) = (1.000, 1.000);
    if (A[6] == 1'b1 && TA[6] == 1'b0)
       (TEN => AY[6]) = (1.000, 1.000);
    if (A[5] == 1'b0 && TA[5] == 1'b1)
       (TEN => AY[5]) = (1.000, 1.000);
    if (A[5] == 1'b1 && TA[5] == 1'b0)
       (TEN => AY[5]) = (1.000, 1.000);
    if (A[4] == 1'b0 && TA[4] == 1'b1)
       (TEN => AY[4]) = (1.000, 1.000);
    if (A[4] == 1'b1 && TA[4] == 1'b0)
       (TEN => AY[4]) = (1.000, 1.000);
    if (A[3] == 1'b0 && TA[3] == 1'b1)
       (TEN => AY[3]) = (1.000, 1.000);
    if (A[3] == 1'b1 && TA[3] == 1'b0)
       (TEN => AY[3]) = (1.000, 1.000);
    if (A[2] == 1'b0 && TA[2] == 1'b1)
       (TEN => AY[2]) = (1.000, 1.000);
    if (A[2] == 1'b1 && TA[2] == 1'b0)
       (TEN => AY[2]) = (1.000, 1.000);
    if (A[1] == 1'b0 && TA[1] == 1'b1)
       (TEN => AY[1]) = (1.000, 1.000);
    if (A[1] == 1'b1 && TA[1] == 1'b0)
       (TEN => AY[1]) = (1.000, 1.000);
    if (A[0] == 1'b0 && TA[0] == 1'b1)
       (TEN => AY[0]) = (1.000, 1.000);
    if (A[0] == 1'b1 && TA[0] == 1'b0)
       (TEN => AY[0]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[8] => AY[8]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[7] => AY[7]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[6] => AY[6]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[5] => AY[5]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[4] => AY[4]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[3] => AY[3]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[2] => AY[2]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[1] => AY[1]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (A[0] => AY[0]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[8] => AY[8]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[7] => AY[7]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[6] => AY[6]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[5] => AY[5]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[4] => AY[4]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[3] => AY[3]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[2] => AY[2]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[1] => AY[1]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TA[0] => AY[0]) = (1.000, 1.000);
    if (D[63] == 1'b0 && TD[63] == 1'b1)
       (TEN => DY[63]) = (1.000, 1.000);
    if (D[63] == 1'b1 && TD[63] == 1'b0)
       (TEN => DY[63]) = (1.000, 1.000);
    if (D[62] == 1'b0 && TD[62] == 1'b1)
       (TEN => DY[62]) = (1.000, 1.000);
    if (D[62] == 1'b1 && TD[62] == 1'b0)
       (TEN => DY[62]) = (1.000, 1.000);
    if (D[61] == 1'b0 && TD[61] == 1'b1)
       (TEN => DY[61]) = (1.000, 1.000);
    if (D[61] == 1'b1 && TD[61] == 1'b0)
       (TEN => DY[61]) = (1.000, 1.000);
    if (D[60] == 1'b0 && TD[60] == 1'b1)
       (TEN => DY[60]) = (1.000, 1.000);
    if (D[60] == 1'b1 && TD[60] == 1'b0)
       (TEN => DY[60]) = (1.000, 1.000);
    if (D[59] == 1'b0 && TD[59] == 1'b1)
       (TEN => DY[59]) = (1.000, 1.000);
    if (D[59] == 1'b1 && TD[59] == 1'b0)
       (TEN => DY[59]) = (1.000, 1.000);
    if (D[58] == 1'b0 && TD[58] == 1'b1)
       (TEN => DY[58]) = (1.000, 1.000);
    if (D[58] == 1'b1 && TD[58] == 1'b0)
       (TEN => DY[58]) = (1.000, 1.000);
    if (D[57] == 1'b0 && TD[57] == 1'b1)
       (TEN => DY[57]) = (1.000, 1.000);
    if (D[57] == 1'b1 && TD[57] == 1'b0)
       (TEN => DY[57]) = (1.000, 1.000);
    if (D[56] == 1'b0 && TD[56] == 1'b1)
       (TEN => DY[56]) = (1.000, 1.000);
    if (D[56] == 1'b1 && TD[56] == 1'b0)
       (TEN => DY[56]) = (1.000, 1.000);
    if (D[55] == 1'b0 && TD[55] == 1'b1)
       (TEN => DY[55]) = (1.000, 1.000);
    if (D[55] == 1'b1 && TD[55] == 1'b0)
       (TEN => DY[55]) = (1.000, 1.000);
    if (D[54] == 1'b0 && TD[54] == 1'b1)
       (TEN => DY[54]) = (1.000, 1.000);
    if (D[54] == 1'b1 && TD[54] == 1'b0)
       (TEN => DY[54]) = (1.000, 1.000);
    if (D[53] == 1'b0 && TD[53] == 1'b1)
       (TEN => DY[53]) = (1.000, 1.000);
    if (D[53] == 1'b1 && TD[53] == 1'b0)
       (TEN => DY[53]) = (1.000, 1.000);
    if (D[52] == 1'b0 && TD[52] == 1'b1)
       (TEN => DY[52]) = (1.000, 1.000);
    if (D[52] == 1'b1 && TD[52] == 1'b0)
       (TEN => DY[52]) = (1.000, 1.000);
    if (D[51] == 1'b0 && TD[51] == 1'b1)
       (TEN => DY[51]) = (1.000, 1.000);
    if (D[51] == 1'b1 && TD[51] == 1'b0)
       (TEN => DY[51]) = (1.000, 1.000);
    if (D[50] == 1'b0 && TD[50] == 1'b1)
       (TEN => DY[50]) = (1.000, 1.000);
    if (D[50] == 1'b1 && TD[50] == 1'b0)
       (TEN => DY[50]) = (1.000, 1.000);
    if (D[49] == 1'b0 && TD[49] == 1'b1)
       (TEN => DY[49]) = (1.000, 1.000);
    if (D[49] == 1'b1 && TD[49] == 1'b0)
       (TEN => DY[49]) = (1.000, 1.000);
    if (D[48] == 1'b0 && TD[48] == 1'b1)
       (TEN => DY[48]) = (1.000, 1.000);
    if (D[48] == 1'b1 && TD[48] == 1'b0)
       (TEN => DY[48]) = (1.000, 1.000);
    if (D[47] == 1'b0 && TD[47] == 1'b1)
       (TEN => DY[47]) = (1.000, 1.000);
    if (D[47] == 1'b1 && TD[47] == 1'b0)
       (TEN => DY[47]) = (1.000, 1.000);
    if (D[46] == 1'b0 && TD[46] == 1'b1)
       (TEN => DY[46]) = (1.000, 1.000);
    if (D[46] == 1'b1 && TD[46] == 1'b0)
       (TEN => DY[46]) = (1.000, 1.000);
    if (D[45] == 1'b0 && TD[45] == 1'b1)
       (TEN => DY[45]) = (1.000, 1.000);
    if (D[45] == 1'b1 && TD[45] == 1'b0)
       (TEN => DY[45]) = (1.000, 1.000);
    if (D[44] == 1'b0 && TD[44] == 1'b1)
       (TEN => DY[44]) = (1.000, 1.000);
    if (D[44] == 1'b1 && TD[44] == 1'b0)
       (TEN => DY[44]) = (1.000, 1.000);
    if (D[43] == 1'b0 && TD[43] == 1'b1)
       (TEN => DY[43]) = (1.000, 1.000);
    if (D[43] == 1'b1 && TD[43] == 1'b0)
       (TEN => DY[43]) = (1.000, 1.000);
    if (D[42] == 1'b0 && TD[42] == 1'b1)
       (TEN => DY[42]) = (1.000, 1.000);
    if (D[42] == 1'b1 && TD[42] == 1'b0)
       (TEN => DY[42]) = (1.000, 1.000);
    if (D[41] == 1'b0 && TD[41] == 1'b1)
       (TEN => DY[41]) = (1.000, 1.000);
    if (D[41] == 1'b1 && TD[41] == 1'b0)
       (TEN => DY[41]) = (1.000, 1.000);
    if (D[40] == 1'b0 && TD[40] == 1'b1)
       (TEN => DY[40]) = (1.000, 1.000);
    if (D[40] == 1'b1 && TD[40] == 1'b0)
       (TEN => DY[40]) = (1.000, 1.000);
    if (D[39] == 1'b0 && TD[39] == 1'b1)
       (TEN => DY[39]) = (1.000, 1.000);
    if (D[39] == 1'b1 && TD[39] == 1'b0)
       (TEN => DY[39]) = (1.000, 1.000);
    if (D[38] == 1'b0 && TD[38] == 1'b1)
       (TEN => DY[38]) = (1.000, 1.000);
    if (D[38] == 1'b1 && TD[38] == 1'b0)
       (TEN => DY[38]) = (1.000, 1.000);
    if (D[37] == 1'b0 && TD[37] == 1'b1)
       (TEN => DY[37]) = (1.000, 1.000);
    if (D[37] == 1'b1 && TD[37] == 1'b0)
       (TEN => DY[37]) = (1.000, 1.000);
    if (D[36] == 1'b0 && TD[36] == 1'b1)
       (TEN => DY[36]) = (1.000, 1.000);
    if (D[36] == 1'b1 && TD[36] == 1'b0)
       (TEN => DY[36]) = (1.000, 1.000);
    if (D[35] == 1'b0 && TD[35] == 1'b1)
       (TEN => DY[35]) = (1.000, 1.000);
    if (D[35] == 1'b1 && TD[35] == 1'b0)
       (TEN => DY[35]) = (1.000, 1.000);
    if (D[34] == 1'b0 && TD[34] == 1'b1)
       (TEN => DY[34]) = (1.000, 1.000);
    if (D[34] == 1'b1 && TD[34] == 1'b0)
       (TEN => DY[34]) = (1.000, 1.000);
    if (D[33] == 1'b0 && TD[33] == 1'b1)
       (TEN => DY[33]) = (1.000, 1.000);
    if (D[33] == 1'b1 && TD[33] == 1'b0)
       (TEN => DY[33]) = (1.000, 1.000);
    if (D[32] == 1'b0 && TD[32] == 1'b1)
       (TEN => DY[32]) = (1.000, 1.000);
    if (D[32] == 1'b1 && TD[32] == 1'b0)
       (TEN => DY[32]) = (1.000, 1.000);
    if (D[31] == 1'b0 && TD[31] == 1'b1)
       (TEN => DY[31]) = (1.000, 1.000);
    if (D[31] == 1'b1 && TD[31] == 1'b0)
       (TEN => DY[31]) = (1.000, 1.000);
    if (D[30] == 1'b0 && TD[30] == 1'b1)
       (TEN => DY[30]) = (1.000, 1.000);
    if (D[30] == 1'b1 && TD[30] == 1'b0)
       (TEN => DY[30]) = (1.000, 1.000);
    if (D[29] == 1'b0 && TD[29] == 1'b1)
       (TEN => DY[29]) = (1.000, 1.000);
    if (D[29] == 1'b1 && TD[29] == 1'b0)
       (TEN => DY[29]) = (1.000, 1.000);
    if (D[28] == 1'b0 && TD[28] == 1'b1)
       (TEN => DY[28]) = (1.000, 1.000);
    if (D[28] == 1'b1 && TD[28] == 1'b0)
       (TEN => DY[28]) = (1.000, 1.000);
    if (D[27] == 1'b0 && TD[27] == 1'b1)
       (TEN => DY[27]) = (1.000, 1.000);
    if (D[27] == 1'b1 && TD[27] == 1'b0)
       (TEN => DY[27]) = (1.000, 1.000);
    if (D[26] == 1'b0 && TD[26] == 1'b1)
       (TEN => DY[26]) = (1.000, 1.000);
    if (D[26] == 1'b1 && TD[26] == 1'b0)
       (TEN => DY[26]) = (1.000, 1.000);
    if (D[25] == 1'b0 && TD[25] == 1'b1)
       (TEN => DY[25]) = (1.000, 1.000);
    if (D[25] == 1'b1 && TD[25] == 1'b0)
       (TEN => DY[25]) = (1.000, 1.000);
    if (D[24] == 1'b0 && TD[24] == 1'b1)
       (TEN => DY[24]) = (1.000, 1.000);
    if (D[24] == 1'b1 && TD[24] == 1'b0)
       (TEN => DY[24]) = (1.000, 1.000);
    if (D[23] == 1'b0 && TD[23] == 1'b1)
       (TEN => DY[23]) = (1.000, 1.000);
    if (D[23] == 1'b1 && TD[23] == 1'b0)
       (TEN => DY[23]) = (1.000, 1.000);
    if (D[22] == 1'b0 && TD[22] == 1'b1)
       (TEN => DY[22]) = (1.000, 1.000);
    if (D[22] == 1'b1 && TD[22] == 1'b0)
       (TEN => DY[22]) = (1.000, 1.000);
    if (D[21] == 1'b0 && TD[21] == 1'b1)
       (TEN => DY[21]) = (1.000, 1.000);
    if (D[21] == 1'b1 && TD[21] == 1'b0)
       (TEN => DY[21]) = (1.000, 1.000);
    if (D[20] == 1'b0 && TD[20] == 1'b1)
       (TEN => DY[20]) = (1.000, 1.000);
    if (D[20] == 1'b1 && TD[20] == 1'b0)
       (TEN => DY[20]) = (1.000, 1.000);
    if (D[19] == 1'b0 && TD[19] == 1'b1)
       (TEN => DY[19]) = (1.000, 1.000);
    if (D[19] == 1'b1 && TD[19] == 1'b0)
       (TEN => DY[19]) = (1.000, 1.000);
    if (D[18] == 1'b0 && TD[18] == 1'b1)
       (TEN => DY[18]) = (1.000, 1.000);
    if (D[18] == 1'b1 && TD[18] == 1'b0)
       (TEN => DY[18]) = (1.000, 1.000);
    if (D[17] == 1'b0 && TD[17] == 1'b1)
       (TEN => DY[17]) = (1.000, 1.000);
    if (D[17] == 1'b1 && TD[17] == 1'b0)
       (TEN => DY[17]) = (1.000, 1.000);
    if (D[16] == 1'b0 && TD[16] == 1'b1)
       (TEN => DY[16]) = (1.000, 1.000);
    if (D[16] == 1'b1 && TD[16] == 1'b0)
       (TEN => DY[16]) = (1.000, 1.000);
    if (D[15] == 1'b0 && TD[15] == 1'b1)
       (TEN => DY[15]) = (1.000, 1.000);
    if (D[15] == 1'b1 && TD[15] == 1'b0)
       (TEN => DY[15]) = (1.000, 1.000);
    if (D[14] == 1'b0 && TD[14] == 1'b1)
       (TEN => DY[14]) = (1.000, 1.000);
    if (D[14] == 1'b1 && TD[14] == 1'b0)
       (TEN => DY[14]) = (1.000, 1.000);
    if (D[13] == 1'b0 && TD[13] == 1'b1)
       (TEN => DY[13]) = (1.000, 1.000);
    if (D[13] == 1'b1 && TD[13] == 1'b0)
       (TEN => DY[13]) = (1.000, 1.000);
    if (D[12] == 1'b0 && TD[12] == 1'b1)
       (TEN => DY[12]) = (1.000, 1.000);
    if (D[12] == 1'b1 && TD[12] == 1'b0)
       (TEN => DY[12]) = (1.000, 1.000);
    if (D[11] == 1'b0 && TD[11] == 1'b1)
       (TEN => DY[11]) = (1.000, 1.000);
    if (D[11] == 1'b1 && TD[11] == 1'b0)
       (TEN => DY[11]) = (1.000, 1.000);
    if (D[10] == 1'b0 && TD[10] == 1'b1)
       (TEN => DY[10]) = (1.000, 1.000);
    if (D[10] == 1'b1 && TD[10] == 1'b0)
       (TEN => DY[10]) = (1.000, 1.000);
    if (D[9] == 1'b0 && TD[9] == 1'b1)
       (TEN => DY[9]) = (1.000, 1.000);
    if (D[9] == 1'b1 && TD[9] == 1'b0)
       (TEN => DY[9]) = (1.000, 1.000);
    if (D[8] == 1'b0 && TD[8] == 1'b1)
       (TEN => DY[8]) = (1.000, 1.000);
    if (D[8] == 1'b1 && TD[8] == 1'b0)
       (TEN => DY[8]) = (1.000, 1.000);
    if (D[7] == 1'b0 && TD[7] == 1'b1)
       (TEN => DY[7]) = (1.000, 1.000);
    if (D[7] == 1'b1 && TD[7] == 1'b0)
       (TEN => DY[7]) = (1.000, 1.000);
    if (D[6] == 1'b0 && TD[6] == 1'b1)
       (TEN => DY[6]) = (1.000, 1.000);
    if (D[6] == 1'b1 && TD[6] == 1'b0)
       (TEN => DY[6]) = (1.000, 1.000);
    if (D[5] == 1'b0 && TD[5] == 1'b1)
       (TEN => DY[5]) = (1.000, 1.000);
    if (D[5] == 1'b1 && TD[5] == 1'b0)
       (TEN => DY[5]) = (1.000, 1.000);
    if (D[4] == 1'b0 && TD[4] == 1'b1)
       (TEN => DY[4]) = (1.000, 1.000);
    if (D[4] == 1'b1 && TD[4] == 1'b0)
       (TEN => DY[4]) = (1.000, 1.000);
    if (D[3] == 1'b0 && TD[3] == 1'b1)
       (TEN => DY[3]) = (1.000, 1.000);
    if (D[3] == 1'b1 && TD[3] == 1'b0)
       (TEN => DY[3]) = (1.000, 1.000);
    if (D[2] == 1'b0 && TD[2] == 1'b1)
       (TEN => DY[2]) = (1.000, 1.000);
    if (D[2] == 1'b1 && TD[2] == 1'b0)
       (TEN => DY[2]) = (1.000, 1.000);
    if (D[1] == 1'b0 && TD[1] == 1'b1)
       (TEN => DY[1]) = (1.000, 1.000);
    if (D[1] == 1'b1 && TD[1] == 1'b0)
       (TEN => DY[1]) = (1.000, 1.000);
    if (D[0] == 1'b0 && TD[0] == 1'b1)
       (TEN => DY[0]) = (1.000, 1.000);
    if (D[0] == 1'b1 && TD[0] == 1'b0)
       (TEN => DY[0]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[63] => DY[63]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[62] => DY[62]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[61] => DY[61]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[60] => DY[60]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[59] => DY[59]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[58] => DY[58]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[57] => DY[57]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[56] => DY[56]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[55] => DY[55]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[54] => DY[54]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[53] => DY[53]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[52] => DY[52]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[51] => DY[51]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[50] => DY[50]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[49] => DY[49]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[48] => DY[48]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[47] => DY[47]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[46] => DY[46]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[45] => DY[45]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[44] => DY[44]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[43] => DY[43]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[42] => DY[42]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[41] => DY[41]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[40] => DY[40]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[39] => DY[39]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[38] => DY[38]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[37] => DY[37]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[36] => DY[36]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[35] => DY[35]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[34] => DY[34]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[33] => DY[33]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[32] => DY[32]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[31] => DY[31]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[30] => DY[30]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[29] => DY[29]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[28] => DY[28]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[27] => DY[27]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[26] => DY[26]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[25] => DY[25]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[24] => DY[24]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[23] => DY[23]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[22] => DY[22]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[21] => DY[21]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[20] => DY[20]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[19] => DY[19]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[18] => DY[18]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[17] => DY[17]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[16] => DY[16]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[15] => DY[15]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[14] => DY[14]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[13] => DY[13]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[12] => DY[12]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[11] => DY[11]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[10] => DY[10]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[9] => DY[9]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[8] => DY[8]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[7] => DY[7]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[6] => DY[6]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[5] => DY[5]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[4] => DY[4]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[3] => DY[3]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[2] => DY[2]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[1] => DY[1]) = (1.000, 1.000);
    if (TEN == 1'b1)
       (D[0] => DY[0]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[63] => DY[63]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[62] => DY[62]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[61] => DY[61]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[60] => DY[60]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[59] => DY[59]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[58] => DY[58]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[57] => DY[57]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[56] => DY[56]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[55] => DY[55]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[54] => DY[54]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[53] => DY[53]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[52] => DY[52]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[51] => DY[51]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[50] => DY[50]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[49] => DY[49]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[48] => DY[48]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[47] => DY[47]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[46] => DY[46]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[45] => DY[45]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[44] => DY[44]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[43] => DY[43]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[42] => DY[42]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[41] => DY[41]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[40] => DY[40]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[39] => DY[39]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[38] => DY[38]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[37] => DY[37]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[36] => DY[36]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[35] => DY[35]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[34] => DY[34]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[33] => DY[33]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[32] => DY[32]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[31] => DY[31]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[30] => DY[30]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[29] => DY[29]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[28] => DY[28]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[27] => DY[27]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[26] => DY[26]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[25] => DY[25]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[24] => DY[24]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[23] => DY[23]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[22] => DY[22]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[21] => DY[21]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[20] => DY[20]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[19] => DY[19]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[18] => DY[18]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[17] => DY[17]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[16] => DY[16]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[15] => DY[15]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[14] => DY[14]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[13] => DY[13]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[12] => DY[12]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[11] => DY[11]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[10] => DY[10]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[9] => DY[9]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[8] => DY[8]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[7] => DY[7]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[6] => DY[6]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[5] => DY[5]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[4] => DY[4]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[3] => DY[3]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[2] => DY[2]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[1] => DY[1]) = (1.000, 1.000);
    if (TEN == 1'b0)
       (TD[0] => DY[0]) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b1) || (TEN == 1'b0 && TWEN == 1'b1)))
       (negedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b0 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[63] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[62] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[61] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[60] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[59] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[58] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[57] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[56] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[55] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[54] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[53] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[52] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[51] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[50] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[49] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[48] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[47] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[46] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[45] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[44] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[43] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[42] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[41] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[40] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[39] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[38] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[37] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[36] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[35] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[34] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[33] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[32] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[31] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[30] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[29] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[28] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[27] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[26] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[25] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[24] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[23] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[22] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[21] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[20] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[19] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[18] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[17] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[16] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[15] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[14] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[13] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[12] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[11] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[10] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[9] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[8] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[7] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[6] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[5] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[4] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[3] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[2] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[1] : 1'b0)) = (1.000, 1.000);
    if (RET1N == 1'b1 && BEN == 1'b1 && STOV == 1'b1 && ((TEN == 1'b1 && WEN == 1'b0) || (TEN == 1'b0 && TWEN == 1'b0)))
       (posedge CLK => (Q[0] : 1'b0)) = (1.000, 1.000);
    if (TQ[63] == 1'b1)
       (BEN => Q[63]) = (1.000, 1.000);
    if (TQ[63] == 1'b0)
       (BEN => Q[63]) = (1.000, 1.000);
    if (TQ[62] == 1'b1)
       (BEN => Q[62]) = (1.000, 1.000);
    if (TQ[62] == 1'b0)
       (BEN => Q[62]) = (1.000, 1.000);
    if (TQ[61] == 1'b1)
       (BEN => Q[61]) = (1.000, 1.000);
    if (TQ[61] == 1'b0)
       (BEN => Q[61]) = (1.000, 1.000);
    if (TQ[60] == 1'b1)
       (BEN => Q[60]) = (1.000, 1.000);
    if (TQ[60] == 1'b0)
       (BEN => Q[60]) = (1.000, 1.000);
    if (TQ[59] == 1'b1)
       (BEN => Q[59]) = (1.000, 1.000);
    if (TQ[59] == 1'b0)
       (BEN => Q[59]) = (1.000, 1.000);
    if (TQ[58] == 1'b1)
       (BEN => Q[58]) = (1.000, 1.000);
    if (TQ[58] == 1'b0)
       (BEN => Q[58]) = (1.000, 1.000);
    if (TQ[57] == 1'b1)
       (BEN => Q[57]) = (1.000, 1.000);
    if (TQ[57] == 1'b0)
       (BEN => Q[57]) = (1.000, 1.000);
    if (TQ[56] == 1'b1)
       (BEN => Q[56]) = (1.000, 1.000);
    if (TQ[56] == 1'b0)
       (BEN => Q[56]) = (1.000, 1.000);
    if (TQ[55] == 1'b1)
       (BEN => Q[55]) = (1.000, 1.000);
    if (TQ[55] == 1'b0)
       (BEN => Q[55]) = (1.000, 1.000);
    if (TQ[54] == 1'b1)
       (BEN => Q[54]) = (1.000, 1.000);
    if (TQ[54] == 1'b0)
       (BEN => Q[54]) = (1.000, 1.000);
    if (TQ[53] == 1'b1)
       (BEN => Q[53]) = (1.000, 1.000);
    if (TQ[53] == 1'b0)
       (BEN => Q[53]) = (1.000, 1.000);
    if (TQ[52] == 1'b1)
       (BEN => Q[52]) = (1.000, 1.000);
    if (TQ[52] == 1'b0)
       (BEN => Q[52]) = (1.000, 1.000);
    if (TQ[51] == 1'b1)
       (BEN => Q[51]) = (1.000, 1.000);
    if (TQ[51] == 1'b0)
       (BEN => Q[51]) = (1.000, 1.000);
    if (TQ[50] == 1'b1)
       (BEN => Q[50]) = (1.000, 1.000);
    if (TQ[50] == 1'b0)
       (BEN => Q[50]) = (1.000, 1.000);
    if (TQ[49] == 1'b1)
       (BEN => Q[49]) = (1.000, 1.000);
    if (TQ[49] == 1'b0)
       (BEN => Q[49]) = (1.000, 1.000);
    if (TQ[48] == 1'b1)
       (BEN => Q[48]) = (1.000, 1.000);
    if (TQ[48] == 1'b0)
       (BEN => Q[48]) = (1.000, 1.000);
    if (TQ[47] == 1'b1)
       (BEN => Q[47]) = (1.000, 1.000);
    if (TQ[47] == 1'b0)
       (BEN => Q[47]) = (1.000, 1.000);
    if (TQ[46] == 1'b1)
       (BEN => Q[46]) = (1.000, 1.000);
    if (TQ[46] == 1'b0)
       (BEN => Q[46]) = (1.000, 1.000);
    if (TQ[45] == 1'b1)
       (BEN => Q[45]) = (1.000, 1.000);
    if (TQ[45] == 1'b0)
       (BEN => Q[45]) = (1.000, 1.000);
    if (TQ[44] == 1'b1)
       (BEN => Q[44]) = (1.000, 1.000);
    if (TQ[44] == 1'b0)
       (BEN => Q[44]) = (1.000, 1.000);
    if (TQ[43] == 1'b1)
       (BEN => Q[43]) = (1.000, 1.000);
    if (TQ[43] == 1'b0)
       (BEN => Q[43]) = (1.000, 1.000);
    if (TQ[42] == 1'b1)
       (BEN => Q[42]) = (1.000, 1.000);
    if (TQ[42] == 1'b0)
       (BEN => Q[42]) = (1.000, 1.000);
    if (TQ[41] == 1'b1)
       (BEN => Q[41]) = (1.000, 1.000);
    if (TQ[41] == 1'b0)
       (BEN => Q[41]) = (1.000, 1.000);
    if (TQ[40] == 1'b1)
       (BEN => Q[40]) = (1.000, 1.000);
    if (TQ[40] == 1'b0)
       (BEN => Q[40]) = (1.000, 1.000);
    if (TQ[39] == 1'b1)
       (BEN => Q[39]) = (1.000, 1.000);
    if (TQ[39] == 1'b0)
       (BEN => Q[39]) = (1.000, 1.000);
    if (TQ[38] == 1'b1)
       (BEN => Q[38]) = (1.000, 1.000);
    if (TQ[38] == 1'b0)
       (BEN => Q[38]) = (1.000, 1.000);
    if (TQ[37] == 1'b1)
       (BEN => Q[37]) = (1.000, 1.000);
    if (TQ[37] == 1'b0)
       (BEN => Q[37]) = (1.000, 1.000);
    if (TQ[36] == 1'b1)
       (BEN => Q[36]) = (1.000, 1.000);
    if (TQ[36] == 1'b0)
       (BEN => Q[36]) = (1.000, 1.000);
    if (TQ[35] == 1'b1)
       (BEN => Q[35]) = (1.000, 1.000);
    if (TQ[35] == 1'b0)
       (BEN => Q[35]) = (1.000, 1.000);
    if (TQ[34] == 1'b1)
       (BEN => Q[34]) = (1.000, 1.000);
    if (TQ[34] == 1'b0)
       (BEN => Q[34]) = (1.000, 1.000);
    if (TQ[33] == 1'b1)
       (BEN => Q[33]) = (1.000, 1.000);
    if (TQ[33] == 1'b0)
       (BEN => Q[33]) = (1.000, 1.000);
    if (TQ[32] == 1'b1)
       (BEN => Q[32]) = (1.000, 1.000);
    if (TQ[32] == 1'b0)
       (BEN => Q[32]) = (1.000, 1.000);
    if (TQ[31] == 1'b1)
       (BEN => Q[31]) = (1.000, 1.000);
    if (TQ[31] == 1'b0)
       (BEN => Q[31]) = (1.000, 1.000);
    if (TQ[30] == 1'b1)
       (BEN => Q[30]) = (1.000, 1.000);
    if (TQ[30] == 1'b0)
       (BEN => Q[30]) = (1.000, 1.000);
    if (TQ[29] == 1'b1)
       (BEN => Q[29]) = (1.000, 1.000);
    if (TQ[29] == 1'b0)
       (BEN => Q[29]) = (1.000, 1.000);
    if (TQ[28] == 1'b1)
       (BEN => Q[28]) = (1.000, 1.000);
    if (TQ[28] == 1'b0)
       (BEN => Q[28]) = (1.000, 1.000);
    if (TQ[27] == 1'b1)
       (BEN => Q[27]) = (1.000, 1.000);
    if (TQ[27] == 1'b0)
       (BEN => Q[27]) = (1.000, 1.000);
    if (TQ[26] == 1'b1)
       (BEN => Q[26]) = (1.000, 1.000);
    if (TQ[26] == 1'b0)
       (BEN => Q[26]) = (1.000, 1.000);
    if (TQ[25] == 1'b1)
       (BEN => Q[25]) = (1.000, 1.000);
    if (TQ[25] == 1'b0)
       (BEN => Q[25]) = (1.000, 1.000);
    if (TQ[24] == 1'b1)
       (BEN => Q[24]) = (1.000, 1.000);
    if (TQ[24] == 1'b0)
       (BEN => Q[24]) = (1.000, 1.000);
    if (TQ[23] == 1'b1)
       (BEN => Q[23]) = (1.000, 1.000);
    if (TQ[23] == 1'b0)
       (BEN => Q[23]) = (1.000, 1.000);
    if (TQ[22] == 1'b1)
       (BEN => Q[22]) = (1.000, 1.000);
    if (TQ[22] == 1'b0)
       (BEN => Q[22]) = (1.000, 1.000);
    if (TQ[21] == 1'b1)
       (BEN => Q[21]) = (1.000, 1.000);
    if (TQ[21] == 1'b0)
       (BEN => Q[21]) = (1.000, 1.000);
    if (TQ[20] == 1'b1)
       (BEN => Q[20]) = (1.000, 1.000);
    if (TQ[20] == 1'b0)
       (BEN => Q[20]) = (1.000, 1.000);
    if (TQ[19] == 1'b1)
       (BEN => Q[19]) = (1.000, 1.000);
    if (TQ[19] == 1'b0)
       (BEN => Q[19]) = (1.000, 1.000);
    if (TQ[18] == 1'b1)
       (BEN => Q[18]) = (1.000, 1.000);
    if (TQ[18] == 1'b0)
       (BEN => Q[18]) = (1.000, 1.000);
    if (TQ[17] == 1'b1)
       (BEN => Q[17]) = (1.000, 1.000);
    if (TQ[17] == 1'b0)
       (BEN => Q[17]) = (1.000, 1.000);
    if (TQ[16] == 1'b1)
       (BEN => Q[16]) = (1.000, 1.000);
    if (TQ[16] == 1'b0)
       (BEN => Q[16]) = (1.000, 1.000);
    if (TQ[15] == 1'b1)
       (BEN => Q[15]) = (1.000, 1.000);
    if (TQ[15] == 1'b0)
       (BEN => Q[15]) = (1.000, 1.000);
    if (TQ[14] == 1'b1)
       (BEN => Q[14]) = (1.000, 1.000);
    if (TQ[14] == 1'b0)
       (BEN => Q[14]) = (1.000, 1.000);
    if (TQ[13] == 1'b1)
       (BEN => Q[13]) = (1.000, 1.000);
    if (TQ[13] == 1'b0)
       (BEN => Q[13]) = (1.000, 1.000);
    if (TQ[12] == 1'b1)
       (BEN => Q[12]) = (1.000, 1.000);
    if (TQ[12] == 1'b0)
       (BEN => Q[12]) = (1.000, 1.000);
    if (TQ[11] == 1'b1)
       (BEN => Q[11]) = (1.000, 1.000);
    if (TQ[11] == 1'b0)
       (BEN => Q[11]) = (1.000, 1.000);
    if (TQ[10] == 1'b1)
       (BEN => Q[10]) = (1.000, 1.000);
    if (TQ[10] == 1'b0)
       (BEN => Q[10]) = (1.000, 1.000);
    if (TQ[9] == 1'b1)
       (BEN => Q[9]) = (1.000, 1.000);
    if (TQ[9] == 1'b0)
       (BEN => Q[9]) = (1.000, 1.000);
    if (TQ[8] == 1'b1)
       (BEN => Q[8]) = (1.000, 1.000);
    if (TQ[8] == 1'b0)
       (BEN => Q[8]) = (1.000, 1.000);
    if (TQ[7] == 1'b1)
       (BEN => Q[7]) = (1.000, 1.000);
    if (TQ[7] == 1'b0)
       (BEN => Q[7]) = (1.000, 1.000);
    if (TQ[6] == 1'b1)
       (BEN => Q[6]) = (1.000, 1.000);
    if (TQ[6] == 1'b0)
       (BEN => Q[6]) = (1.000, 1.000);
    if (TQ[5] == 1'b1)
       (BEN => Q[5]) = (1.000, 1.000);
    if (TQ[5] == 1'b0)
       (BEN => Q[5]) = (1.000, 1.000);
    if (TQ[4] == 1'b1)
       (BEN => Q[4]) = (1.000, 1.000);
    if (TQ[4] == 1'b0)
       (BEN => Q[4]) = (1.000, 1.000);
    if (TQ[3] == 1'b1)
       (BEN => Q[3]) = (1.000, 1.000);
    if (TQ[3] == 1'b0)
       (BEN => Q[3]) = (1.000, 1.000);
    if (TQ[2] == 1'b1)
       (BEN => Q[2]) = (1.000, 1.000);
    if (TQ[2] == 1'b0)
       (BEN => Q[2]) = (1.000, 1.000);
    if (TQ[1] == 1'b1)
       (BEN => Q[1]) = (1.000, 1.000);
    if (TQ[1] == 1'b0)
       (BEN => Q[1]) = (1.000, 1.000);
    if (TQ[0] == 1'b1)
       (BEN => Q[0]) = (1.000, 1.000);
    if (TQ[0] == 1'b0)
       (BEN => Q[0]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[63] => Q[63]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[62] => Q[62]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[61] => Q[61]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[60] => Q[60]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[59] => Q[59]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[58] => Q[58]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[57] => Q[57]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[56] => Q[56]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[55] => Q[55]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[54] => Q[54]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[53] => Q[53]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[52] => Q[52]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[51] => Q[51]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[50] => Q[50]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[49] => Q[49]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[48] => Q[48]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[47] => Q[47]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[46] => Q[46]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[45] => Q[45]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[44] => Q[44]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[43] => Q[43]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[42] => Q[42]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[41] => Q[41]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[40] => Q[40]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[39] => Q[39]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[38] => Q[38]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[37] => Q[37]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[36] => Q[36]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[35] => Q[35]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[34] => Q[34]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[33] => Q[33]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[32] => Q[32]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[31] => Q[31]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[30] => Q[30]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[29] => Q[29]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[28] => Q[28]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[27] => Q[27]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[26] => Q[26]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[25] => Q[25]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[24] => Q[24]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[23] => Q[23]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[22] => Q[22]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[21] => Q[21]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[20] => Q[20]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[19] => Q[19]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[18] => Q[18]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[17] => Q[17]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[16] => Q[16]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[15] => Q[15]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[14] => Q[14]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[13] => Q[13]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[12] => Q[12]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[11] => Q[11]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[10] => Q[10]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[9] => Q[9]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[8] => Q[8]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[7] => Q[7]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[6] => Q[6]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[5] => Q[5]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[4] => Q[4]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[3] => Q[3]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[2] => Q[2]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[1] => Q[1]) = (1.000, 1.000);
    if (BEN == 1'b0)
       (TQ[0] => Q[0]) = (1.000, 1.000);

// Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $period(posedge CLK, 3.000, NOT_CLK_PER);
   `else
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(negedge CLK &&& STOVeq1andEMASeq0andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(negedge CLK &&& STOVeq1andEMASeq1andopopTENeq1andWENeq1cporopTENeq0andTWENeq1cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq0andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq0andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq0andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq0andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq0andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq0andEMA2eq1andEMA1eq1andEMA0eq1andEMAW1eq1andEMAW0eq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
       $period(posedge CLK &&& STOVeq1andopopTENeq1andWENeq0cporopTENeq0andTWENeq0cpcp, 3.000, NOT_CLK_PER);
   `endif

// Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $width(posedge CLK, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK, 1.000, 0, NOT_CLK_MINL);
   `else
       $width(posedge CLK &&& STOVeq0, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& STOVeq0, 1.000, 0, NOT_CLK_MINL);
       $width(posedge CLK &&& STOVeq1andEMASeq0, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& STOVeq1andEMASeq0, 1.000, 0, NOT_CLK_MINL);
       $width(posedge CLK &&& STOVeq1andEMASeq1, 1.000, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& STOVeq1andEMASeq1, 1.000, 0, NOT_CLK_MINL);
   `endif

    $setuphold(posedge CLK &&& TENeq1, posedge CEN, 1.000, 0.500, NOT_CEN);
    $setuphold(posedge CLK &&& TENeq1, negedge CEN, 1.000, 0.500, NOT_CEN);
    $setuphold(posedge RET1N &&& TENeq1, negedge CEN, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge WEN, 1.000, 0.500, NOT_WEN);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge WEN, 1.000, 0.500, NOT_WEN);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[8], 1.000, 0.500, NOT_A8);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[7], 1.000, 0.500, NOT_A7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[6], 1.000, 0.500, NOT_A6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[5], 1.000, 0.500, NOT_A5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[4], 1.000, 0.500, NOT_A4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[3], 1.000, 0.500, NOT_A3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[2], 1.000, 0.500, NOT_A2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[1], 1.000, 0.500, NOT_A1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, posedge A[0], 1.000, 0.500, NOT_A0);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[8], 1.000, 0.500, NOT_A8);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[7], 1.000, 0.500, NOT_A7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[6], 1.000, 0.500, NOT_A6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[5], 1.000, 0.500, NOT_A5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[4], 1.000, 0.500, NOT_A4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[3], 1.000, 0.500, NOT_A3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[2], 1.000, 0.500, NOT_A2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[1], 1.000, 0.500, NOT_A1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0, negedge A[0], 1.000, 0.500, NOT_A0);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[63], 1.000, 0.500, NOT_D63);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[62], 1.000, 0.500, NOT_D62);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[61], 1.000, 0.500, NOT_D61);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[60], 1.000, 0.500, NOT_D60);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[59], 1.000, 0.500, NOT_D59);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[58], 1.000, 0.500, NOT_D58);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[57], 1.000, 0.500, NOT_D57);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[56], 1.000, 0.500, NOT_D56);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[55], 1.000, 0.500, NOT_D55);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[54], 1.000, 0.500, NOT_D54);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[53], 1.000, 0.500, NOT_D53);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[52], 1.000, 0.500, NOT_D52);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[51], 1.000, 0.500, NOT_D51);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[50], 1.000, 0.500, NOT_D50);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[49], 1.000, 0.500, NOT_D49);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[48], 1.000, 0.500, NOT_D48);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[47], 1.000, 0.500, NOT_D47);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[46], 1.000, 0.500, NOT_D46);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[45], 1.000, 0.500, NOT_D45);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[44], 1.000, 0.500, NOT_D44);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[43], 1.000, 0.500, NOT_D43);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[42], 1.000, 0.500, NOT_D42);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[41], 1.000, 0.500, NOT_D41);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[40], 1.000, 0.500, NOT_D40);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[39], 1.000, 0.500, NOT_D39);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[38], 1.000, 0.500, NOT_D38);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[37], 1.000, 0.500, NOT_D37);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[36], 1.000, 0.500, NOT_D36);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[35], 1.000, 0.500, NOT_D35);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[34], 1.000, 0.500, NOT_D34);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[33], 1.000, 0.500, NOT_D33);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[32], 1.000, 0.500, NOT_D32);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[31], 1.000, 0.500, NOT_D31);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[30], 1.000, 0.500, NOT_D30);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[29], 1.000, 0.500, NOT_D29);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[28], 1.000, 0.500, NOT_D28);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[27], 1.000, 0.500, NOT_D27);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[26], 1.000, 0.500, NOT_D26);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[25], 1.000, 0.500, NOT_D25);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[24], 1.000, 0.500, NOT_D24);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[23], 1.000, 0.500, NOT_D23);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[22], 1.000, 0.500, NOT_D22);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[21], 1.000, 0.500, NOT_D21);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[20], 1.000, 0.500, NOT_D20);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[19], 1.000, 0.500, NOT_D19);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[18], 1.000, 0.500, NOT_D18);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[17], 1.000, 0.500, NOT_D17);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[16], 1.000, 0.500, NOT_D16);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[15], 1.000, 0.500, NOT_D15);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[14], 1.000, 0.500, NOT_D14);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[13], 1.000, 0.500, NOT_D13);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[12], 1.000, 0.500, NOT_D12);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[11], 1.000, 0.500, NOT_D11);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[10], 1.000, 0.500, NOT_D10);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[9], 1.000, 0.500, NOT_D9);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[8], 1.000, 0.500, NOT_D8);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[7], 1.000, 0.500, NOT_D7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[6], 1.000, 0.500, NOT_D6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[5], 1.000, 0.500, NOT_D5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[4], 1.000, 0.500, NOT_D4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[3], 1.000, 0.500, NOT_D3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[2], 1.000, 0.500, NOT_D2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[1], 1.000, 0.500, NOT_D1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, posedge D[0], 1.000, 0.500, NOT_D0);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[63], 1.000, 0.500, NOT_D63);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[62], 1.000, 0.500, NOT_D62);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[61], 1.000, 0.500, NOT_D61);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[60], 1.000, 0.500, NOT_D60);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[59], 1.000, 0.500, NOT_D59);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[58], 1.000, 0.500, NOT_D58);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[57], 1.000, 0.500, NOT_D57);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[56], 1.000, 0.500, NOT_D56);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[55], 1.000, 0.500, NOT_D55);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[54], 1.000, 0.500, NOT_D54);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[53], 1.000, 0.500, NOT_D53);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[52], 1.000, 0.500, NOT_D52);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[51], 1.000, 0.500, NOT_D51);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[50], 1.000, 0.500, NOT_D50);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[49], 1.000, 0.500, NOT_D49);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[48], 1.000, 0.500, NOT_D48);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[47], 1.000, 0.500, NOT_D47);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[46], 1.000, 0.500, NOT_D46);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[45], 1.000, 0.500, NOT_D45);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[44], 1.000, 0.500, NOT_D44);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[43], 1.000, 0.500, NOT_D43);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[42], 1.000, 0.500, NOT_D42);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[41], 1.000, 0.500, NOT_D41);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[40], 1.000, 0.500, NOT_D40);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[39], 1.000, 0.500, NOT_D39);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[38], 1.000, 0.500, NOT_D38);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[37], 1.000, 0.500, NOT_D37);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[36], 1.000, 0.500, NOT_D36);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[35], 1.000, 0.500, NOT_D35);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[34], 1.000, 0.500, NOT_D34);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[33], 1.000, 0.500, NOT_D33);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[32], 1.000, 0.500, NOT_D32);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[31], 1.000, 0.500, NOT_D31);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[30], 1.000, 0.500, NOT_D30);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[29], 1.000, 0.500, NOT_D29);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[28], 1.000, 0.500, NOT_D28);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[27], 1.000, 0.500, NOT_D27);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[26], 1.000, 0.500, NOT_D26);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[25], 1.000, 0.500, NOT_D25);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[24], 1.000, 0.500, NOT_D24);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[23], 1.000, 0.500, NOT_D23);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[22], 1.000, 0.500, NOT_D22);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[21], 1.000, 0.500, NOT_D21);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[20], 1.000, 0.500, NOT_D20);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[19], 1.000, 0.500, NOT_D19);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[18], 1.000, 0.500, NOT_D18);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[17], 1.000, 0.500, NOT_D17);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[16], 1.000, 0.500, NOT_D16);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[15], 1.000, 0.500, NOT_D15);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[14], 1.000, 0.500, NOT_D14);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[13], 1.000, 0.500, NOT_D13);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[12], 1.000, 0.500, NOT_D12);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[11], 1.000, 0.500, NOT_D11);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[10], 1.000, 0.500, NOT_D10);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[9], 1.000, 0.500, NOT_D9);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[8], 1.000, 0.500, NOT_D8);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[7], 1.000, 0.500, NOT_D7);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[6], 1.000, 0.500, NOT_D6);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[5], 1.000, 0.500, NOT_D5);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[4], 1.000, 0.500, NOT_D4);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[3], 1.000, 0.500, NOT_D3);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[2], 1.000, 0.500, NOT_D2);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[1], 1.000, 0.500, NOT_D1);
    $setuphold(posedge CLK &&& TENeq1andCENeq0andWENeq0, negedge D[0], 1.000, 0.500, NOT_D0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMA[2], 1.000, 0.500, NOT_EMA2);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMA[1], 1.000, 0.500, NOT_EMA1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMA[0], 1.000, 0.500, NOT_EMA0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMA[2], 1.000, 0.500, NOT_EMA2);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMA[1], 1.000, 0.500, NOT_EMA1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMA[0], 1.000, 0.500, NOT_EMA0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMAW[1], 1.000, 0.500, NOT_EMAW1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMAW[0], 1.000, 0.500, NOT_EMAW0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMAW[1], 1.000, 0.500, NOT_EMAW1);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMAW[0], 1.000, 0.500, NOT_EMAW0);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge EMAS, 1.000, 0.500, NOT_EMAS);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge EMAS, 1.000, 0.500, NOT_EMAS);
    $setuphold(posedge CLK, posedge TEN, 1.000, 0.500, NOT_TEN);
    $setuphold(posedge CLK, negedge TEN, 1.000, 0.500, NOT_TEN);
    $setuphold(posedge CLK &&& TENeq0, posedge TCEN, 1.000, 0.500, NOT_TCEN);
    $setuphold(posedge CLK &&& TENeq0, negedge TCEN, 1.000, 0.500, NOT_TCEN);
    $setuphold(posedge RET1N &&& TENeq0, negedge TCEN, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TWEN, 1.000, 0.500, NOT_TWEN);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TWEN, 1.000, 0.500, NOT_TWEN);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[8], 1.000, 0.500, NOT_TA8);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[7], 1.000, 0.500, NOT_TA7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[6], 1.000, 0.500, NOT_TA6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[5], 1.000, 0.500, NOT_TA5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[4], 1.000, 0.500, NOT_TA4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[3], 1.000, 0.500, NOT_TA3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[2], 1.000, 0.500, NOT_TA2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[1], 1.000, 0.500, NOT_TA1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, posedge TA[0], 1.000, 0.500, NOT_TA0);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[8], 1.000, 0.500, NOT_TA8);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[7], 1.000, 0.500, NOT_TA7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[6], 1.000, 0.500, NOT_TA6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[5], 1.000, 0.500, NOT_TA5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[4], 1.000, 0.500, NOT_TA4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[3], 1.000, 0.500, NOT_TA3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[2], 1.000, 0.500, NOT_TA2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[1], 1.000, 0.500, NOT_TA1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0, negedge TA[0], 1.000, 0.500, NOT_TA0);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[63], 1.000, 0.500, NOT_TD63);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[62], 1.000, 0.500, NOT_TD62);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[61], 1.000, 0.500, NOT_TD61);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[60], 1.000, 0.500, NOT_TD60);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[59], 1.000, 0.500, NOT_TD59);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[58], 1.000, 0.500, NOT_TD58);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[57], 1.000, 0.500, NOT_TD57);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[56], 1.000, 0.500, NOT_TD56);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[55], 1.000, 0.500, NOT_TD55);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[54], 1.000, 0.500, NOT_TD54);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[53], 1.000, 0.500, NOT_TD53);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[52], 1.000, 0.500, NOT_TD52);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[51], 1.000, 0.500, NOT_TD51);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[50], 1.000, 0.500, NOT_TD50);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[49], 1.000, 0.500, NOT_TD49);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[48], 1.000, 0.500, NOT_TD48);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[47], 1.000, 0.500, NOT_TD47);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[46], 1.000, 0.500, NOT_TD46);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[45], 1.000, 0.500, NOT_TD45);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[44], 1.000, 0.500, NOT_TD44);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[43], 1.000, 0.500, NOT_TD43);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[42], 1.000, 0.500, NOT_TD42);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[41], 1.000, 0.500, NOT_TD41);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[40], 1.000, 0.500, NOT_TD40);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[39], 1.000, 0.500, NOT_TD39);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[38], 1.000, 0.500, NOT_TD38);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[37], 1.000, 0.500, NOT_TD37);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[36], 1.000, 0.500, NOT_TD36);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[35], 1.000, 0.500, NOT_TD35);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[34], 1.000, 0.500, NOT_TD34);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[33], 1.000, 0.500, NOT_TD33);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[32], 1.000, 0.500, NOT_TD32);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[31], 1.000, 0.500, NOT_TD31);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[30], 1.000, 0.500, NOT_TD30);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[29], 1.000, 0.500, NOT_TD29);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[28], 1.000, 0.500, NOT_TD28);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[27], 1.000, 0.500, NOT_TD27);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[26], 1.000, 0.500, NOT_TD26);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[25], 1.000, 0.500, NOT_TD25);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[24], 1.000, 0.500, NOT_TD24);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[23], 1.000, 0.500, NOT_TD23);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[22], 1.000, 0.500, NOT_TD22);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[21], 1.000, 0.500, NOT_TD21);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[20], 1.000, 0.500, NOT_TD20);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[19], 1.000, 0.500, NOT_TD19);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[18], 1.000, 0.500, NOT_TD18);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[17], 1.000, 0.500, NOT_TD17);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[16], 1.000, 0.500, NOT_TD16);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[15], 1.000, 0.500, NOT_TD15);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[14], 1.000, 0.500, NOT_TD14);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[13], 1.000, 0.500, NOT_TD13);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[12], 1.000, 0.500, NOT_TD12);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[11], 1.000, 0.500, NOT_TD11);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[10], 1.000, 0.500, NOT_TD10);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[9], 1.000, 0.500, NOT_TD9);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[8], 1.000, 0.500, NOT_TD8);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[7], 1.000, 0.500, NOT_TD7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[6], 1.000, 0.500, NOT_TD6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[5], 1.000, 0.500, NOT_TD5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[4], 1.000, 0.500, NOT_TD4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[3], 1.000, 0.500, NOT_TD3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[2], 1.000, 0.500, NOT_TD2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[1], 1.000, 0.500, NOT_TD1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, posedge TD[0], 1.000, 0.500, NOT_TD0);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[63], 1.000, 0.500, NOT_TD63);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[62], 1.000, 0.500, NOT_TD62);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[61], 1.000, 0.500, NOT_TD61);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[60], 1.000, 0.500, NOT_TD60);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[59], 1.000, 0.500, NOT_TD59);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[58], 1.000, 0.500, NOT_TD58);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[57], 1.000, 0.500, NOT_TD57);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[56], 1.000, 0.500, NOT_TD56);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[55], 1.000, 0.500, NOT_TD55);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[54], 1.000, 0.500, NOT_TD54);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[53], 1.000, 0.500, NOT_TD53);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[52], 1.000, 0.500, NOT_TD52);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[51], 1.000, 0.500, NOT_TD51);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[50], 1.000, 0.500, NOT_TD50);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[49], 1.000, 0.500, NOT_TD49);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[48], 1.000, 0.500, NOT_TD48);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[47], 1.000, 0.500, NOT_TD47);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[46], 1.000, 0.500, NOT_TD46);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[45], 1.000, 0.500, NOT_TD45);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[44], 1.000, 0.500, NOT_TD44);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[43], 1.000, 0.500, NOT_TD43);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[42], 1.000, 0.500, NOT_TD42);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[41], 1.000, 0.500, NOT_TD41);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[40], 1.000, 0.500, NOT_TD40);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[39], 1.000, 0.500, NOT_TD39);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[38], 1.000, 0.500, NOT_TD38);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[37], 1.000, 0.500, NOT_TD37);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[36], 1.000, 0.500, NOT_TD36);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[35], 1.000, 0.500, NOT_TD35);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[34], 1.000, 0.500, NOT_TD34);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[33], 1.000, 0.500, NOT_TD33);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[32], 1.000, 0.500, NOT_TD32);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[31], 1.000, 0.500, NOT_TD31);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[30], 1.000, 0.500, NOT_TD30);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[29], 1.000, 0.500, NOT_TD29);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[28], 1.000, 0.500, NOT_TD28);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[27], 1.000, 0.500, NOT_TD27);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[26], 1.000, 0.500, NOT_TD26);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[25], 1.000, 0.500, NOT_TD25);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[24], 1.000, 0.500, NOT_TD24);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[23], 1.000, 0.500, NOT_TD23);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[22], 1.000, 0.500, NOT_TD22);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[21], 1.000, 0.500, NOT_TD21);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[20], 1.000, 0.500, NOT_TD20);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[19], 1.000, 0.500, NOT_TD19);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[18], 1.000, 0.500, NOT_TD18);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[17], 1.000, 0.500, NOT_TD17);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[16], 1.000, 0.500, NOT_TD16);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[15], 1.000, 0.500, NOT_TD15);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[14], 1.000, 0.500, NOT_TD14);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[13], 1.000, 0.500, NOT_TD13);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[12], 1.000, 0.500, NOT_TD12);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[11], 1.000, 0.500, NOT_TD11);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[10], 1.000, 0.500, NOT_TD10);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[9], 1.000, 0.500, NOT_TD9);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[8], 1.000, 0.500, NOT_TD8);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[7], 1.000, 0.500, NOT_TD7);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[6], 1.000, 0.500, NOT_TD6);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[5], 1.000, 0.500, NOT_TD5);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[4], 1.000, 0.500, NOT_TD4);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[3], 1.000, 0.500, NOT_TD3);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[2], 1.000, 0.500, NOT_TD2);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[1], 1.000, 0.500, NOT_TD1);
    $setuphold(posedge CLK &&& TENeq0andTCENeq0andTWENeq0, negedge TD[0], 1.000, 0.500, NOT_TD0);
    $setuphold(posedge CLK &&& opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp, posedge RET1N, 1.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& opopTENeq1andCENeq0cporopTENeq0andTCENeq0cpcp, negedge RET1N, 1.000, 0.500, NOT_RET1N);
    $setuphold(posedge CEN &&& TENeq1, negedge RET1N, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge TCEN &&& TENeq0, negedge RET1N, 0.000, 0.500, NOT_RET1N);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, posedge STOV, 1.000, 0.500, NOT_STOV);
    $setuphold(posedge CLK &&& opTENeq1andCENeq0cporopTENeq0andTCENeq0cp, negedge STOV, 1.000, 0.500, NOT_STOV);
  endspecify


endmodule
`endcelldefine
`endif
`timescale 1ns/1ps
module sram_sp_512x64_error_injection (Q_out, Q_in, CLK, A, CEN, WEN, BEN, TQ);
   output [63:0] Q_out;
   input [63:0] Q_in;
   input CLK;
   input [8:0] A;
   input CEN;
   input WEN;
   input BEN;
   input [63:0] TQ;
   parameter LEFT_RED_COLUMN_FAULT = 2'd1;
   parameter RIGHT_RED_COLUMN_FAULT = 2'd2;
   parameter NO_RED_FAULT = 2'd0;
   reg [63:0] Q_out;
   reg entry_found;
   reg list_complete;
   reg [19:0] fault_table [31:0];
   reg [19:0] fault_entry;
initial
begin
   `ifdef DUT
      `define pre_pend_path TB.DUT_inst.CHIP
   `else
       `define pre_pend_path TB.CHIP
   `endif
   `ifdef ARM_NONREPAIRABLE_FAULT
      `pre_pend_path.SMARCHCHKBVCD_LVISION_MBISTPG_ASSEMBLY_UNDER_TEST_INST.MEM0_MEM_INST.u1.add_fault(9'd505,6'd6,2'd1,2'd0);
   `endif
end
   task add_fault;
   //This task injects fault in memory
   //In order to inject fault in redundant column for Bit 0 to 31, column address
   //should have value in range of 12 to 15
   //In order to inject fault in redundant column for Bit 32 to 63, column address
   //should have value in range of 0 to 3
      input [8:0] address;
      input [5:0] bitPlace;
      input [1:0] fault_type;
      input [1:0] red_fault;
 
      integer i;
      reg done;
   begin
      done = 1'b0;
      i = 0;
      while ((!done) && i < 31)
      begin
         fault_entry = fault_table[i];
         if (fault_entry[0] === 1'b0 || fault_entry[0] === 1'bx)
         begin
            fault_entry[0] = 1'b1;
            fault_entry[2:1] = red_fault;
            fault_entry[4:3] = fault_type;
            fault_entry[10:5] = bitPlace;
            fault_entry[19:11] = address;
            fault_table[i] = fault_entry;
            done = 1'b1;
         end
         i = i+1;
      end
   end
   endtask
//This task removes all fault entries injected by user
task remove_all_faults;
   integer i;
begin
   for (i = 0; i < 32; i=i+1)
   begin
      fault_entry = fault_table[i];
      fault_entry[0] = 1'b0;
      fault_table[i] = fault_entry;
   end
end
endtask
task bit_error;
// This task is used to inject error in memory and should be called
// only from current module.
//
// This task injects error depending upon fault type to particular bit
// of the output
   inout [63:0] q_int;
   input [1:0] fault_type;
   input [5:0] bitLoc;
begin
   if (fault_type === 2'd0)
      q_int[bitLoc] = 1'b0;
   else if (fault_type === 2'd1)
      q_int[bitLoc] = 1'b1;
   else
      q_int[bitLoc] = ~q_int[bitLoc];
end
endtask
task error_injection_on_output;
// This function goes through error injection table for every
// read cycle and corrupts Q output if fault for the particular
// address is present in fault table
//
// If fault is redundant column is detected, this task corrupts
// Q output in read cycle
//
// If fault is repaired using repair bus, this task does not
// courrpt Q output in read cycle
//
   output [63:0] Q_output;
   reg list_complete;
   integer i;
   reg [4:0] row_address;
   reg [3:0] column_address;
   reg [5:0] bitPlace;
   reg [1:0] fault_type;
   reg [1:0] red_fault;
   reg valid;
begin
   entry_found = 1'b0;
   list_complete = 1'b0;
   i = 0;
   Q_output = Q_in;
   while(!list_complete)
   begin
      fault_entry = fault_table[i];
      {row_address, column_address, bitPlace, fault_type, red_fault, valid} = fault_entry;
      i = i + 1;
      if (valid == 1'b1)
      begin
         if (red_fault === NO_RED_FAULT)
         begin
            if (row_address == A[8:4] && column_address == A[3:0])
            begin
               if (bitPlace < 32)
                  bit_error(Q_output,fault_type, bitPlace);
               else if (bitPlace >= 32 )
                  bit_error(Q_output,fault_type, bitPlace);
            end
         end
      end
      else
         list_complete = 1'b1;
      end
   end
   endtask
   always @ (Q_in or CLK or A or CEN or WEN or BEN or TQ)
   begin
   if (CEN === 1'b0 && &WEN === 1'b1 && BEN === 1'b1)
      error_injection_on_output(Q_out);
   else if (BEN === 1'b0)
      Q_out = TQ;
   else
      Q_out = Q_in;
   end
endmodule
