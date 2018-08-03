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

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
axi_protocol_checker your_instance_name (
  .pc_status(pc_status),              // output wire [159 : 0] pc_status
  .pc_asserted(pc_asserted),          // output wire pc_asserted
  .aclk(aclk),                        // input wire aclk
  .aresetn(aresetn),                  // input wire aresetn
  .pc_axi_awaddr(pc_axi_awaddr),      // input wire [63 : 0] pc_axi_awaddr
  .pc_axi_awlen(pc_axi_awlen),        // input wire [7 : 0] pc_axi_awlen
  .pc_axi_awsize(pc_axi_awsize),      // input wire [2 : 0] pc_axi_awsize
  .pc_axi_awburst(pc_axi_awburst),    // input wire [1 : 0] pc_axi_awburst
  .pc_axi_awlock(pc_axi_awlock),      // input wire [0 : 0] pc_axi_awlock
  .pc_axi_awcache(pc_axi_awcache),    // input wire [3 : 0] pc_axi_awcache
  .pc_axi_awprot(pc_axi_awprot),      // input wire [2 : 0] pc_axi_awprot
  .pc_axi_awqos(pc_axi_awqos),        // input wire [3 : 0] pc_axi_awqos
  .pc_axi_awregion(pc_axi_awregion),  // input wire [3 : 0] pc_axi_awregion
  .pc_axi_awvalid(pc_axi_awvalid),    // input wire pc_axi_awvalid
  .pc_axi_awready(pc_axi_awready),    // input wire pc_axi_awready
  .pc_axi_wlast(pc_axi_wlast),        // input wire pc_axi_wlast
  .pc_axi_wdata(pc_axi_wdata),        // input wire [511 : 0] pc_axi_wdata
  .pc_axi_wstrb(pc_axi_wstrb),        // input wire [63 : 0] pc_axi_wstrb
  .pc_axi_wvalid(pc_axi_wvalid),      // input wire pc_axi_wvalid
  .pc_axi_wready(pc_axi_wready),      // input wire pc_axi_wready
  .pc_axi_bresp(pc_axi_bresp),        // input wire [1 : 0] pc_axi_bresp
  .pc_axi_bvalid(pc_axi_bvalid),      // input wire pc_axi_bvalid
  .pc_axi_bready(pc_axi_bready),      // input wire pc_axi_bready
  .pc_axi_araddr(pc_axi_araddr),      // input wire [63 : 0] pc_axi_araddr
  .pc_axi_arlen(pc_axi_arlen),        // input wire [7 : 0] pc_axi_arlen
  .pc_axi_arsize(pc_axi_arsize),      // input wire [2 : 0] pc_axi_arsize
  .pc_axi_arburst(pc_axi_arburst),    // input wire [1 : 0] pc_axi_arburst
  .pc_axi_arlock(pc_axi_arlock),      // input wire [0 : 0] pc_axi_arlock
  .pc_axi_arcache(pc_axi_arcache),    // input wire [3 : 0] pc_axi_arcache
  .pc_axi_arprot(pc_axi_arprot),      // input wire [2 : 0] pc_axi_arprot
  .pc_axi_arqos(pc_axi_arqos),        // input wire [3 : 0] pc_axi_arqos
  .pc_axi_arregion(pc_axi_arregion),  // input wire [3 : 0] pc_axi_arregion
  .pc_axi_arvalid(pc_axi_arvalid),    // input wire pc_axi_arvalid
  .pc_axi_arready(pc_axi_arready),    // input wire pc_axi_arready
  .pc_axi_rlast(pc_axi_rlast),        // input wire pc_axi_rlast
  .pc_axi_rdata(pc_axi_rdata),        // input wire [511 : 0] pc_axi_rdata
  .pc_axi_rresp(pc_axi_rresp),        // input wire [1 : 0] pc_axi_rresp
  .pc_axi_rvalid(pc_axi_rvalid),      // input wire pc_axi_rvalid
  .pc_axi_rready(pc_axi_rready)      // input wire pc_axi_rready
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file axi_protocol_checker.v when simulating
// the core, axi_protocol_checker. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

