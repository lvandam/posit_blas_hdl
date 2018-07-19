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
use ieee.std_logic_misc.all;

library work;
use work.Streams.all;
use work.Utils.all;
use work.Arrow.all;

use work.SimUtils.all;

use work.arrow_positdot_pkg.all;

-- In our programming model it is required to have an interface to a
-- memory (host memory, wether or not copied, as long as it retains the
-- Arrow format) and a slave interface for the memory mapped registers.
--
-- This unit uses AXI interconnect to do both, where the slave interface
-- is AXI4-lite and the master interface an AXI4 full interface. For high
-- throughput, the master interface should support bursts.

entity arrow_positdot is
  generic (
    -- Number of pair HMM units. Maximum 8
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
end arrow_positdot;

architecture arrow_positdot of arrow_positdot is
  signal reset : std_logic;

  -- Bottom buses
  constant BB : natural := 16;  -- Dependent on the number of ports on the BusArbiter

  -----------------------------------------------------------------------------
  -- Memory Mapped Input/Output
  -----------------------------------------------------------------------------
  -----------------------------------
  -- Fletcher registers
  ----------------------------------- Default registers
  --   1 status (uint64)          =  2
  --   1 control (uint64)         =  2
  --   1 return (uint64)          =  2
  ----------------------------------- Buffer addresses
  --   1 element1 offsets address    =  2
  --   1 element1 vbmp address       =  2
  --   1 element1 data address       =  2
  --   1 element2 offsets address    =  2
  --   1 element2 vbmp address        =  2
  --   1 element2 data address       =  2
  ----------------------------------- Buffer addresses
  --   8 result data address       =  16
  ----------------------------------- Custom registers (arguments)
  --   8 batch offsets                   =  8
  -----------------------------------
  -- Total:                          42 regs
  constant NUM_FLETCHER_REGS : natural := 42;

  -- The LSB index in the slave address
  constant SLV_ADDR_LSB : natural := log2floor(SLV_BUS_DATA_WIDTH / 4) - 1;

  -- The MSB index in the slave address
  constant SLV_ADDR_MSB : natural := SLV_ADDR_LSB + log2floor(NUM_FLETCHER_REGS);

  -- Fletcher register offsets
  constant REG_STATUS_HI : natural := 0;
  constant REG_STATUS_LO : natural := 1;

  -- Control register offsets
  constant REG_CONTROL_HI : natural := 2;
  constant REG_CONTROL_LO : natural := 3;

  -- Return register
  constant REG_RETURN_HI : natural := 4;
  constant REG_RETURN_LO : natural := 5;

  -- Posit Element Vector 1 Index/Offset buffer address
  constant REG_ELEMENT1_OFF_ADDR_HI : natural := 6;
  constant REG_ELEMENT1_OFF_ADDR_LO : natural := 7;

  -- Posit Element Vector 1 valid bitmap
  constant REG_ELEMENT1_POSIT_VBMP_HI : natural := 8;
  constant REG_ELEMENT1_POSIT_VBMP_LO : natural := 9;

  -- Posit Element Vector 1 Data buffer address
  constant REG_ELEMENT1_POSIT_ADDR_HI : natural := 10;
  constant REG_ELEMENT1_POSIT_ADDR_LO : natural := 11;

  -- Posit Element Vector 2 Index/Offset buffer address
  constant REG_ELEMENT2_OFF_ADDR_HI : natural := 12;
  constant REG_ELEMENT2_OFF_ADDR_LO : natural := 13;

  -- Posit Element Vector 2 valid bitmap
  constant REG_ELEMENT2_POSIT_VBMP_HI : natural := 14;
  constant REG_ELEMENT2_POSIT_VBMP_LO : natural := 15;

  -- Posit Element Vector 2 Data buffer address
  constant REG_ELEMENT2_POSIT_ADDR_HI : natural := 16;
  constant REG_ELEMENT2_POSIT_ADDR_LO : natural := 17;

  -- Result data buffer address
  constant REG_RESULT_DATA_ADDR_HI : natural := 18;
  constant REG_RESULT_DATA_ADDR_LO : natural := 19;

  -- 20, 21

  -- 22, 23

  -- 24, 25

  -- 26, 27

  -- 28, 29

  -- 30, 31

  -- 32, 33

  -- Batch offsets
  constant REG_BATCH_OFFSET : natural := 34;

  -- The offsets of the bits to signal busy and done for each of the units
  constant STATUS_BUSY_OFFSET : natural := 0;
  constant STATUS_DONE_OFFSET : natural := CORES;

  -- The offsets of the bits to signal start and reset to each of the units
  constant CONTROL_START_OFFSET : natural := 0;
  constant CONTROL_RESET_OFFSET : natural := CORES;

  -- Memory mapped register file
  type mm_regs_t is array (0 to NUM_FLETCHER_REGS - 1) of std_logic_vector(SLV_BUS_DATA_WIDTH - 1 downto 0);
  signal mm_regs : mm_regs_t;

  -- Helper signals to do handshaking on the slave port
  signal read_address    : natural range 0 to NUM_FLETCHER_REGS - 1;
  signal write_valid     : std_logic;
  signal read_valid      : std_logic := '0';
  signal write_processed : std_logic;

  -----------------------------------------------------------------------------
  -- AXI Interconnect Master Ports
  -----------------------------------------------------------------------------
  type bus_element_array_t is array (0 to CORES-1) of bus_bottom_read_t;
  signal bus_element1_array, bus_element2_array : bus_element_array_t;

  type bus_write_array_t is array (0 to CORES-1) of bus_bottom_write_t;
  signal bus_result_array : bus_write_array_t;

  type axi_mid_array_t is array (0 to BB-1) of axi_mid_t;
  signal axi_mid_array : axi_mid_array_t;

  signal axi_top : axi_top_t;

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  type reg_array_t is array (0 to CORES-1) of std_logic_vector(31 downto 0);

  -- Element buffer addresses
  signal reg_array_element1_off_hi, reg_array_element1_off_lo     : reg_array_t;
  signal reg_array_element1_posit_hi, reg_array_element1_posit_lo : reg_array_t;

  signal reg_array_element2_off_hi, reg_array_element2_off_lo     : reg_array_t;
  signal reg_array_element2_posit_hi, reg_array_element2_posit_lo : reg_array_t;

  -- Result buffer address
  signal reg_array_result_data_hi, reg_array_result_data_lo : reg_array_t;

  -- Batch offset (to fetch from Arrow)
  signal reg_array_batch_offset : reg_array_t;

  signal bit_array_control_reset : std_logic_vector(CORES-1 downto 0);
  signal bit_array_control_start : std_logic_vector(CORES-1 downto 0);
  signal bit_array_reset_start   : std_logic_vector(CORES-1 downto 0);
  signal bit_array_busy          : std_logic_vector(CORES-1 downto 0);
  signal bit_array_done          : std_logic_vector(CORES-1 downto 0);

begin
  reset <= '1' when reset_n = '0' else '0';

  -----------------------------------------------------------------------------
  -- Memory Mapped Slave Registers
  -----------------------------------------------------------------------------
  write_valid <= s_axi_awvalid and s_axi_wvalid and not write_processed;

  s_axi_awready <= write_valid;
  s_axi_wready  <= write_valid;
  s_axi_bresp   <= "00";                -- Always OK
  s_axi_bvalid  <= write_processed;

  s_axi_arready <= not read_valid;

  -- Mux for reading
  -- Might want to insert a reg slice before getting it to the ColumnReaders
  -- and UserCore
  s_axi_rdata  <= mm_regs(read_address);
  s_axi_rvalid <= read_valid;
  s_axi_rresp  <= "00";                 -- Always OK

  -- Reads
  read_from_regs : process(clk) is
    variable address : natural range 0 to NUM_FLETCHER_REGS-1;
  begin
    address := int(s_axi_araddr(SLV_ADDR_MSB downto SLV_ADDR_LSB));

    if rising_edge(clk) then
      if reset_n = '0' then
        read_valid <= '0';
      else
        if s_axi_arvalid = '1' and read_valid = '0' then
          dumpStdOut("Read request from MMIO: " & integer'image(address) & " value " & integer'image(int(mm_regs(address))));
          read_address <= address;
          read_valid   <= '1';
        elsif s_axi_rready = '1' then
          read_valid <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Writes

  -- TODO: For registers that are split up over two addresses, this is not
  -- very pretty. There should probably be some synchronization mechanism
  -- to only apply the write after both HI and LO addresses have been
  -- written.
  -- Also we don't care about byte enables at the moment.
  write_to_regs : process(clk) is
    variable address : natural range 0 to NUM_FLETCHER_REGS;
  begin

    address := int(s_axi_awaddr(SLV_ADDR_MSB downto SLV_ADDR_LSB));

    if rising_edge(clk) then
      if write_valid = '1' then
        dumpStdOut("Write to MMIO: " & integer'image(address));

        case address is
          -- Read only addresses do nothing
          when REG_STATUS_HI =>         -- no-op
          when REG_STATUS_LO =>         -- no-op
          when REG_RETURN_HI =>         -- no-op
          when REG_RETURN_LO =>         -- no-op

          -- All others are writeable:
          when others =>
            mm_regs(address) <= s_axi_wdata;
        end case;
      else
        -- Control register is also resettable by individual units
        for I in 0 to CORES-1 loop
          if bit_array_reset_start(I) = '1' then
            mm_regs(REG_CONTROL_LO)(CONTROL_START_OFFSET + I) <= '0';
          end if;
        end loop;
      end if;

      -- Read only register values:

      -- Status registers
      mm_regs(REG_STATUS_HI) <= (others => '0');

      if CORES /= 16 then
        mm_regs(REG_STATUS_LO)(SLV_BUS_DATA_WIDTH-1 downto STATUS_DONE_OFFSET + CORES) <= (others => '0');
      end if;
      mm_regs(REG_STATUS_LO)(STATUS_BUSY_OFFSET + CORES - 1 downto STATUS_BUSY_OFFSET) <= bit_array_busy;
      mm_regs(REG_STATUS_LO)(STATUS_DONE_OFFSET + CORES - 1 downto STATUS_DONE_OFFSET) <= bit_array_done;

      -- Return registers
      mm_regs(REG_RETURN_HI) <= (others => '0');
      mm_regs(REG_RETURN_LO) <= (others => '1');

      if reset_n = '0' then
        mm_regs(REG_CONTROL_LO) <= (others => '0');
        mm_regs(REG_CONTROL_HI) <= (others => '0');
      end if;
    end if;
  end process;

  -- Write response
  write_resp_proc : process(clk) is
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        write_processed <= '0';
      else
        if write_valid = '1' then
          write_processed <= '1';
        elsif s_axi_bready = '1' then
          write_processed <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Some registers between paths to units
  reg_settings : process(clk)
  begin
    if rising_edge(clk) then
      -- Control bits
      bit_array_control_start <= mm_regs(REG_CONTROL_LO)(CONTROL_START_OFFSET + CORES - 1 downto CONTROL_START_OFFSET);
      bit_array_control_reset <= mm_regs(REG_CONTROL_LO)(CONTROL_RESET_OFFSET + CORES - 1 downto CONTROL_RESET_OFFSET);

      -- Registers
      reg_gen : for I in 0 to CORES-1 loop
        -- Global: Elements
        reg_array_element1_off_hi (I) <= mm_regs(REG_ELEMENT1_OFF_ADDR_HI);
        reg_array_element1_off_lo (I) <= mm_regs(REG_ELEMENT1_OFF_ADDR_LO);

        reg_array_element1_posit_hi (I) <= mm_regs(REG_ELEMENT1_POSIT_ADDR_HI);
        reg_array_element1_posit_lo (I) <= mm_regs(REG_ELEMENT1_POSIT_ADDR_LO);

        reg_array_element2_off_hi (I) <= mm_regs(REG_ELEMENT2_OFF_ADDR_HI);
        reg_array_element2_off_lo (I) <= mm_regs(REG_ELEMENT2_OFF_ADDR_LO);

        reg_array_element2_posit_hi (I) <= mm_regs(REG_ELEMENT2_POSIT_ADDR_HI);
        reg_array_element2_posit_lo (I) <= mm_regs(REG_ELEMENT2_POSIT_ADDR_LO);

        reg_array_batch_offset (I) <= mm_regs(REG_BATCH_OFFSET + I);

        -- Global: Result
        reg_array_result_data_hi (I) <= mm_regs(REG_RESULT_DATA_ADDR_HI + (I * 2));
        reg_array_result_data_lo (I) <= mm_regs(REG_RESULT_DATA_ADDR_LO + (I * 2));
      end loop;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Master
  -----------------------------------------------------------------------------
  -- Read address channel
  axi_top.arready <= m_axi_arready;
  m_axi_arvalid   <= axi_top.arvalid;
  m_axi_araddr    <= axi_top.araddr;
  m_axi_arlen     <= axi_top.arlen;
  m_axi_arsize    <= "110";             -- 6 for 2^6*8 bits = 512 bits

  -- Read data channel
  m_axi_rready   <= axi_top.rready;
  axi_top.rvalid <= m_axi_rvalid;
  axi_top.rdata  <= m_axi_rdata;
  axi_top.rresp  <= m_axi_rresp;
  axi_top.rlast  <= m_axi_rlast;

  -- Write address channel
  axi_top.awready <= m_axi_awready;
  axi_top.wready  <= m_axi_wready;
  m_axi_awvalid   <= axi_top.awvalid;
  m_axi_awaddr    <= axi_top.awaddr;
  m_axi_awlen     <= axi_top.awlen;
  m_axi_awsize    <= axi_top.awsize;

  -- Write data channel
  m_axi_wvalid <= axi_top.wvalid;
  m_axi_wdata  <= axi_top.wdata;
  m_axi_wlast  <= axi_top.wlast;
  m_axi_wstrb  <= axi_top.wstrb;

  -----------------------------------------------------------------------------
  -- Bottom layer
  -----------------------------------------------------------------------------
  positdot_gen : for I in 0 to CORES-1 generate
    -- Convert axi read address channel and read response channel
    -- Scales "len" and "size" according to the master data width
    -- and converts the Fletcher bus "len" to AXI bus "len"
    read_converter_element1_inst : axi_read_converter generic map (
      ADDR_WIDTH        => BUS_ADDR_WIDTH,
      ID_WIDTH          => 1,
      MASTER_DATA_WIDTH => BUS_DATA_WIDTH,
      MASTER_LEN_WIDTH  => 8,
      SLAVE_DATA_WIDTH  => BUS_DATA_WIDTH,
      SLAVE_LEN_WIDTH   => BOTTOM_LEN_WIDTH,
      SLAVE_MAX_BURST   => BOTTOM_BURST_MAX_LEN,
      ENABLE_FIFO       => false
      )
      port map (
        clk             => clk,
        reset_n         => reset_n,
        s_bus_req_addr  => bus_element1_array(I).req_addr,
        s_bus_req_len   => bus_element1_array(I).req_len,
        s_bus_req_valid => bus_element1_array(I).req_valid,
        s_bus_req_ready => bus_element1_array(I).req_ready,
        s_bus_rsp_data  => bus_element1_array(I).rsp_data,
        s_bus_rsp_last  => bus_element1_array(I).rsp_last,
        s_bus_rsp_valid => bus_element1_array(I).rsp_valid,
        s_bus_rsp_ready => bus_element1_array(I).rsp_ready,

        m_axi_araddr  => axi_mid_array(I*3).araddr,
        m_axi_arlen   => axi_mid_array(I*3).arlen,
        m_axi_arvalid => axi_mid_array(I*3).arvalid,
        m_axi_arready => axi_mid_array(I*3).arready,
        m_axi_arsize  => axi_mid_array(I*3).arsize,
        m_axi_rdata   => axi_mid_array(I*3).rdata,
        m_axi_rlast   => axi_mid_array(I*3).rlast,
        m_axi_rvalid  => axi_mid_array(I*3).rvalid,
        m_axi_rready  => axi_mid_array(I*3).rready
        );

    read_converter_element2_inst : axi_read_converter generic map (
      ADDR_WIDTH        => BUS_ADDR_WIDTH,
      ID_WIDTH          => 1,
      MASTER_DATA_WIDTH => BUS_DATA_WIDTH,
      MASTER_LEN_WIDTH  => 8,
      SLAVE_DATA_WIDTH  => BUS_DATA_WIDTH,
      SLAVE_LEN_WIDTH   => BOTTOM_LEN_WIDTH,
      SLAVE_MAX_BURST   => BOTTOM_BURST_MAX_LEN,
      ENABLE_FIFO       => false
      )
      port map (
        clk             => clk,
        reset_n         => reset_n,
        s_bus_req_addr  => bus_element2_array(I).req_addr,
        s_bus_req_len   => bus_element2_array(I).req_len,
        s_bus_req_valid => bus_element2_array(I).req_valid,
        s_bus_req_ready => bus_element2_array(I).req_ready,
        s_bus_rsp_data  => bus_element2_array(I).rsp_data,
        s_bus_rsp_last  => bus_element2_array(I).rsp_last,
        s_bus_rsp_valid => bus_element2_array(I).rsp_valid,
        s_bus_rsp_ready => bus_element2_array(I).rsp_ready,

        m_axi_araddr  => axi_mid_array(I*3+1).araddr,
        m_axi_arlen   => axi_mid_array(I*3+1).arlen,
        m_axi_arvalid => axi_mid_array(I*3+1).arvalid,
        m_axi_arready => axi_mid_array(I*3+1).arready,
        m_axi_arsize  => axi_mid_array(I*3+1).arsize,
        m_axi_rdata   => axi_mid_array(I*3+1).rdata,
        m_axi_rlast   => axi_mid_array(I*3+1).rlast,
        m_axi_rvalid  => axi_mid_array(I*3+1).rvalid,
        m_axi_rready  => axi_mid_array(I*3+1).rready
        );

    write_converter_inst : axi_write_converter
      generic map (
        ADDR_WIDTH        => BUS_ADDR_WIDTH,
        MASTER_DATA_WIDTH => BUS_DATA_WIDTH,
        MASTER_LEN_WIDTH  => 8,
        SLAVE_DATA_WIDTH  => BUS_DATA_WIDTH,
        SLAVE_LEN_WIDTH   => BOTTOM_LEN_WIDTH,
        SLAVE_MAX_BURST   => BOTTOM_BURST_MAX_LEN,
        ENABLE_FIFO       => false
        )
      port map (
        clk     => clk,
        reset_n => reset_n,

        s_bus_wreq_valid => bus_result_array(I).wreq_valid,
        s_bus_wreq_ready => bus_result_array(I).wreq_ready,
        s_bus_wreq_addr  => bus_result_array(I).wreq_addr,
        s_bus_wreq_len   => bus_result_array(I).wreq_len,

        s_bus_wdat_valid  => bus_result_array(I).wdat_valid,
        s_bus_wdat_ready  => bus_result_array(I).wdat_ready,
        s_bus_wdat_data   => bus_result_array(I).wdat_data,
        s_bus_wdat_strobe => bus_result_array(I).wdat_strobe,
        s_bus_wdat_last   => bus_result_array(I).wdat_last,

        m_axi_awaddr  => axi_mid_array(I*3+2).awaddr,
        m_axi_awlen   => axi_mid_array(I*3+2).awlen,
        m_axi_awvalid => axi_mid_array(I*3+2).awvalid,
        m_axi_awready => axi_mid_array(I*3+2).awready,
        m_axi_awsize  => axi_mid_array(I*3+2).awsize,

        m_axi_wvalid => axi_mid_array(I*3+2).wvalid,
        m_axi_wready => axi_mid_array(I*3+2).wready,
        m_axi_wdata  => axi_mid_array(I*3+2).wdata,
        m_axi_wstrb  => axi_mid_array(I*3+2).wstrb,
        m_axi_wlast  => axi_mid_array(I*3+2).wlast
        );

    -- Posit dot product unit
    positdot_inst : positdot_unit generic map (
      BUS_ADDR_WIDTH     => BUS_ADDR_WIDTH,
      BUS_DATA_WIDTH     => BOTTOM_DATA_WIDTH,
      BUS_LEN_WIDTH      => BOTTOM_LEN_WIDTH,
      BUS_BURST_STEP_LEN => BOTTOM_BURST_STEP_LEN,
      BUS_BURST_MAX_LEN  => BOTTOM_BURST_MAX_LEN,
      REG_WIDTH          => 32
      ) port map (
        clk     => clk,
        reset_n => reset_n,

        control_reset => bit_array_control_reset(I),
        control_start => bit_array_control_start(I),
        reset_start   => bit_array_reset_start (I),
        busy          => bit_array_busy (I),
        done          => bit_array_done (I),

        -- Elements buffer addresses
        element1_off_hi => reg_array_element1_off_hi (I),
        element1_off_lo => reg_array_element1_off_lo (I),

        element2_off_hi => reg_array_element2_off_hi (I),
        element2_off_lo => reg_array_element2_off_lo (I),

        element1_posit_hi => reg_array_element1_posit_hi (I),
        element1_posit_lo => reg_array_element1_posit_lo (I),

        element2_posit_hi => reg_array_element2_posit_hi (I),
        element2_posit_lo => reg_array_element2_posit_lo (I),

        -- Results buffer addresses
        result_data_hi => reg_array_result_data_hi (I),
        result_data_lo => reg_array_result_data_lo (I),

        -- Batch offset (to fetch from Arrow)
        batch_offset => reg_array_batch_offset (I),

        ---------------------------------------------------------------------------
        -- Master bus Element vector 1
        ---------------------------------------------------------------------------
        -- Read request channel
        bus_element1_req_addr  => bus_element1_array(I).req_addr,
        bus_element1_req_len   => bus_element1_array(I).req_len,
        bus_element1_req_valid => bus_element1_array(I).req_valid,
        bus_element1_req_ready => bus_element1_array(I).req_ready,

        -- Read response channel
        bus_element1_rsp_data  => bus_element1_array(I).rsp_data,
        bus_element1_rsp_resp  => bus_element1_array(I).rsp_resp,
        bus_element1_rsp_last  => bus_element1_array(I).rsp_last,
        bus_element1_rsp_valid => bus_element1_array(I).rsp_valid,
        bus_element1_rsp_ready => bus_element1_array(I).rsp_ready,

        ---------------------------------------------------------------------------
        -- Master bus Element vector 2
        ---------------------------------------------------------------------------
        -- Read request channel
        bus_element2_req_addr  => bus_element2_array(I).req_addr,
        bus_element2_req_len   => bus_element2_array(I).req_len,
        bus_element2_req_valid => bus_element2_array(I).req_valid,
        bus_element2_req_ready => bus_element2_array(I).req_ready,

        -- Read response channel
        bus_element2_rsp_data  => bus_element2_array(I).rsp_data,
        bus_element2_rsp_resp  => bus_element2_array(I).rsp_resp,
        bus_element2_rsp_last  => bus_element2_array(I).rsp_last,
        bus_element2_rsp_valid => bus_element2_array(I).rsp_valid,
        bus_element2_rsp_ready => bus_element2_array(I).rsp_ready,

        ---------------------------------------------------------------------------
        -- Master bus Result
        ---------------------------------------------------------------------------
        -- Read request channel
        bus_result_wreq_addr  => bus_result_array(I).wreq_addr,
        bus_result_wreq_len   => bus_result_array(I).wreq_len,
        bus_result_wreq_valid => bus_result_array(I).wreq_valid,
        bus_result_wreq_ready => bus_result_array(I).wreq_ready,

        -- Read response channel
        bus_result_wdat_data   => bus_result_array(I).wdat_data,
        bus_result_wdat_strobe => bus_result_array(I).wdat_strobe,
        bus_result_wdat_last   => bus_result_array(I).wdat_last,
        bus_result_wdat_valid  => bus_result_array(I).wdat_valid,
        bus_result_wdat_ready  => bus_result_array(I).wdat_ready
        );
  end generate;

  -- Tie off unused ports, if any
  unused_gen : for I in CORES * 3 to BB - 1 generate
    axi_mid_array(I).araddr  <= (others => '0');
    axi_mid_array(I).arlen   <= (others => '0');
    axi_mid_array(I).arvalid <= '0';
    axi_mid_array(I).arsize  <= (others => '0');
    axi_mid_array(I).rready  <= '0';
    axi_mid_array(I).aclk    <= clk;

    axi_mid_array(I).awaddr  <= (others => '0');
    axi_mid_array(I).awlen   <= (others => '0');
    axi_mid_array(I).awvalid <= '0';
    axi_mid_array(I).awready <= '0';
    axi_mid_array(I).wvalid  <= '0';
    axi_mid_array(I).wdata   <= (others => '0');
    axi_mid_array(I).wstrb   <= (others => '0');
    axi_mid_array(I).wlast   <= '0';
    axi_mid_array(I).aclk    <= clk;
  end generate;

  mid_interconnect : BusArbiter generic map (
    BUS_ADDR_WIDTH  => BUS_ADDR_WIDTH,
    BUS_LEN_WIDTH   => 8,
    BUS_DATA_WIDTH  => BUS_DATA_WIDTH,
    NUM_MASTERS     => CORES * 2,
    ARB_METHOD      => "ROUND-ROBIN",
    MAX_OUTSTANDING => 32,
    RAM_CONFIG      => "",
    REQ_IN_SLICES   => false,
    REQ_OUT_SLICE   => false,
    RESP_IN_SLICE   => false,
    RESP_OUT_SLICES => false
    )
    port map (
      clk   => clk,
      reset => reset,

      slv_req_valid  => axi_top.arvalid,
      slv_req_ready  => axi_top.arready,
      slv_req_addr   => axi_top.araddr,
      slv_req_len    => axi_top.arlen,
      slv_resp_valid => axi_top.rvalid,
      slv_resp_ready => axi_top.rready,
      slv_resp_data  => axi_top.rdata,
      slv_resp_last  => axi_top.rlast,

      bm0_req_valid  => axi_mid_array(0).arvalid,
      bm0_req_ready  => axi_mid_array(0).arready,
      bm0_req_addr   => axi_mid_array(0).araddr,
      bm0_req_len    => axi_mid_array(0).arlen,
      bm0_resp_valid => axi_mid_array(0).rvalid,
      bm0_resp_ready => axi_mid_array(0).rready,
      bm0_resp_data  => axi_mid_array(0).rdata,
      bm0_resp_last  => axi_mid_array(0).rlast,

      bm1_req_valid  => axi_mid_array(1).arvalid,
      bm1_req_ready  => axi_mid_array(1).arready,
      bm1_req_addr   => axi_mid_array(1).araddr,
      bm1_req_len    => axi_mid_array(1).arlen,
      bm1_resp_valid => axi_mid_array(1).rvalid,
      bm1_resp_ready => axi_mid_array(1).rready,
      bm1_resp_data  => axi_mid_array(1).rdata,
      bm1_resp_last  => axi_mid_array(1).rlast,

      bm2_req_valid  => open,
      bm2_req_ready  => open,
      bm2_req_addr   => open,
      bm2_req_len    => open,
      bm2_resp_valid => open,
      bm2_resp_ready => open,
      bm2_resp_data  => open,
      bm2_resp_last  => open,

      bm3_req_valid  => open,
      bm3_req_ready  => open,
      bm3_req_addr   => open,
      bm3_req_len    => open,
      bm3_resp_valid => open,
      bm3_resp_ready => open,
      bm3_resp_data  => open,
      bm3_resp_last  => open,

      bm4_req_valid  => open,
      bm4_req_ready  => open,
      bm4_req_addr   => open,
      bm4_req_len    => open,
      bm4_resp_valid => open,
      bm4_resp_ready => open,
      bm4_resp_data  => open,
      bm4_resp_last  => open,

      bm5_req_valid  => open,
      bm5_req_ready  => open,
      bm5_req_addr   => open,
      bm5_req_len    => open,
      bm5_resp_valid => open,
      bm5_resp_ready => open,
      bm5_resp_data  => open,
      bm5_resp_last  => open,

      bm6_req_valid  => open,
      bm6_req_ready  => open,
      bm6_req_addr   => open,
      bm6_req_len    => open,
      bm6_resp_valid => open,
      bm6_resp_ready => open,
      bm6_resp_data  => open,
      bm6_resp_last  => open,

      bm7_req_valid  => open,
      bm7_req_ready  => open,
      bm7_req_addr   => open,
      bm7_req_len    => open,
      bm7_resp_valid => open,
      bm7_resp_ready => open,
      bm7_resp_data  => open,
      bm7_resp_last  => open,

      bm8_req_valid  => open,
      bm8_req_ready  => open,
      bm8_req_addr   => open,
      bm8_req_len    => open,
      bm8_resp_valid => open,
      bm8_resp_ready => open,
      bm8_resp_data  => open,
      bm8_resp_last  => open,

      bm9_req_valid  => open,
      bm9_req_ready  => open,
      bm9_req_addr   => open,
      bm9_req_len    => open,
      bm9_resp_valid => open,
      bm9_resp_ready => open,
      bm9_resp_data  => open,
      bm9_resp_last  => open,

      bm10_req_valid  => open,
      bm10_req_ready  => open,
      bm10_req_addr   => open,
      bm10_req_len    => open,
      bm10_resp_valid => open,
      bm10_resp_ready => open,
      bm10_resp_data  => open,
      bm10_resp_last  => open,

      bm11_req_valid  => open,
      bm11_req_ready  => open,
      bm11_req_addr   => open,
      bm11_req_len    => open,
      bm11_resp_valid => open,
      bm11_resp_ready => open,
      bm11_resp_data  => open,
      bm11_resp_last  => open,

      bm12_req_valid  => open,
      bm12_req_ready  => open,
      bm12_req_addr   => open,
      bm12_req_len    => open,
      bm12_resp_valid => open,
      bm12_resp_ready => open,
      bm12_resp_data  => open,
      bm12_resp_last  => open,

      bm13_req_valid  => open,
      bm13_req_ready  => open,
      bm13_req_addr   => open,
      bm13_req_len    => open,
      bm13_resp_valid => open,
      bm13_resp_ready => open,
      bm13_resp_data  => open,
      bm13_resp_last  => open,

      bm14_req_valid  => open,
      bm14_req_ready  => open,
      bm14_req_addr   => open,
      bm14_req_len    => open,
      bm14_resp_valid => open,
      bm14_resp_ready => open,
      bm14_resp_data  => open,
      bm14_resp_last  => open,

      bm15_req_valid  => open,
      bm15_req_ready  => open,
      bm15_req_addr   => open,
      bm15_req_len    => open,
      bm15_resp_valid => open,
      bm15_resp_ready => open,
      bm15_resp_data  => open,
      bm15_resp_last  => open
      );

  mid_interconnect_write : BusWriteArbiter generic map (
    BUS_ADDR_WIDTH   => BUS_ADDR_WIDTH,
    BUS_LEN_WIDTH    => 8,
    BUS_DATA_WIDTH   => BUS_DATA_WIDTH,
    BUS_STROBE_WIDTH => BUS_DATA_WIDTH/8,
    NUM_SLAVES       => CORES,
    ARB_METHOD       => "ROUND-ROBIN",
    MAX_OUTSTANDING  => 8,
    RAM_CONFIG       => "",
    REQ_IN_SLICES    => false,
    REQ_OUT_SLICE    => false,
    DAT_IN_SLICE     => false,
    DAT_OUT_SLICE    => false
    )
    port map (
      clk   => clk,
      reset => reset,

      mst_wreq_valid  => axi_top.awvalid,
      mst_wreq_ready  => axi_top.awready,
      mst_wreq_addr   => axi_top.awaddr,
      mst_wreq_len    => axi_top.awlen,
      mst_wdat_valid  => axi_top.wvalid,
      mst_wdat_ready  => axi_top.wready,
      mst_wdat_data   => axi_top.wdata,
      mst_wdat_strobe => axi_top.wstrb,
      mst_wdat_last   => axi_top.wlast,

      bs00_wreq_valid  => axi_mid_array(2).awvalid,
      bs00_wreq_ready  => axi_mid_array(2).awready,
      bs00_wreq_addr   => axi_mid_array(2).awaddr,
      bs00_wreq_len    => axi_mid_array(2).awlen,
      bs00_wdat_valid  => axi_mid_array(2).wvalid,
      bs00_wdat_ready  => axi_mid_array(2).wready,
      bs00_wdat_data   => axi_mid_array(2).wdata,
      bs00_wdat_strobe => axi_mid_array(2).wstrb,
      bs00_wdat_last   => axi_mid_array(2).wlast,

      bs01_wreq_valid  => open,
      bs01_wreq_ready  => open,
      bs01_wreq_addr   => open,
      bs01_wreq_len    => open,
      bs01_wdat_valid  => open,
      bs01_wdat_ready  => open,
      bs01_wdat_data   => open,
      bs01_wdat_strobe => open,
      bs01_wdat_last   => open,

      bs02_wreq_valid  => open,
      bs02_wreq_ready  => open,
      bs02_wreq_addr   => open,
      bs02_wreq_len    => open,
      bs02_wdat_valid  => open,
      bs02_wdat_ready  => open,
      bs02_wdat_data   => open,
      bs02_wdat_strobe => open,
      bs02_wdat_last   => open,

      bs03_wreq_valid  => open,
      bs03_wreq_ready  => open,
      bs03_wreq_addr   => open,
      bs03_wreq_len    => open,
      bs03_wdat_valid  => open,
      bs03_wdat_ready  => open,
      bs03_wdat_data   => open,
      bs03_wdat_strobe => open,
      bs03_wdat_last   => open,

      bs04_wreq_valid  => open,
      bs04_wreq_ready  => open,
      bs04_wreq_addr   => open,
      bs04_wreq_len    => open,
      bs04_wdat_valid  => open,
      bs04_wdat_ready  => open,
      bs04_wdat_data   => open,
      bs04_wdat_strobe => open,
      bs04_wdat_last   => open,

      bs05_wreq_valid  => open,
      bs05_wreq_ready  => open,
      bs05_wreq_addr   => open,
      bs05_wreq_len    => open,
      bs05_wdat_valid  => open,
      bs05_wdat_ready  => open,
      bs05_wdat_data   => open,
      bs05_wdat_strobe => open,
      bs05_wdat_last   => open,

      bs06_wreq_valid  => open,
      bs06_wreq_ready  => open,
      bs06_wreq_addr   => open,
      bs06_wreq_len    => open,
      bs06_wdat_valid  => open,
      bs06_wdat_ready  => open,
      bs06_wdat_data   => open,
      bs06_wdat_strobe => open,
      bs06_wdat_last   => open,

      bs07_wreq_valid  => open,
      bs07_wreq_ready  => open,
      bs07_wreq_addr   => open,
      bs07_wreq_len    => open,
      bs07_wdat_valid  => open,
      bs07_wdat_ready  => open,
      bs07_wdat_data   => open,
      bs07_wdat_strobe => open,
      bs07_wdat_last   => open,

      bs08_wreq_valid  => open,
      bs08_wreq_ready  => open,
      bs08_wreq_addr   => open,
      bs08_wreq_len    => open,
      bs08_wdat_valid  => open,
      bs08_wdat_ready  => open,
      bs08_wdat_data   => open,
      bs08_wdat_strobe => open,
      bs08_wdat_last   => open,

      bs09_wreq_valid  => open,
      bs09_wreq_ready  => open,
      bs09_wreq_addr   => open,
      bs09_wreq_len    => open,
      bs09_wdat_valid  => open,
      bs09_wdat_ready  => open,
      bs09_wdat_data   => open,
      bs09_wdat_strobe => open,
      bs09_wdat_last   => open,

      bs10_wreq_valid  => open,
      bs10_wreq_ready  => open,
      bs10_wreq_addr   => open,
      bs10_wreq_len    => open,
      bs10_wdat_valid  => open,
      bs10_wdat_ready  => open,
      bs10_wdat_data   => open,
      bs10_wdat_strobe => open,
      bs10_wdat_last   => open,

      bs11_wreq_valid  => open,
      bs11_wreq_ready  => open,
      bs11_wreq_addr   => open,
      bs11_wreq_len    => open,
      bs11_wdat_valid  => open,
      bs11_wdat_ready  => open,
      bs11_wdat_data   => open,
      bs11_wdat_strobe => open,
      bs11_wdat_last   => open,

      bs12_wreq_valid  => open,
      bs12_wreq_ready  => open,
      bs12_wreq_addr   => open,
      bs12_wreq_len    => open,
      bs12_wdat_valid  => open,
      bs12_wdat_ready  => open,
      bs12_wdat_data   => open,
      bs12_wdat_strobe => open,
      bs12_wdat_last   => open,

      bs13_wreq_valid  => open,
      bs13_wreq_ready  => open,
      bs13_wreq_addr   => open,
      bs13_wreq_len    => open,
      bs13_wdat_valid  => open,
      bs13_wdat_ready  => open,
      bs13_wdat_data   => open,
      bs13_wdat_strobe => open,
      bs13_wdat_last   => open,

      bs14_wreq_valid  => open,
      bs14_wreq_ready  => open,
      bs14_wreq_addr   => open,
      bs14_wreq_len    => open,
      bs14_wdat_valid  => open,
      bs14_wdat_ready  => open,
      bs14_wdat_data   => open,
      bs14_wdat_strobe => open,
      bs14_wdat_last   => open,

      bs15_wreq_valid  => open,
      bs15_wreq_ready  => open,
      bs15_wreq_addr   => open,
      bs15_wreq_len    => open,
      bs15_wdat_valid  => open,
      bs15_wdat_ready  => open,
      bs15_wdat_data   => open,
      bs15_wdat_strobe => open,
      bs15_wdat_last   => open
      );


end arrow_positdot;
