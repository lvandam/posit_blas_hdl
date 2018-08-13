// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
// Date        : Tue Aug  7 15:04:26 2018
// Host        : laurens-ubuntu running 64-bit Ubuntu 16.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/laurens/Desktop/project_snap/project_snap.srcs/sources_1/ip/accum_fifo_es2/accum_fifo_es2_stub.v
// Design      : accum_fifo_es2
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_1,Vivado 2017.4" *)
module accum_fifo_es2(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, 
  wr_ack, overflow, empty, valid, underflow, wr_rst_busy, rd_rst_busy)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[158:0],wr_en,rd_en,dout[158:0],full,wr_ack,overflow,empty,valid,underflow,wr_rst_busy,rd_rst_busy" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [158:0]din;
  input wr_en;
  input rd_en;
  output [158:0]dout;
  output full;
  output wr_ack;
  output overflow;
  output empty;
  output valid;
  output underflow;
  output wr_rst_busy;
  output rd_rst_busy;
endmodule
