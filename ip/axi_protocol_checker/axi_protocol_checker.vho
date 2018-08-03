-- (c) Copyright 1995-2018 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:ip:axi_protocol_checker:2.0
-- IP Revision: 1

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT axi_protocol_checker
  PORT (
    pc_status : OUT STD_LOGIC_VECTOR(159 DOWNTO 0);
    pc_asserted : OUT STD_LOGIC;
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    pc_axi_awaddr : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    pc_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    pc_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    pc_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    pc_axi_awlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    pc_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    pc_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    pc_axi_awqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    pc_axi_awregion : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    pc_axi_awvalid : IN STD_LOGIC;
    pc_axi_awready : IN STD_LOGIC;
    pc_axi_wlast : IN STD_LOGIC;
    pc_axi_wdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    pc_axi_wstrb : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    pc_axi_wvalid : IN STD_LOGIC;
    pc_axi_wready : IN STD_LOGIC;
    pc_axi_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    pc_axi_bvalid : IN STD_LOGIC;
    pc_axi_bready : IN STD_LOGIC;
    pc_axi_araddr : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    pc_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    pc_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    pc_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    pc_axi_arlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    pc_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    pc_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    pc_axi_arqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    pc_axi_arregion : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    pc_axi_arvalid : IN STD_LOGIC;
    pc_axi_arready : IN STD_LOGIC;
    pc_axi_rlast : IN STD_LOGIC;
    pc_axi_rdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    pc_axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    pc_axi_rvalid : IN STD_LOGIC;
    pc_axi_rready : IN STD_LOGIC
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : axi_protocol_checker
  PORT MAP (
    pc_status => pc_status,
    pc_asserted => pc_asserted,
    aclk => aclk,
    aresetn => aresetn,
    pc_axi_awaddr => pc_axi_awaddr,
    pc_axi_awlen => pc_axi_awlen,
    pc_axi_awsize => pc_axi_awsize,
    pc_axi_awburst => pc_axi_awburst,
    pc_axi_awlock => pc_axi_awlock,
    pc_axi_awcache => pc_axi_awcache,
    pc_axi_awprot => pc_axi_awprot,
    pc_axi_awqos => pc_axi_awqos,
    pc_axi_awregion => pc_axi_awregion,
    pc_axi_awvalid => pc_axi_awvalid,
    pc_axi_awready => pc_axi_awready,
    pc_axi_wlast => pc_axi_wlast,
    pc_axi_wdata => pc_axi_wdata,
    pc_axi_wstrb => pc_axi_wstrb,
    pc_axi_wvalid => pc_axi_wvalid,
    pc_axi_wready => pc_axi_wready,
    pc_axi_bresp => pc_axi_bresp,
    pc_axi_bvalid => pc_axi_bvalid,
    pc_axi_bready => pc_axi_bready,
    pc_axi_araddr => pc_axi_araddr,
    pc_axi_arlen => pc_axi_arlen,
    pc_axi_arsize => pc_axi_arsize,
    pc_axi_arburst => pc_axi_arburst,
    pc_axi_arlock => pc_axi_arlock,
    pc_axi_arcache => pc_axi_arcache,
    pc_axi_arprot => pc_axi_arprot,
    pc_axi_arqos => pc_axi_arqos,
    pc_axi_arregion => pc_axi_arregion,
    pc_axi_arvalid => pc_axi_arvalid,
    pc_axi_arready => pc_axi_arready,
    pc_axi_rlast => pc_axi_rlast,
    pc_axi_rdata => pc_axi_rdata,
    pc_axi_rresp => pc_axi_rresp,
    pc_axi_rvalid => pc_axi_rvalid,
    pc_axi_rready => pc_axi_rready
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file axi_protocol_checker.vhd when simulating
-- the core, axi_protocol_checker. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

