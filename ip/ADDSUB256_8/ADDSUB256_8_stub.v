// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
// Date        : Wed Aug  1 15:36:04 2018
// Host        : laurens-ubuntu running 64-bit Ubuntu 16.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/laurens/open-power-snap/actions/posit_dot/posit/ip/ADDSUB256_8/ADDSUB256_8_stub.v
// Design      : ADDSUB256_8
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "c_addsub_v12_0_11,Vivado 2017.4" *)
module ADDSUB256_8(A, B, CLK, ADD, SCLR, S)
/* synthesis syn_black_box black_box_pad_pin="A[255:0],B[255:0],CLK,ADD,SCLR,S[256:0]" */;
  input [255:0]A;
  input [255:0]B;
  input CLK;
  input ADD;
  input SCLR;
  output [256:0]S;
endmodule
