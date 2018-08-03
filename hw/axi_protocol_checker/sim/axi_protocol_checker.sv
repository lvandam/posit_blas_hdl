// (c) Copyright 1995-2018 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:ip:axi_protocol_checker:2.0
// IP Revision: 1

`timescale 1ns/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module axi_protocol_checker (
  pc_status,
  pc_asserted,
  aclk,
  aresetn,
  pc_axi_awaddr,
  pc_axi_awlen,
  pc_axi_awsize,
  pc_axi_awburst,
  pc_axi_awlock,
  pc_axi_awcache,
  pc_axi_awprot,
  pc_axi_awqos,
  pc_axi_awregion,
  pc_axi_awvalid,
  pc_axi_awready,
  pc_axi_wlast,
  pc_axi_wdata,
  pc_axi_wstrb,
  pc_axi_wvalid,
  pc_axi_wready,
  pc_axi_bresp,
  pc_axi_bvalid,
  pc_axi_bready,
  pc_axi_araddr,
  pc_axi_arlen,
  pc_axi_arsize,
  pc_axi_arburst,
  pc_axi_arlock,
  pc_axi_arcache,
  pc_axi_arprot,
  pc_axi_arqos,
  pc_axi_arregion,
  pc_axi_arvalid,
  pc_axi_arready,
  pc_axi_rlast,
  pc_axi_rdata,
  pc_axi_rresp,
  pc_axi_rvalid,
  pc_axi_rready
);

output wire [159 : 0] pc_status;
output wire pc_asserted;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aclk, ASSOCIATED_BUSIF PC_AXI:S_AXI, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000, PHASE 0.000" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
input wire aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
input wire aresetn;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWADDR" *)
input wire [63 : 0] pc_axi_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWLEN" *)
input wire [7 : 0] pc_axi_awlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWSIZE" *)
input wire [2 : 0] pc_axi_awsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWBURST" *)
input wire [1 : 0] pc_axi_awburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWLOCK" *)
input wire [0 : 0] pc_axi_awlock;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWCACHE" *)
input wire [3 : 0] pc_axi_awcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWPROT" *)
input wire [2 : 0] pc_axi_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWQOS" *)
input wire [3 : 0] pc_axi_awqos;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWREGION" *)
input wire [3 : 0] pc_axi_awregion;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWVALID" *)
input wire pc_axi_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI AWREADY" *)
input wire pc_axi_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI WLAST" *)
input wire pc_axi_wlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI WDATA" *)
input wire [511 : 0] pc_axi_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI WSTRB" *)
input wire [63 : 0] pc_axi_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI WVALID" *)
input wire pc_axi_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI WREADY" *)
input wire pc_axi_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI BRESP" *)
input wire [1 : 0] pc_axi_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI BVALID" *)
input wire pc_axi_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI BREADY" *)
input wire pc_axi_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARADDR" *)
input wire [63 : 0] pc_axi_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARLEN" *)
input wire [7 : 0] pc_axi_arlen;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARSIZE" *)
input wire [2 : 0] pc_axi_arsize;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARBURST" *)
input wire [1 : 0] pc_axi_arburst;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARLOCK" *)
input wire [0 : 0] pc_axi_arlock;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARCACHE" *)
input wire [3 : 0] pc_axi_arcache;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARPROT" *)
input wire [2 : 0] pc_axi_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARQOS" *)
input wire [3 : 0] pc_axi_arqos;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARREGION" *)
input wire [3 : 0] pc_axi_arregion;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARVALID" *)
input wire pc_axi_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI ARREADY" *)
input wire pc_axi_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI RLAST" *)
input wire pc_axi_rlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI RDATA" *)
input wire [511 : 0] pc_axi_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI RRESP" *)
input wire [1 : 0] pc_axi_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI RVALID" *)
input wire pc_axi_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME PC_AXI, DATA_WIDTH 512, PROTOCOL AXI4, FREQ_HZ 100000000, ID_WIDTH 0, ADDR_WIDTH 64, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 1, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 1, HAS_REGION 1, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.000, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 PC_AXI RREADY" *)
input wire pc_axi_rready;

  axi_protocol_checker_v2_0_1_top #(
    .C_AXI_PROTOCOL(0),
    .C_AXI_ID_WIDTH(1),
    .C_AXI_DATA_WIDTH(512),
    .C_AXI_ADDR_WIDTH(64),
    .C_AXI_AWUSER_WIDTH(1),
    .C_AXI_ARUSER_WIDTH(1),
    .C_AXI_WUSER_WIDTH(1),
    .C_AXI_RUSER_WIDTH(1),
    .C_AXI_BUSER_WIDTH(1),
    .C_HAS_WSTRB(1),
    .C_PC_MAXRBURSTS(8),
    .C_PC_MAXWBURSTS(8),
    .C_PC_EXMON_WIDTH(0),
    .C_PC_AW_MAXWAITS(0),
    .C_PC_AR_MAXWAITS(0),
    .C_PC_W_MAXWAITS(0),
    .C_PC_R_MAXWAITS(0),
    .C_PC_B_MAXWAITS(0),
    .C_PC_MAX_CONTINUOUS_RTRANSFERS_WAITS(0),
    .C_PC_MAX_CONTINUOUS_WTRANSFERS_WAITS(0),
    .C_PC_MAX_WLAST_TO_AWVALID_WAITS(0),
    .C_PC_MAX_WRITE_TO_BVALID_WAITS(0),
    .C_PC_LIGHT_WEIGHT(0),
    .C_PC_MESSAGE_LEVEL(2),
    .C_PC_SUPPORTS_NARROW_BURST(1),
    .C_PC_MAX_BURST_LENGTH(256),
    .C_PC_HAS_SYSTEM_RESET(0),
    .C_ENABLE_CONTROL(0),
    .C_PC_STATUS_WIDTH(160),
    .C_ENABLE_MARK_DEBUG(1)
  ) inst (
    .pc_status(pc_status),
    .pc_asserted(pc_asserted),
    .system_resetn(1'D1),
    .aclk(aclk),
    .aresetn(aresetn),
    .pc_axi_awid(1'H0),
    .pc_axi_awaddr(pc_axi_awaddr),
    .pc_axi_awlen(pc_axi_awlen),
    .pc_axi_awsize(pc_axi_awsize),
    .pc_axi_awburst(pc_axi_awburst),
    .pc_axi_awlock(pc_axi_awlock),
    .pc_axi_awcache(pc_axi_awcache),
    .pc_axi_awprot(pc_axi_awprot),
    .pc_axi_awqos(pc_axi_awqos),
    .pc_axi_awregion(pc_axi_awregion),
    .pc_axi_awuser(1'H0),
    .pc_axi_awvalid(pc_axi_awvalid),
    .pc_axi_awready(pc_axi_awready),
    .pc_axi_wid(1'H0),
    .pc_axi_wlast(pc_axi_wlast),
    .pc_axi_wdata(pc_axi_wdata),
    .pc_axi_wstrb(pc_axi_wstrb),
    .pc_axi_wuser(1'H0),
    .pc_axi_wvalid(pc_axi_wvalid),
    .pc_axi_wready(pc_axi_wready),
    .pc_axi_bid(1'H0),
    .pc_axi_bresp(pc_axi_bresp),
    .pc_axi_buser(1'H0),
    .pc_axi_bvalid(pc_axi_bvalid),
    .pc_axi_bready(pc_axi_bready),
    .pc_axi_arid(1'H0),
    .pc_axi_araddr(pc_axi_araddr),
    .pc_axi_arlen(pc_axi_arlen),
    .pc_axi_arsize(pc_axi_arsize),
    .pc_axi_arburst(pc_axi_arburst),
    .pc_axi_arlock(pc_axi_arlock),
    .pc_axi_arcache(pc_axi_arcache),
    .pc_axi_arprot(pc_axi_arprot),
    .pc_axi_arqos(pc_axi_arqos),
    .pc_axi_arregion(pc_axi_arregion),
    .pc_axi_aruser(1'H0),
    .pc_axi_arvalid(pc_axi_arvalid),
    .pc_axi_arready(pc_axi_arready),
    .pc_axi_rid(1'H0),
    .pc_axi_rlast(pc_axi_rlast),
    .pc_axi_rdata(pc_axi_rdata),
    .pc_axi_rresp(pc_axi_rresp),
    .pc_axi_ruser(1'H0),
    .pc_axi_rvalid(pc_axi_rvalid),
    .pc_axi_rready(pc_axi_rready),
    .s_axi_araddr(10'D0),
    .s_axi_arvalid(1'D0),
    .s_axi_arready(),
    .s_axi_rdata(),
    .s_axi_rresp(),
    .s_axi_rvalid(),
    .s_axi_rready(1'D0)
  );
endmodule
