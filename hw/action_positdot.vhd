----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Copyright 2016 International Business Machines
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions AND
-- limitations under the License.
--
-- change log:
-- 12/20/2016 R. Rieke fixed case statement issue
----------------------------------------------------------------------------
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.Utils.all;
use work.arrow_positdot_pkg.all;

entity action_positdot is
  generic (
    -- Parameters of Axi Master Bus Interface AXI_CARD_MEM0 ; to DDR memory
    C_AXI_CARD_MEM0_ID_WIDTH     : integer := 2;
    C_AXI_CARD_MEM0_ADDR_WIDTH   : integer := 33;
    C_AXI_CARD_MEM0_DATA_WIDTH   : integer := 512;
    C_AXI_CARD_MEM0_AWUSER_WIDTH : integer := 1;
    C_AXI_CARD_MEM0_ARUSER_WIDTH : integer := 1;
    C_AXI_CARD_MEM0_WUSER_WIDTH  : integer := 1;
    C_AXI_CARD_MEM0_RUSER_WIDTH  : integer := 1;
    C_AXI_CARD_MEM0_BUSER_WIDTH  : integer := 1;

    -- Parameters of Axi Slave Bus Interface AXI_CTRL_REG
    C_AXI_CTRL_REG_DATA_WIDTH : integer := 32;
    C_AXI_CTRL_REG_ADDR_WIDTH : integer := 32;

    -- Parameters of Axi Master Bus Interface AXI_HOST_MEM ; to Host memory
    C_AXI_HOST_MEM_ID_WIDTH     : integer := 2;
    C_AXI_HOST_MEM_ADDR_WIDTH   : integer := 96;  --64
    C_AXI_HOST_MEM_DATA_WIDTH   : integer := 512;
    C_AXI_HOST_MEM_AWUSER_WIDTH : integer := 1;
    C_AXI_HOST_MEM_ARUSER_WIDTH : integer := 1;
    C_AXI_HOST_MEM_WUSER_WIDTH  : integer := 1;
    C_AXI_HOST_MEM_RUSER_WIDTH  : integer := 1;
    C_AXI_HOST_MEM_BUSER_WIDTH  : integer := 1;
    INT_BITS                    : integer := 3;
    CONTEXT_BITS                : integer := 8
    );
  port (
    action_clk   : in  std_logic;
    action_rst_n : in  std_logic;
    int_req_ack  : in  std_logic;
    int_req      : out std_logic;
    int_src      : out std_logic_vector(INT_BITS-2 downto 0);
    int_ctx      : out std_logic_vector(CONTEXT_BITS-1 downto 0);

    -- Ports of Axi Slave Bus Interface AXI_CTRL_REG
    axi_ctrl_reg_awaddr  : in  std_logic_vector(C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0);
    -- axi_ctrl_reg_awprot : in std_logic_vector(2 downto 0);
    axi_ctrl_reg_awvalid : in  std_logic;
    axi_ctrl_reg_awready : out std_logic;
    axi_ctrl_reg_wdata   : in  std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
    axi_ctrl_reg_wstrb   : in  std_logic_vector((C_AXI_CTRL_REG_DATA_WIDTH/8)-1 downto 0);
    axi_ctrl_reg_wvalid  : in  std_logic;
    axi_ctrl_reg_wready  : out std_logic;
    axi_ctrl_reg_bresp   : out std_logic_vector(1 downto 0);
    axi_ctrl_reg_bvalid  : out std_logic;
    axi_ctrl_reg_bready  : in  std_logic;
    axi_ctrl_reg_araddr  : in  std_logic_vector(C_AXI_CTRL_REG_ADDR_WIDTH-1 downto 0);
    -- axi_ctrl_reg_arprot  : in std_logic_vector(2 downto 0);
    axi_ctrl_reg_arvalid : in  std_logic;
    axi_ctrl_reg_arready : out std_logic;
    axi_ctrl_reg_rdata   : out std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
    axi_ctrl_reg_rresp   : out std_logic_vector(1 downto 0);
    axi_ctrl_reg_rvalid  : out std_logic;
    axi_ctrl_reg_rready  : in  std_logic;

    -- Ports of Axi Master Bus Interface AXI_HOST_MEM
    -- to HOST memory
    axi_host_mem_awaddr   : out std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
    axi_host_mem_awlen    : out std_logic_vector(7 downto 0);
    axi_host_mem_awsize   : out std_logic_vector(2 downto 0);
    axi_host_mem_awburst  : out std_logic_vector(1 downto 0);
    axi_host_mem_awlock   : out std_logic_vector(1 downto 0);
    axi_host_mem_awcache  : out std_logic_vector(3 downto 0);
    axi_host_mem_awprot   : out std_logic_vector(2 downto 0);
    axi_host_mem_awregion : out std_logic_vector(3 downto 0);
    axi_host_mem_awqos    : out std_logic_vector(3 downto 0);
    axi_host_mem_awvalid  : out std_logic;
    axi_host_mem_awready  : in  std_logic;
    axi_host_mem_wdata    : out std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
    axi_host_mem_wstrb    : out std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH/8-1 downto 0);
    axi_host_mem_wlast    : out std_logic;
    axi_host_mem_wvalid   : out std_logic;
    axi_host_mem_wready   : in  std_logic;
    axi_host_mem_bresp    : in  std_logic_vector(1 downto 0);
    axi_host_mem_bvalid   : in  std_logic;
    axi_host_mem_bready   : out std_logic;
    axi_host_mem_araddr   : out std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
    axi_host_mem_arlen    : out std_logic_vector(7 downto 0);
    axi_host_mem_arsize   : out std_logic_vector(2 downto 0);
    axi_host_mem_arburst  : out std_logic_vector(1 downto 0);
    axi_host_mem_arlock   : out std_logic_vector(1 downto 0);
    axi_host_mem_arcache  : out std_logic_vector(3 downto 0);
    axi_host_mem_arprot   : out std_logic_vector(2 downto 0);
    axi_host_mem_arregion : out std_logic_vector(3 downto 0);
    axi_host_mem_arqos    : out std_logic_vector(3 downto 0);
    axi_host_mem_arvalid  : out std_logic;
    axi_host_mem_arready  : in  std_logic;
    axi_host_mem_rdata    : in  std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
    axi_host_mem_rresp    : in  std_logic_vector(1 downto 0);
    axi_host_mem_rlast    : in  std_logic;
    axi_host_mem_rvalid   : in  std_logic;
    axi_host_mem_rready   : out std_logic;
--      axi_host_mem_error    : out std_logic;
    axi_host_mem_arid     : out std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_aruser   : out std_logic_vector(C_AXI_HOST_MEM_ARUSER_WIDTH-1 downto 0);
    axi_host_mem_awid     : out std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_awuser   : out std_logic_vector(C_AXI_HOST_MEM_AWUSER_WIDTH-1 downto 0);
    axi_host_mem_bid      : in  std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_buser    : in  std_logic_vector(C_AXI_HOST_MEM_BUSER_WIDTH-1 downto 0);
    axi_host_mem_rid      : in  std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
    axi_host_mem_ruser    : in  std_logic_vector(C_AXI_HOST_MEM_RUSER_WIDTH-1 downto 0);
    axi_host_mem_wuser    : out std_logic_vector(C_AXI_HOST_MEM_WUSER_WIDTH-1 downto 0)
    );
end action_positdot;



architecture action_positdot of action_positdot is
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

      signal s_axi_host_mem_awaddr   :  std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
      signal s_axi_host_mem_awlen    :  std_logic_vector(7 downto 0);
      signal s_axi_host_mem_awsize   :  std_logic_vector(2 downto 0);
      signal s_axi_host_mem_awburst  :  std_logic_vector(1 downto 0);
      signal s_axi_host_mem_awlock   :  std_logic_vector(1 downto 0);
      signal s_axi_host_mem_awcache  :  std_logic_vector(3 downto 0);
      signal s_axi_host_mem_awprot   :  std_logic_vector(2 downto 0);
      signal s_axi_host_mem_awregion :  std_logic_vector(3 downto 0);
      signal s_axi_host_mem_awqos    :  std_logic_vector(3 downto 0);
      signal s_axi_host_mem_awvalid  :  std_logic;
      signal s_axi_host_mem_awready  : std_logic;
      signal s_axi_host_mem_wdata    :  std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
      signal s_axi_host_mem_wstrb    :  std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH/8-1 downto 0);
      signal s_axi_host_mem_wlast    :  std_logic;
      signal s_axi_host_mem_wvalid   :  std_logic;
      signal s_axi_host_mem_wready   : std_logic;
      signal s_axi_host_mem_bresp    : std_logic_vector(1 downto 0);
      signal s_axi_host_mem_bvalid   : std_logic;
      signal s_axi_host_mem_bready   :  std_logic;
      signal s_axi_host_mem_araddr   :  std_logic_vector(C_AXI_HOST_MEM_ADDR_WIDTH-1 downto 0);
      signal s_axi_host_mem_arlen    :  std_logic_vector(7 downto 0);
      signal s_axi_host_mem_arsize   :  std_logic_vector(2 downto 0);
      signal s_axi_host_mem_arburst  :  std_logic_vector(1 downto 0);
      signal s_axi_host_mem_arlock   :  std_logic_vector(1 downto 0);
      signal s_axi_host_mem_arcache  :  std_logic_vector(3 downto 0);
      signal s_axi_host_mem_arprot   :  std_logic_vector(2 downto 0);
      signal s_axi_host_mem_arregion :  std_logic_vector(3 downto 0);
      signal s_axi_host_mem_arqos    :  std_logic_vector(3 downto 0);
      signal s_axi_host_mem_arvalid  :  std_logic;
      signal s_axi_host_mem_arready  : std_logic;
      signal s_axi_host_mem_rdata    : std_logic_vector(C_AXI_HOST_MEM_DATA_WIDTH-1 downto 0);
      signal s_axi_host_mem_rresp    : std_logic_vector(1 downto 0);
      signal s_axi_host_mem_rlast    : std_logic;
      signal s_axi_host_mem_rvalid   : std_logic;
      signal s_axi_host_mem_rready   :  std_logic;
      signal s_axi_host_mem_arid     :  std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
      signal s_axi_host_mem_aruser   :  std_logic_vector(C_AXI_HOST_MEM_ARUSER_WIDTH-1 downto 0);
      signal s_axi_host_mem_awid     :  std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
      signal s_axi_host_mem_awuser   :  std_logic_vector(C_AXI_HOST_MEM_AWUSER_WIDTH-1 downto 0);
      signal s_axi_host_mem_bid      : std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
      signal s_axi_host_mem_buser    : std_logic_vector(C_AXI_HOST_MEM_BUSER_WIDTH-1 downto 0);
      signal s_axi_host_mem_rid      : std_logic_vector(C_AXI_HOST_MEM_ID_WIDTH-1 downto 0);
      signal s_axi_host_mem_ruser    : std_logic_vector(C_AXI_HOST_MEM_RUSER_WIDTH-1 downto 0);
      signal s_axi_host_mem_wuser    :  std_logic_vector(C_AXI_HOST_MEM_WUSER_WIDTH-1 downto 0);

  -----------------------------------
  -- SNAP registers
  -----------------------------------
  --   1 control (uint32_t)     =  1
  --   1 interrupt enable       =  1
  --   1 type                   =  1
  --   1 version                =  1
  --   1 context id             =  1
  -----------------------------------
  -- SNAP Total:                   5 regs

  constant SNAP_NUM_REGS   : natural := 9;
  constant SNAP_ADDR_WIDTH : natural := 2 + log2floor(SNAP_NUM_REGS);

  -- SNAP register offsets
  constant SNAP_REG_CONTROL          : natural := 0;
  constant SNAP_REG_INTERRUPT_ENABLE : natural := 1;
  constant SNAP_REG_TYPE             : natural := 4;
  constant SNAP_REG_VERSION          : natural := 5;
  constant SNAP_REG_CONTEXT_ID       : natural := 8;

  type snap_regs_t is array (0 to SNAP_NUM_REGS-1) of std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
  signal snap_regs : snap_regs_t;

  signal regexp_s_axi_awaddr  : std_logic_vector(8 downto 0);
  signal regexp_s_axi_awvalid : std_logic;
  signal regexp_s_axi_awready : std_logic;
  signal regexp_s_axi_wdata   : std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
  signal regexp_s_axi_wstrb   : std_logic_vector((C_AXI_CTRL_REG_DATA_WIDTH/8)-1 downto 0);
  signal regexp_s_axi_wvalid  : std_logic;
  signal regexp_s_axi_wready  : std_logic;
  signal regexp_s_axi_bresp   : std_logic_vector(1 downto 0);
  signal regexp_s_axi_bvalid  : std_logic;
  signal regexp_s_axi_bready  : std_logic;
  signal regexp_s_axi_arvalid : std_logic;
  signal regexp_s_axi_arready : std_logic;
  signal regexp_s_axi_araddr  : std_logic_vector(8 downto 0);
  signal regexp_s_axi_rvalid  : std_logic;
  signal regexp_s_axi_rready  : std_logic;
  signal regexp_s_axi_rdata   : std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
  signal regexp_s_axi_rresp   : std_logic_vector(1 downto 0);

  signal snap_s_axi_awaddr  : std_logic_vector(SNAP_ADDR_WIDTH-1 downto 0);
  signal snap_s_axi_awvalid : std_logic;
  signal snap_s_axi_awready : std_logic;
  signal snap_s_axi_wdata   : std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
  signal snap_s_axi_wstrb   : std_logic_vector((C_AXI_CTRL_REG_DATA_WIDTH/8)-1 downto 0);
  signal snap_s_axi_wvalid  : std_logic;
  signal snap_s_axi_wready  : std_logic;
  signal snap_s_axi_bresp   : std_logic_vector(1 downto 0);
  signal snap_s_axi_bvalid  : std_logic;
  signal snap_s_axi_bready  : std_logic;
  signal snap_s_axi_arvalid : std_logic;
  signal snap_s_axi_arready : std_logic;
  signal snap_s_axi_araddr  : std_logic_vector(SNAP_ADDR_WIDTH-1 downto 0);
  signal snap_s_axi_rvalid  : std_logic;
  signal snap_s_axi_rready  : std_logic;
  signal snap_s_axi_rdata   : std_logic_vector(C_AXI_CTRL_REG_DATA_WIDTH-1 downto 0);
  signal snap_s_axi_rresp   : std_logic_vector(1 downto 0);

  signal snap_read_address : natural range 0 to SNAP_NUM_REGS-1;

  signal read_valid      : std_logic;
  signal write_processed : std_logic;
  signal write_valid     : std_logic;

  signal regexp_space_r : std_logic;
  signal regexp_space_w : std_logic;

  component arrow_positdot is
    generic (
      -- Number of pair HMM units. Must be a natural multiple of 2
      CORES : natural := 1;

      -- Host bus properties
      BUS_ADDR_WIDTH : natural := 64;
      BUS_DATA_WIDTH : natural := 512;

      -- MMIO bus properties
      SLV_BUS_ADDR_WIDTH : natural := 32;
      SLV_BUS_DATA_WIDTH : natural := 32;

      REG_WIDTH : natural := 32

     -- (Generic defaults are set for SystemVerilog compatibility)
      );

    port (
      clk     : in std_logic;
      reset_n : in std_logic;

      ---------------------------------------------------------------------------
      -- AXI4 master
      --
      -- To be connected to the DDR controllers (through CL_DMA_PCIS_SLV)
      ---------------------------------------------------------------------------
      -- Read address channel
      m_axi_araddr  : out std_logic_vector(BUS_ADDR_WIDTH-1 downto 0);
      m_axi_arlen   : out std_logic_vector(7 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in  std_logic;
      m_axi_arsize  : out std_logic_vector(2 downto 0);

      -- Read data channel
      m_axi_rdata  : in  std_logic_vector(BUS_DATA_WIDTH-1 downto 0);
      m_axi_rresp  : in  std_logic_vector(1 downto 0);
      m_axi_rlast  : in  std_logic;
      m_axi_rvalid : in  std_logic;
      m_axi_rready : out std_logic;

      -- Write address channel
      m_axi_awvalid : out std_logic;
      m_axi_awready : in  std_logic;
      m_axi_awaddr  : out std_logic_vector(BUS_ADDR_WIDTH-1 downto 0);
      m_axi_awlen   : out std_logic_vector(7 downto 0);
      m_axi_awsize  : out std_logic_vector(2 downto 0);

      -- Write data channel
      m_axi_wvalid : out std_logic;
      m_axi_wready : in  std_logic;
      m_axi_wdata  : out std_logic_vector(BUS_DATA_WIDTH-1 downto 0);
      m_axi_wlast  : out std_logic;
      m_axi_wstrb  : out std_logic_vector(BUS_DATA_WIDTH/8-1 downto 0);

      ---------------------------------------------------------------------------
      -- AXI4-lite slave
      --
      -- To be connected to "sh_cl_sda" a.k.a. "AppPF Bar 1"
      ---------------------------------------------------------------------------
      -- Write adress
      s_axi_awvalid : in  std_logic;
      s_axi_awready : out std_logic;
      s_axi_awaddr  : in  std_logic_vector(SLV_BUS_ADDR_WIDTH-1 downto 0);

      -- Write data
      s_axi_wvalid : in  std_logic;
      s_axi_wready : out std_logic;
      s_axi_wdata  : in  std_logic_vector(SLV_BUS_DATA_WIDTH-1 downto 0);
      s_axi_wstrb  : in  std_logic_vector((SLV_BUS_DATA_WIDTH/8)-1 downto 0);

      -- Write response
      s_axi_bvalid : out std_logic;
      s_axi_bready : in  std_logic;
      s_axi_bresp  : out std_logic_vector(1 downto 0);

      -- Read address
      s_axi_arvalid : in  std_logic;
      s_axi_arready : out std_logic;
      s_axi_araddr  : in  std_logic_vector(SLV_BUS_ADDR_WIDTH-1 downto 0);

      -- Read data
      s_axi_rvalid : out std_logic;
      s_axi_rready : in  std_logic;
      s_axi_rdata  : out std_logic_vector(SLV_BUS_DATA_WIDTH-1 downto 0);
      s_axi_rresp  : out std_logic_vector(1 downto 0)
      );
  end component;

begin

    axi_host_mem_awaddr   <= s_axi_host_mem_awaddr   ;
    axi_host_mem_awlen    <= s_axi_host_mem_awlen    ;
    axi_host_mem_awsize   <= s_axi_host_mem_awsize   ;
    axi_host_mem_awburst  <= s_axi_host_mem_awburst  ;
    axi_host_mem_awlock   <= s_axi_host_mem_awlock   ;
    axi_host_mem_awcache  <= s_axi_host_mem_awcache  ;
    axi_host_mem_awprot   <= s_axi_host_mem_awprot   ;
    axi_host_mem_awregion <= s_axi_host_mem_awregion ;
    axi_host_mem_awqos    <= s_axi_host_mem_awqos    ;
    axi_host_mem_awvalid  <= s_axi_host_mem_awvalid  ;
    axi_host_mem_wdata    <= s_axi_host_mem_wdata    ;
    axi_host_mem_wstrb    <= s_axi_host_mem_wstrb    ;
    axi_host_mem_wlast    <= s_axi_host_mem_wlast    ;
    axi_host_mem_wvalid   <= s_axi_host_mem_wvalid   ;
    axi_host_mem_bready   <= s_axi_host_mem_bready   ;
    axi_host_mem_araddr   <= s_axi_host_mem_araddr   ;
    axi_host_mem_arlen    <= s_axi_host_mem_arlen    ;
    axi_host_mem_arsize   <= s_axi_host_mem_arsize   ;
    axi_host_mem_arburst  <= s_axi_host_mem_arburst  ;
    axi_host_mem_arlock   <= s_axi_host_mem_arlock   ;
    axi_host_mem_arcache  <= s_axi_host_mem_arcache  ;
    axi_host_mem_arprot   <= s_axi_host_mem_arprot   ;
    axi_host_mem_arregion <= s_axi_host_mem_arregion ;
    axi_host_mem_arqos    <= s_axi_host_mem_arqos    ;
    axi_host_mem_arvalid  <= s_axi_host_mem_arvalid  ;
    axi_host_mem_rready   <= s_axi_host_mem_rready   ;
    axi_host_mem_arid     <= s_axi_host_mem_arid     ;
    axi_host_mem_aruser   <= s_axi_host_mem_aruser   ;
    axi_host_mem_awid     <= s_axi_host_mem_awid     ;
    axi_host_mem_awuser   <= s_axi_host_mem_awuser   ;
    axi_host_mem_wuser    <= s_axi_host_mem_wuser    ;
    s_axi_host_mem_awready  <= axi_host_mem_awready  ;
    s_axi_host_mem_wready   <= axi_host_mem_wready   ;
    s_axi_host_mem_bresp    <= axi_host_mem_bresp    ;
    s_axi_host_mem_bvalid   <= axi_host_mem_bvalid   ;
    s_axi_host_mem_arready  <= axi_host_mem_arready  ;
    s_axi_host_mem_rdata    <= axi_host_mem_rdata    ;
    s_axi_host_mem_rresp    <= axi_host_mem_rresp    ;
    s_axi_host_mem_rlast    <= axi_host_mem_rlast    ;
    s_axi_host_mem_rvalid   <= axi_host_mem_rvalid   ;
    s_axi_host_mem_bid      <= axi_host_mem_bid      ;
    s_axi_host_mem_buser    <= axi_host_mem_buser    ;
    s_axi_host_mem_rid      <= axi_host_mem_rid      ;
    s_axi_host_mem_ruser    <= axi_host_mem_ruser    ;

  ----------------------------------------------------------------------
  -- AXI Lite Slave inputs
  ----------------------------------------------------------------------
  regexp_space_r <= axi_ctrl_reg_araddr(9);
  regexp_space_w <= axi_ctrl_reg_araddr(9);

  -- RegExp inputs
  regexp_s_axi_awaddr  <= axi_ctrl_reg_awaddr(8 downto 0);
  regexp_s_axi_awvalid <= axi_ctrl_reg_awvalid and regexp_space_w;
  regexp_s_axi_wdata   <= axi_ctrl_reg_wdata;
  regexp_s_axi_wstrb   <= axi_ctrl_reg_wstrb;
  regexp_s_axi_wvalid  <= axi_ctrl_reg_wvalid;
  regexp_s_axi_bready  <= axi_ctrl_reg_bready;

  regexp_s_axi_arvalid <= axi_ctrl_reg_arvalid and regexp_space_r;
  regexp_s_axi_araddr  <= axi_ctrl_reg_araddr(8 downto 0);
  regexp_s_axi_rready  <= axi_ctrl_reg_rready;

  -- SNAP inputs
  snap_s_axi_awaddr  <= axi_ctrl_reg_awaddr(SNAP_ADDR_WIDTH-1 downto 0);
  snap_s_axi_awvalid <= axi_ctrl_reg_awvalid and not(regexp_space_w);
  snap_s_axi_wdata   <= axi_ctrl_reg_wdata;
  snap_s_axi_wstrb   <= axi_ctrl_reg_wstrb;
  snap_s_axi_wvalid  <= axi_ctrl_reg_wvalid;
  snap_s_axi_bready  <= axi_ctrl_reg_bready;

  snap_s_axi_arvalid <= axi_ctrl_reg_arvalid and not(regexp_space_r);
  snap_s_axi_araddr  <= axi_ctrl_reg_araddr(SNAP_ADDR_WIDTH-1 downto 0);
  snap_s_axi_rready  <= axi_ctrl_reg_rready;

  ----------------------------------------------------------------------
  -- AXI Lite Slave outputs
  ----------------------------------------------------------------------
  -- Write channels
  axi_ctrl_reg_awready <= regexp_s_axi_awready when regexp_space_w = '1' else snap_s_axi_awready;
  axi_ctrl_reg_wready  <= regexp_s_axi_wready  when regexp_space_w = '1' else snap_s_axi_wready;  -- Blatantly assuming awready is given with wready

  axi_ctrl_reg_bresp  <= regexp_s_axi_bresp  when regexp_s_axi_bvalid = '1' else snap_s_axi_bresp;
  axi_ctrl_reg_bvalid <= regexp_s_axi_bvalid when regexp_s_axi_bvalid = '1' else snap_s_axi_bvalid;

  -- Read channels
  axi_ctrl_reg_arready <= regexp_s_axi_arready when regexp_space_r = '1' else snap_s_axi_arready;

  axi_ctrl_reg_rdata  <= regexp_s_axi_rdata  when regexp_s_axi_rvalid = '1' else snap_s_axi_rdata;
  axi_ctrl_reg_rresp  <= regexp_s_axi_rresp  when regexp_s_axi_rvalid = '1' else snap_s_axi_rresp;
  axi_ctrl_reg_rvalid <= regexp_s_axi_rvalid when regexp_s_axi_rvalid = '1' else snap_s_axi_rvalid;

  ----------------------------------------------------------------------
  -- SNAP AXI Lite slave
  ----------------------------------------------------------------------
  -- We just need to implement reads from REG_SNAP_TYPE and REG_SNAP_VERSION
  snap_regs(SNAP_REG_TYPE)    <= X"00000001";
  snap_regs(SNAP_REG_VERSION) <= X"00000000";

  -- Ready
  snap_s_axi_arready <= not read_valid;

  -- Mux for reading
  snap_s_axi_rdata  <= snap_regs(snap_read_address);
  snap_s_axi_rvalid <= read_valid;
  snap_s_axi_rresp  <= "00";            -- Always OK

  -- Writing
  write_valid <= snap_s_axi_awvalid and snap_s_axi_wvalid and not write_processed;

  snap_s_axi_awready <= write_valid;
  snap_s_axi_wready  <= write_valid;
  snap_s_axi_bresp   <= "00";           -- Always OK
  snap_s_axi_bvalid  <= write_processed;

  -- Read
  read_proc : process(action_clk) is
  begin
    if rising_edge(action_clk) then
      snap_read_address <= int(snap_s_axi_araddr(SNAP_ADDR_WIDTH-1 downto 2));
      if snap_s_axi_arvalid = '1' and read_valid = '0' then
        read_valid <= '1';
      elsif snap_s_axi_rready = '1' then
        read_valid <= '0';
      end if;

      -- Reset
      if action_rst_n = '0' then
        read_valid <= '0';
      end if;
    end if;
  end process;

  -- Writes
  write_proc : process(action_clk) is
    variable address : natural range 0 to SNAP_NUM_REGS-1;
  begin
    address := int(snap_s_axi_araddr(SNAP_ADDR_WIDTH-1 downto 2));
    if rising_edge(action_clk) then
      if write_valid = '1' then
        case address is
          when SNAP_REG_CONTEXT_ID       => snap_regs(SNAP_REG_CONTEXT_ID)       <= snap_s_axi_wdata;
          when SNAP_REG_CONTROL          => snap_regs(SNAP_REG_CONTROL)          <= snap_s_axi_wdata;
          when SNAP_REG_INTERRUPT_ENABLE => snap_regs(SNAP_REG_INTERRUPT_ENABLE) <= snap_s_axi_wdata;
          when others                    =>  -- do nothing to read only regs
        end case;
      end if;

      -- Reset
      if action_rst_n = '0' then
        snap_regs(SNAP_REG_CONTROL) <= (others => '0');
      end if;
    end if;
  end process;

  -- Write response
  write_resp_proc : process(action_clk) is
  begin
    if rising_edge(action_clk) then
      if write_valid = '1' then
        write_processed <= '1';
      elsif snap_s_axi_bready = '1' then
        write_processed <= '0';
      end if;

      -- Reset
      if action_rst_n = '0' then
        write_processed <= '0';
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------
  -- AXI Host Memory
  ----------------------------------------------------------------------
  -- Write channel tie off
   s_axi_host_mem_bready  <= '1';

  -- Read channel defaults:
  s_axi_host_mem_arsize  <= "110";        -- 512 bit beats
  s_axi_host_mem_arburst <= "01";         -- incremental

  -- Write channel defaults:
  s_axi_host_mem_awsize           <= "110"; -- 512 bit beats
  s_axi_host_mem_awburst          <= "01"; -- incremental

  -- Not using any of these:
  s_axi_host_mem_awid             <= (others => '0');
  s_axi_host_mem_awlock           <= (others => '0');
  s_axi_host_mem_awcache          <= "0010";
  s_axi_host_mem_awprot           <= "000";
  s_axi_host_mem_awqos            <= x"0";
  s_axi_host_mem_awuser           <= (others => '0');

  -- Not using any of these:
  s_axi_host_mem_arid    <= (others => '0');
  s_axi_host_mem_arlock  <= (others => '0');
  s_axi_host_mem_arcache <= "0010";
  s_axi_host_mem_arprot  <= "000";
  s_axi_host_mem_arqos   <= x"0";
  s_axi_host_mem_aruser  <= (others => '0');

  ----------------------------------------------------------------------
  -- Arrow posit dot instance
  ----------------------------------------------------------------------
  arrow_positdot_inst : arrow_positdot
    generic map (
      BUS_ADDR_WIDTH     => C_AXI_HOST_MEM_ADDR_WIDTH,
      BUS_DATA_WIDTH     => C_AXI_HOST_MEM_DATA_WIDTH,
      SLV_BUS_ADDR_WIDTH => 9,
      SLV_BUS_DATA_WIDTH => C_AXI_CTRL_REG_DATA_WIDTH,
      REG_WIDTH          => 32
      )
    port map (
      clk     => action_clk,
      reset_n => action_rst_n,

      ---------------------------------------------------------------------------
      -- AXI4 master
      --
      -- To be connected to the DDR controllers (through CL_DMA_PCIS_SLV)
      ---------------------------------------------------------------------------
      -- Read address channel
      m_axi_araddr  => s_axi_host_mem_araddr,
      m_axi_arlen   => s_axi_host_mem_arlen,
      m_axi_arvalid => s_axi_host_mem_arvalid,
      m_axi_arready => s_axi_host_mem_arready,
      m_axi_arsize  => open,

      -- Read data channel
      m_axi_rdata  => s_axi_host_mem_rdata,
      m_axi_rresp  => s_axi_host_mem_rresp,
      m_axi_rlast  => s_axi_host_mem_rlast,
      m_axi_rvalid => s_axi_host_mem_rvalid,
      m_axi_rready => s_axi_host_mem_rready,

      -- Write address channel
      m_axi_awvalid => s_axi_host_mem_awvalid,
      m_axi_awready => s_axi_host_mem_awready,
      m_axi_awaddr  => s_axi_host_mem_awaddr,
      m_axi_awlen   => s_axi_host_mem_awlen,
      m_axi_awsize  => open,

      -- Write data channel
      m_axi_wvalid => s_axi_host_mem_wvalid,
      m_axi_wready => s_axi_host_mem_wready,
      m_axi_wdata  => s_axi_host_mem_wdata,
      m_axi_wlast  => s_axi_host_mem_wlast,
      m_axi_wstrb  => s_axi_host_mem_wstrb,

      ---------------------------------------------------------------------------
      -- AXI4-lite slave
      --
      -- To be connected to "sh_cl_sda" a.k.a. "AppPF Bar 1"
      ---------------------------------------------------------------------------
      -- Write adress
      s_axi_awvalid => regexp_s_axi_awvalid,
      s_axi_awready => regexp_s_axi_awready,
      s_axi_awaddr  => regexp_s_axi_awaddr,

      -- Write data
      s_axi_wvalid => regexp_s_axi_wvalid,
      s_axi_wready => regexp_s_axi_wready,
      s_axi_wdata  => regexp_s_axi_wdata,
      s_axi_wstrb  => regexp_s_axi_wstrb,

      -- Write response
      s_axi_bvalid => regexp_s_axi_bvalid,
      s_axi_bready => regexp_s_axi_bready,
      s_axi_bresp  => regexp_s_axi_bresp,

      -- Read address
      s_axi_arvalid => regexp_s_axi_arvalid,
      s_axi_arready => regexp_s_axi_arready,
      s_axi_araddr  => regexp_s_axi_araddr,

      -- Read data
      s_axi_rvalid => regexp_s_axi_rvalid,
      s_axi_rready => regexp_s_axi_rready,
      s_axi_rdata  => regexp_s_axi_rdata,
      s_axi_rresp  => regexp_s_axi_rresp
      );

      -- AXI protocol checker
  prot_check : axi_protocol_checker
  PORT MAP (
    --pc_status => pc_status,
    --pc_asserted => pc_asserted,
    aclk            => action_clk,
    aresetn         => action_rst_n,
    pc_axi_awaddr   => s_axi_host_mem_awaddr,
    pc_axi_awlen    => s_axi_host_mem_awlen,
    pc_axi_awsize   => s_axi_host_mem_awsize,
    pc_axi_awburst  => s_axi_host_mem_awburst,
    pc_axi_awlock   => s_axi_host_mem_awlock(0 downto 0),
    pc_axi_awcache  => s_axi_host_mem_awcache,
    pc_axi_awprot   => s_axi_host_mem_awprot,
    pc_axi_awqos    => s_axi_host_mem_awqos,
    pc_axi_awregion => s_axi_host_mem_awregion,
    pc_axi_awvalid  => s_axi_host_mem_awvalid,
    pc_axi_awready  => s_axi_host_mem_awready,
    pc_axi_wlast    => s_axi_host_mem_wlast,
    pc_axi_wdata    => s_axi_host_mem_wdata,
    pc_axi_wstrb    => s_axi_host_mem_wstrb,
    pc_axi_wvalid   => s_axi_host_mem_wvalid,
    pc_axi_wready   => s_axi_host_mem_wready,
    pc_axi_bresp    => s_axi_host_mem_bresp,
    pc_axi_bvalid   => s_axi_host_mem_bvalid,
    pc_axi_bready   => s_axi_host_mem_bready,
    pc_axi_araddr   => s_axi_host_mem_araddr,
    pc_axi_arlen    => s_axi_host_mem_arlen,
    pc_axi_arsize   => s_axi_host_mem_arsize,
    pc_axi_arburst  => s_axi_host_mem_arburst,
    pc_axi_arlock   => s_axi_host_mem_arlock(0 downto 0),
    pc_axi_arcache  => s_axi_host_mem_arcache,
    pc_axi_arprot   => s_axi_host_mem_arprot,
    pc_axi_arqos    => s_axi_host_mem_arqos,
    pc_axi_arregion => s_axi_host_mem_arregion,
    pc_axi_arvalid  => s_axi_host_mem_arvalid,
    pc_axi_arready  => s_axi_host_mem_arready,
    pc_axi_rlast    => s_axi_host_mem_rlast,
    pc_axi_rdata    => s_axi_host_mem_rdata,
    pc_axi_rresp    => s_axi_host_mem_rresp,
    pc_axi_rvalid   => s_axi_host_mem_rvalid,
    pc_axi_rready   => s_axi_host_mem_rready
  );

end action_positdot;
