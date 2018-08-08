-- Copyright 2018 Delft University of Technology
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
-- See the License for the specific language governing permissions and
-- limitations under the License.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.Utils.all;

package arrow_positdot_pkg is
  -----------------------------------------------------------------------------
  -- Bus interfaces
  -----------------------------------------------------------------------------
  constant BOTTOM_ADDR_WIDTH     : natural := 64;
  constant BOTTOM_DATA_WIDTH     : natural := 512;
  constant BOTTOM_ID_WIDTH       : natural := 1;
  constant BOTTOM_BURST_STEP_LEN : natural := 1;
  constant BOTTOM_BURST_MAX_LEN  : natural := 32;
  constant BOTTOM_LEN_WIDTH      : natural := log2ceil(BOTTOM_BURST_MAX_LEN) + 1;
  constant BOTTOM_ENABLE_FIFO    : boolean := true;

  constant MID_ADDR_WIDTH  : natural := 64;
  constant MID_DATA_WIDTH  : natural := 512;
  constant MID_WSTRB_WIDTH : natural := 64;
  constant MID_ID_WIDTH    : natural := 1;

  constant TOP_ADDR_WIDTH  : natural := 64;
  constant TOP_DATA_WIDTH  : natural := 512;
  constant TOP_WSTRB_WIDTH : natural := 64;
  constant TOP_ID_WIDTH    : natural := 8;

  -----------------------------------------------------------------------------
  -- Arrow pair HMM top-level
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Internal buses
  -----------------------------------------------------------------------------
  -- Bottom columnreader to read converters
  -- All signals have the same definition as in AXI4, except len which is axi_len + 1
  type bus_bottom_read_t is record
    req_id    : std_logic_vector(BOTTOM_ID_WIDTH-1 downto 0);
    req_addr  : std_logic_vector(BOTTOM_ADDR_WIDTH-1 downto 0);
    req_len   : std_logic_vector(BOTTOM_LEN_WIDTH-1 downto 0);
    req_valid : std_logic;
    req_ready : std_logic;
    rsp_id    : std_logic_vector(BOTTOM_ID_WIDTH-1 downto 0);
    rsp_data  : std_logic_vector(BOTTOM_DATA_WIDTH-1 downto 0);
    rsp_resp  : std_logic_vector(1 downto 0);
    rsp_last  : std_logic;
    rsp_valid : std_logic;
    rsp_ready : std_logic;
  end record;

  -- Bottom result columnwriter to write converters
  -- All signals have the same definition as in AXI4, except len which is axi_len + 1
  type bus_bottom_write_t is record
    wreq_id     : std_logic_vector(BOTTOM_ID_WIDTH-1 downto 0);
    wreq_addr   : std_logic_vector(BOTTOM_ADDR_WIDTH-1 downto 0);
    wreq_len    : std_logic_vector(BOTTOM_LEN_WIDTH-1 downto 0);
    wreq_valid  : std_logic;
    wreq_ready  : std_logic;
    wdat_valid  : std_logic;
    wdat_ready  : std_logic;
    wdat_data   : std_logic_vector(BOTTOM_DATA_WIDTH-1 downto 0);
    wdat_strobe : std_logic_vector(BOTTOM_DATA_WIDTH/8-1 downto 0);
    wdat_last   : std_logic;
  end record;

  -- Mid (read converters to interconnect)
  type axi_mid_t is record
    areset_out_n : std_logic;
    aclk         : std_logic;
    awid         : std_logic_vector(MID_ID_WIDTH-1 downto 0);
    awaddr       : std_logic_vector(MID_ADDR_WIDTH-1 downto 0);
    awlen        : std_logic_vector(7 downto 0);
    awsize       : std_logic_vector(2 downto 0);
    awburst      : std_logic_vector(1 downto 0);
    awlock       : std_logic;
    awcache      : std_logic_vector(3 downto 0);
    awprot       : std_logic_vector(2 downto 0);
    awqos        : std_logic_vector(3 downto 0);
    awvalid      : std_logic;
    awready      : std_logic;
    wdata        : std_logic_vector(MID_DATA_WIDTH-1 downto 0);
    wstrb        : std_logic_vector(MID_WSTRB_WIDTH-1 downto 0);
    wlast        : std_logic;
    wvalid       : std_logic;
    wready       : std_logic;
    bid          : std_logic_vector(MID_ID_WIDTH-1 downto 0);
    bresp        : std_logic_vector(1 downto 0);
    bvalid       : std_logic;
    bready       : std_logic;
    arid         : std_logic_vector(MID_ID_WIDTH-1 downto 0);
    araddr       : std_logic_vector(MID_ADDR_WIDTH-1 downto 0);
    arlen        : std_logic_vector(7 downto 0);
    arsize       : std_logic_vector(2 downto 0);
    arburst      : std_logic_vector(1 downto 0);
    arlock       : std_logic;
    arcache      : std_logic_vector(3 downto 0);
    arprot       : std_logic_vector(2 downto 0);
    arqos        : std_logic_vector(3 downto 0);
    arvalid      : std_logic;
    arready      : std_logic;
    rid          : std_logic_vector(MID_ID_WIDTH-1 downto 0);
    rdata        : std_logic_vector(MID_DATA_WIDTH-1 downto 0);
    rresp        : std_logic_vector(1 downto 0);
    rlast        : std_logic;
    rvalid       : std_logic;
    rready       : std_logic;
  end record;

  -- Top (to host interface)
  type axi_top_t is record
    areset_out_n : std_logic;
    aclk         : std_logic;
    awid         : std_logic_vector(TOP_ID_WIDTH-1 downto 0);
    awaddr       : std_logic_vector(TOP_ADDR_WIDTH-1 downto 0);
    awlen        : std_logic_vector(7 downto 0);
    awsize       : std_logic_vector(2 downto 0);
    awburst      : std_logic_vector(1 downto 0);
    awlock       : std_logic;
    awcache      : std_logic_vector(3 downto 0);
    awprot       : std_logic_vector(2 downto 0);
    awqos        : std_logic_vector(3 downto 0);
    awvalid      : std_logic;
    awready      : std_logic;
    wdata        : std_logic_vector(TOP_DATA_WIDTH-1 downto 0);
    wstrb        : std_logic_vector(TOP_WSTRB_WIDTH-1 downto 0);
    wlast        : std_logic;
    wvalid       : std_logic;
    wready       : std_logic;
    bid          : std_logic_vector(TOP_ID_WIDTH-1 downto 0);
    bresp        : std_logic_vector(1 downto 0);
    bvalid       : std_logic;
    bready       : std_logic;
    arid         : std_logic_vector(TOP_ID_WIDTH-1 downto 0);
    araddr       : std_logic_vector(TOP_ADDR_WIDTH-1 downto 0);
    arlen        : std_logic_vector(7 downto 0);
    arsize       : std_logic_vector(2 downto 0);
    arburst      : std_logic_vector(1 downto 0);
    arlock       : std_logic;
    arcache      : std_logic_vector(3 downto 0);
    arprot       : std_logic_vector(2 downto 0);
    arqos        : std_logic_vector(3 downto 0);
    arvalid      : std_logic;
    arready      : std_logic;
    rid          : std_logic_vector(TOP_ID_WIDTH-1 downto 0);
    rdata        : std_logic_vector(TOP_DATA_WIDTH-1 downto 0);
    rresp        : std_logic_vector(1 downto 0);
    rlast        : std_logic;
    rvalid       : std_logic;
    rready       : std_logic;
  end record;

  -----------------------------------------------------------------------------
  -- AXI read address & data channel conversion
  -----------------------------------------------------------------------------
  component axi_read_converter is
    generic (
      ADDR_WIDTH : natural;
      ID_WIDTH   : natural;

      MASTER_DATA_WIDTH : natural;
      MASTER_LEN_WIDTH  : natural := 8;

      SLAVE_DATA_WIDTH : natural;
      SLAVE_LEN_WIDTH  : natural;
      SLAVE_MAX_BURST  : natural;

      ENABLE_FIFO : boolean := true
      );
    port (
      clk             : in  std_logic;
      reset_n         : in  std_logic;
      s_bus_req_addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      s_bus_req_len   : in  std_logic_vector(SLAVE_LEN_WIDTH-1 downto 0);
      s_bus_req_valid : in  std_logic;
      s_bus_req_ready : out std_logic;
      s_bus_rsp_data  : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      s_bus_rsp_last  : out std_logic;
      s_bus_rsp_valid : out std_logic;
      s_bus_rsp_ready : in  std_logic;
      m_axi_araddr    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      m_axi_arlen     : out std_logic_vector(7 downto 0);
      m_axi_arvalid   : out std_logic;
      m_axi_arready   : in  std_logic;
      m_axi_arsize    : out std_logic_vector(2 downto 0);
      m_axi_rdata     : in  std_logic_vector(MASTER_DATA_WIDTH-1 downto 0);
      m_axi_rlast     : in  std_logic;
      m_axi_rvalid    : in  std_logic;
      m_axi_rready    : out std_logic
      );
  end component;

  -----------------------------------------------------------------------------
  -- AXI write address & data channel conversion
  -----------------------------------------------------------------------------
  component axi_write_converter is
    generic (
      ADDR_WIDTH        : natural;
      MASTER_DATA_WIDTH : natural;
      MASTER_LEN_WIDTH  : natural;
      SLAVE_DATA_WIDTH  : natural;
      SLAVE_LEN_WIDTH   : natural;
      SLAVE_MAX_BURST   : natural;
      ENABLE_FIFO       : boolean
      );
    port (
      clk               : in  std_logic;
      reset_n           : in  std_logic;
      s_bus_wreq_valid  : in  std_logic;
      s_bus_wreq_ready  : out std_logic;
      s_bus_wreq_addr   : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      s_bus_wreq_len    : in  std_logic_vector(SLAVE_LEN_WIDTH-1 downto 0);
      s_bus_wdat_valid  : in  std_logic;
      s_bus_wdat_ready  : out std_logic;
      s_bus_wdat_data   : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      s_bus_wdat_strobe : in  std_logic_vector(SLAVE_DATA_WIDTH/8-1 downto 0);
      s_bus_wdat_last   : in  std_logic;
      m_axi_awaddr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      m_axi_awlen       : out std_logic_vector(MASTER_LEN_WIDTH-1 downto 0);
      m_axi_awvalid     : out std_logic;
      m_axi_awready     : in  std_logic;
      m_axi_awsize      : out std_logic_vector(2 downto 0);
      m_axi_wvalid      : out std_logic;
      m_axi_wready      : in  std_logic;
      m_axi_wdata       : out std_logic_vector(MASTER_DATA_WIDTH-1 downto 0);
      m_axi_wstrb       : out std_logic_vector(MASTER_DATA_WIDTH/8-1 downto 0);
      m_axi_wlast       : out std_logic
      );
  end component;

  component positdot_unit is
    generic (
      -- Host bus properties
      BUS_ADDR_WIDTH : natural := 64;
      BUS_DATA_WIDTH : natural := 512;

      BUS_LEN_WIDTH      : natural := BOTTOM_LEN_WIDTH;
      BUS_BURST_STEP_LEN : natural := BOTTOM_BURST_STEP_LEN;
      BUS_BURST_MAX_LEN  : natural := BOTTOM_BURST_MAX_LEN;

      REG_WIDTH : natural := 32

     -- (Generic defaults are set for SystemVerilog compatibility)
      );

    port (
      clk     : in std_logic;
      reset_n : in std_logic;

      control_reset : in  std_logic;
      control_start : in  std_logic;
      reset_start   : out std_logic;

      busy : out std_logic;
      done : out std_logic;

      -- Elements buffer addresses
      element1_off_hi, element1_off_lo     : in std_logic_vector(REG_WIDTH-1 downto 0);
      element1_posit_hi, element1_posit_lo : in std_logic_vector(REG_WIDTH-1 downto 0);
      -- Elements vector 2 buffer addresses
      element2_off_hi, element2_off_lo     : in std_logic_vector(REG_WIDTH-1 downto 0);
      element2_posit_hi, element2_posit_lo : in std_logic_vector(REG_WIDTH-1 downto 0);

      -- Result buffer address
      result_data_hi, result_data_lo : in std_logic_vector(REG_WIDTH-1 downto 0);

      -- Batch offset (to fetch from Arrow)
      batch_offset : in std_logic_vector(REG_WIDTH-1 downto 0);

      -- Result array
      result : out std_logic_vector(REG_WIDTH-1 downto 0);

      ---------------------------------------------------------------------------
      -- Master bus posit vector 1
      ---------------------------------------------------------------------------
      -- Read request channel
      bus_element1_req_addr  : out std_logic_vector(BUS_ADDR_WIDTH-1 downto 0);
      bus_element1_req_len   : out std_logic_vector(BUS_LEN_WIDTH-1 downto 0);
      bus_element1_req_valid : out std_logic;
      bus_element1_req_ready : in  std_logic;

      -- Read response channel
      bus_element1_rsp_data  : in  std_logic_vector(BUS_DATA_WIDTH-1 downto 0);
      bus_element1_rsp_resp  : in  std_logic_vector(1 downto 0);
      bus_element1_rsp_last  : in  std_logic;
      bus_element1_rsp_valid : in  std_logic;
      bus_element1_rsp_ready : out std_logic;

      ---------------------------------------------------------------------------
      -- Master bus posit vector 2
      ---------------------------------------------------------------------------
      -- Read request channel
      bus_element2_req_addr  : out std_logic_vector(BUS_ADDR_WIDTH-1 downto 0);
      bus_element2_req_len   : out std_logic_vector(BUS_LEN_WIDTH-1 downto 0);
      bus_element2_req_valid : out std_logic;
      bus_element2_req_ready : in  std_logic;

      -- Read response channel
      bus_element2_rsp_data  : in  std_logic_vector(BUS_DATA_WIDTH-1 downto 0);
      bus_element2_rsp_resp  : in  std_logic_vector(1 downto 0);
      bus_element2_rsp_last  : in  std_logic;
      bus_element2_rsp_valid : in  std_logic;
      bus_element2_rsp_ready : out std_logic;

      ---------------------------------------------------------------------------
      -- Master bus Result
      ---------------------------------------------------------------------------
      -- Write request channel
      bus_result_wreq_addr  : out std_logic_vector(BUS_ADDR_WIDTH-1 downto 0);
      bus_result_wreq_len   : out std_logic_vector(BUS_LEN_WIDTH-1 downto 0);
      bus_result_wreq_valid : out std_logic;
      bus_result_wreq_ready : in  std_logic;

      -- Write response channel
      bus_result_wdat_data   : out std_logic_vector(BUS_DATA_WIDTH-1 downto 0);
      bus_result_wdat_strobe : out std_logic_vector(BUS_DATA_WIDTH/8-1 downto 0);
      bus_result_wdat_last   : out std_logic;
      bus_result_wdat_valid  : out std_logic;
      bus_result_wdat_ready  : in  std_logic
      );
  end component;

  component element_fifo is
    port (
      rst       : in  std_logic;
      wr_clk    : in  std_logic;
      rd_clk    : in  std_logic;
      din       : in  std_logic_vector (255 downto 0);
      wr_en     : in  std_logic;
      rd_en     : in  std_logic;
      dout      : out std_logic_vector (31 downto 0);
      full      : out std_logic;
      wr_ack    : out std_logic;
      overflow  : out std_logic;
      empty     : out std_logic;
      valid     : out std_logic;
      underflow : out std_logic
      );
  end component;

  component accum_fifo_es2 is
    port (
      rst       : in  std_logic;
      wr_clk    : in  std_logic;
      rd_clk    : in  std_logic;
      din       : in  std_logic_vector (158 downto 0);
      wr_en     : in  std_logic;
      rd_en     : in  std_logic;
      dout      : out std_logic_vector (158 downto 0);
      full      : out std_logic;
      wr_ack    : out std_logic;
      overflow  : out std_logic;
      empty     : out std_logic;
      valid     : out std_logic;
      underflow : out std_logic
      );
  end component;

  component accum_fifo_es3 is
    port (
      rst       : in  std_logic;
      wr_clk    : in  std_logic;
      rd_clk    : in  std_logic;
      din       : in  std_logic_vector (264 downto 0);
      wr_en     : in  std_logic;
      rd_en     : in  std_logic;
      dout      : out std_logic_vector (264 downto 0);
      full      : out std_logic;
      wr_ack    : out std_logic;
      overflow  : out std_logic;
      empty     : out std_logic;
      valid     : out std_logic;
      underflow : out std_logic
      );
  end component;

  component output_fifo
    port (
      wr_clk    : in  std_logic;
      rd_clk    : in  std_logic;
      din       : in  std_logic_vector(31 downto 0);
      wr_en     : in  std_logic;
      rd_en     : in  std_logic;
      dout      : out std_logic_vector(31 downto 0);
      full      : out std_logic;
      wr_ack    : out std_logic;
      overflow  : out std_logic;
      empty     : out std_logic;
      valid     : out std_logic;
      underflow : out std_logic
      );
  end component;

end package;

package body arrow_positdot_pkg is
end package body arrow_positdot_pkg;
