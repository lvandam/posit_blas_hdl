-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
-- Date        : Fri Aug  3 12:13:27 2018
-- Host        : laurens-ubuntu running 64-bit Ubuntu 16.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/laurens/Desktop/project_snap/project_snap.srcs/sources_1/ip/axi_protocol_checker/axi_protocol_checker_stub.vhdl
-- Design      : axi_protocol_checker
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku060-ffva1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_protocol_checker is
  Port ( 
    pc_status : out STD_LOGIC_VECTOR ( 159 downto 0 );
    pc_asserted : out STD_LOGIC;
    aclk : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    pc_axi_awaddr : in STD_LOGIC_VECTOR ( 63 downto 0 );
    pc_axi_awlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pc_axi_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pc_axi_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    pc_axi_awlock : in STD_LOGIC_VECTOR ( 0 to 0 );
    pc_axi_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pc_axi_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pc_axi_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pc_axi_awregion : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pc_axi_awvalid : in STD_LOGIC;
    pc_axi_awready : in STD_LOGIC;
    pc_axi_wlast : in STD_LOGIC;
    pc_axi_wdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    pc_axi_wstrb : in STD_LOGIC_VECTOR ( 63 downto 0 );
    pc_axi_wvalid : in STD_LOGIC;
    pc_axi_wready : in STD_LOGIC;
    pc_axi_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    pc_axi_bvalid : in STD_LOGIC;
    pc_axi_bready : in STD_LOGIC;
    pc_axi_araddr : in STD_LOGIC_VECTOR ( 63 downto 0 );
    pc_axi_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pc_axi_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pc_axi_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    pc_axi_arlock : in STD_LOGIC_VECTOR ( 0 to 0 );
    pc_axi_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pc_axi_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    pc_axi_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pc_axi_arregion : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pc_axi_arvalid : in STD_LOGIC;
    pc_axi_arready : in STD_LOGIC;
    pc_axi_rlast : in STD_LOGIC;
    pc_axi_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    pc_axi_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    pc_axi_rvalid : in STD_LOGIC;
    pc_axi_rready : in STD_LOGIC
  );

end axi_protocol_checker;

architecture stub of axi_protocol_checker is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "pc_status[159:0],pc_asserted,aclk,aresetn,pc_axi_awaddr[63:0],pc_axi_awlen[7:0],pc_axi_awsize[2:0],pc_axi_awburst[1:0],pc_axi_awlock[0:0],pc_axi_awcache[3:0],pc_axi_awprot[2:0],pc_axi_awqos[3:0],pc_axi_awregion[3:0],pc_axi_awvalid,pc_axi_awready,pc_axi_wlast,pc_axi_wdata[511:0],pc_axi_wstrb[63:0],pc_axi_wvalid,pc_axi_wready,pc_axi_bresp[1:0],pc_axi_bvalid,pc_axi_bready,pc_axi_araddr[63:0],pc_axi_arlen[7:0],pc_axi_arsize[2:0],pc_axi_arburst[1:0],pc_axi_arlock[0:0],pc_axi_arcache[3:0],pc_axi_arprot[2:0],pc_axi_arqos[3:0],pc_axi_arregion[3:0],pc_axi_arvalid,pc_axi_arready,pc_axi_rlast,pc_axi_rdata[511:0],pc_axi_rresp[1:0],pc_axi_rvalid,pc_axi_rready";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "axi_protocol_checker_v2_0_1_top,Vivado 2017.4";
begin
end;
