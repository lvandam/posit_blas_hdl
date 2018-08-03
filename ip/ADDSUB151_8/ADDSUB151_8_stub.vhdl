-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
-- Date        : Wed Aug  1 15:06:57 2018
-- Host        : laurens-ubuntu running 64-bit Ubuntu 16.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/laurens/open-power-snap/actions/posit_dot/posit/ip/ADDSUB151_8/ADDSUB151_8_stub.vhdl
-- Design      : ADDSUB151_8
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku060-ffva1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ADDSUB151_8 is
  Port ( 
    A : in STD_LOGIC_VECTOR ( 150 downto 0 );
    B : in STD_LOGIC_VECTOR ( 150 downto 0 );
    CLK : in STD_LOGIC;
    ADD : in STD_LOGIC;
    SCLR : in STD_LOGIC;
    S : out STD_LOGIC_VECTOR ( 151 downto 0 )
  );

end ADDSUB151_8;

architecture stub of ADDSUB151_8 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "A[150:0],B[150:0],CLK,ADD,SCLR,S[151:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "c_addsub_v12_0_11,Vivado 2017.4";
begin
end;
