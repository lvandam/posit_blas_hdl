library ieee, std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.Streams.all;
use work.Utils.all;
use work.Arrow.all;
use work.SimUtils.all;

use work.arrow_positdot_pkg.all;
use work.cu_snap_package.all;
use work.posit_common.all;
use work.posit_package.all;

entity positdot_unit is
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
end positdot_unit;

architecture positdot_unit of positdot_unit is
  constant ADD_CYCLES   : natural := 4;
  constant MUL_CYCLES   : natural := 4;
  constant ACCUM_CYCLES : natural := 16;

  signal reset : std_logic;

  -- Register on all ports to ease timing
  signal r_control_reset : std_logic;
  signal r_control_start : std_logic;
  signal r_reset_start   : std_logic;
  signal r_busy          : std_logic;
  signal r_done          : std_logic;

  signal r_element1_off_hi                        : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal r_element1_off_lo                        : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal r_element1_posit_hi, r_element1_posit_lo : std_logic_vector(REG_WIDTH - 1 downto 0);

  signal r_element2_off_hi                        : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal r_element2_off_lo                        : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal r_element2_posit_hi, r_element2_posit_lo : std_logic_vector(REG_WIDTH - 1 downto 0);

  signal r_result_data_hi, r_result_data_lo : std_logic_vector(REG_WIDTH - 1 downto 0);

  signal r_batch_offset : std_logic_vector(REG_WIDTH - 1 downto 0);  -- To retrieve the correct data from Arrow columns

  -----------------------------------------------------------------------------
  -- ELEMENT STREAMS
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Element ColumnReader Interface
  -----------------------------------------------------------------------------
  constant INDEX_WIDTH_ELEMENT        : natural := 32;
  constant VALUE_ELEM_WIDTH_ELEMENT   : natural := 32;
  constant VALUES_PER_CYCLE_ELEMENT   : natural := 8;
  constant NUM_STREAMS_ELEMENT        : natural := 2;  -- index stream, data stream
  constant VALUES_WIDTH_ELEMENT       : natural := VALUE_ELEM_WIDTH_ELEMENT * VALUES_PER_CYCLE_ELEMENT;
  constant VALUES_COUNT_WIDTH_ELEMENT : natural := log2ceil(VALUES_PER_CYCLE_ELEMENT) + 1;
  constant OUT_DATA_WIDTH_ELEMENT     : natural := INDEX_WIDTH_ELEMENT + VALUES_WIDTH_ELEMENT + VALUES_COUNT_WIDTH_ELEMENT;

  signal out_element1_valid  : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element1_ready  : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element1_last   : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element1_dvalid : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element1_data   : std_logic_vector(OUT_DATA_WIDTH_ELEMENT - 1 downto 0);

  signal out_element2_valid  : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element2_ready  : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element2_last   : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element2_dvalid : std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
  signal out_element2_data   : std_logic_vector(OUT_DATA_WIDTH_ELEMENT - 1 downto 0);

  type len_stream_in_t is record
    valid  : std_logic;
    dvalid : std_logic;
    last   : std_logic;
    data   : std_logic_vector(INDEX_WIDTH_ELEMENT - 1 downto 0);
  end record;

  type len_stream_out_t is record
    ready : std_logic;
  end record;

  type posit_stream_in_t is record
    valid  : std_logic;
    dvalid : std_logic;
    last   : std_logic;
    count  : std_logic_vector(VALUES_COUNT_WIDTH_ELEMENT - 1 downto 0);
    data   : std_logic_vector(VALUES_WIDTH_ELEMENT - 1 downto 0);
  end record;

  type posit_stream_out_t is record
    ready : std_logic;
  end record;

  -- Command Stream
  type command_element_t is record
    valid    : std_logic;
    ready    : std_logic;
    firstIdx : std_logic_vector(INDEX_WIDTH_ELEMENT - 1 downto 0);
    lastIdx  : std_logic_vector(INDEX_WIDTH_ELEMENT - 1 downto 0);
    ctrl     : std_logic_vector(2 * BUS_ADDR_WIDTH - 1 downto 0);
  end record;

  type str_element_elem_in_t is record
    len   : len_stream_in_t;
    posit : posit_stream_in_t;
  end record;

  type str_element_elem_out_t is record
    len   : len_stream_out_t;
    posit : posit_stream_out_t;
  end record;

  procedure conv_streams_element_in (
    signal valid               : in  std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
    signal dvalid              : in  std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
    signal last                : in  std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0);
    signal data                : in  std_logic_vector(OUT_DATA_WIDTH_ELEMENT - 1 downto 0);
    signal str_element_elem_in : out str_element_elem_in_t
    ) is
  begin
    str_element_elem_in.len.data   <= data (INDEX_WIDTH_ELEMENT-1 downto 0);
    str_element_elem_in.len.valid  <= valid (0);
    str_element_elem_in.len.dvalid <= dvalid(0);
    str_element_elem_in.len.last   <= last (0);

    str_element_elem_in.posit.count  <= data(VALUES_COUNT_WIDTH_ELEMENT + VALUES_WIDTH_ELEMENT + INDEX_WIDTH_ELEMENT - 1 downto VALUES_WIDTH_ELEMENT + INDEX_WIDTH_ELEMENT);
    str_element_elem_in.posit.data   <= data(VALUES_WIDTH_ELEMENT + INDEX_WIDTH_ELEMENT - 1 downto INDEX_WIDTH_ELEMENT);
    str_element_elem_in.posit.valid  <= valid(1);
    str_element_elem_in.posit.dvalid <= dvalid(1);
    str_element_elem_in.posit.last   <= last(1);
  end procedure;

  procedure conv_streams_element_out (
    signal str_element_elem_out : in  str_element_elem_out_t;
    signal out_ready            : out std_logic_vector(NUM_STREAMS_ELEMENT - 1 downto 0)
    ) is
  begin
    out_ready(0) <= str_element_elem_out.len.ready;
    out_ready(1) <= str_element_elem_out.posit.ready;
  end procedure;

  signal str_element1_elem_in, str_element2_elem_in   : str_element_elem_in_t;
  signal str_element1_elem_out, str_element2_elem_out : str_element_elem_out_t;

  signal s_cmd_element1_tmp, s_cmd_element2_tmp : std_logic_vector(2 * BUS_ADDR_WIDTH + 2 * INDEX_WIDTH_ELEMENT - 1 downto 0);
  signal s_cmd_element1, s_cmd_element2         : command_element_t;
  signal cmd_element1_ready, cmd_element2_ready : std_logic;

  -----------------------------------------------------------------------------
  -- RESULT STREAMS
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Result ColumnWriter Interface
  -----------------------------------------------------------------------------
  constant INDEX_WIDTH_RESULT        : natural := 32;
  constant VALUE_ELEM_WIDTH_RESULT   : natural := 32;
  constant VALUES_PER_CYCLE_RESULT   : natural := 1;
  constant NUM_STREAMS_RESULT        : natural := 1;  -- data stream
  constant VALUES_WIDTH_RESULT       : natural := VALUE_ELEM_WIDTH_RESULT * VALUES_PER_CYCLE_RESULT;
  constant VALUES_COUNT_WIDTH_RESULT : natural := log2ceil(VALUES_PER_CYCLE_RESULT) + 1;
  constant IN_DATA_WIDTH_RESULT      : natural := INDEX_WIDTH_RESULT + VALUES_WIDTH_RESULT + VALUES_COUNT_WIDTH_RESULT;
  constant TAG_WIDTH_RESULT          : natural := 1;

  signal in_result_valid  : std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0);
  signal in_result_ready  : std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0);
  signal in_result_last   : std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0);
  signal in_result_dvalid : std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0);
  signal in_result_data   : std_logic_vector(VALUES_WIDTH_RESULT - 1 downto 0);

  -- Command Stream
  type command_result_t is record
    valid    : std_logic;
    tag      : std_logic_vector(TAG_WIDTH_RESULT - 1 downto 0);
    firstIdx : std_logic_vector(INDEX_WIDTH_RESULT - 1 downto 0);
    lastIdx  : std_logic_vector(INDEX_WIDTH_RESULT - 1 downto 0);
    ctrl     : std_logic_vector(BUS_ADDR_WIDTH - 1 downto 0);
  end record;

  type result_data_stream_out_t is record
    valid  : std_logic;
    dvalid : std_logic;
    last   : std_logic;
    data   : std_logic_vector(VALUES_WIDTH_RESULT - 1 downto 0);
  end record;

  type result_data_stream_in_t is record
    ready : std_logic;
  end record;

  type str_result_elem_in_t is record
    data : result_data_stream_in_t;
  end record;

  type str_result_elem_out_t is record
    data : result_data_stream_out_t;
  end record;

  procedure conv_streams_result_out (
    signal valid               : out std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0);
    signal dvalid              : out std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0);
    signal last                : out std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0);
    signal data                : out std_logic_vector(VALUES_WIDTH_RESULT - 1 downto 0);
    signal str_result_elem_out : in  str_result_elem_out_t
    ) is
  begin
    valid(0)                               <= str_result_elem_out.data.valid;
    dvalid(0)                              <= str_result_elem_out.data.dvalid;
    last(0)                                <= str_result_elem_out.data.last;
    data(VALUES_WIDTH_RESULT - 1 downto 0) <= str_result_elem_out.data.data;
  end procedure;

  procedure conv_streams_result_in (
    signal str_result_elem_in : out str_result_elem_in_t;
    signal in_ready           : in  std_logic_vector(NUM_STREAMS_RESULT - 1 downto 0)
    ) is
  begin
    str_result_elem_in.data.ready <= in_ready(0);
  end procedure;

  type unl_record is record
    ready : std_logic;
  end record;

  type out_record is record
    cmd : command_result_t;
    unl : unl_record;
  end record;

  signal str_result_elem_in  : str_result_elem_in_t;
  signal str_result_elem_out : str_result_elem_out_t;

  signal result_cmd_valid    : std_logic;
  signal result_cmd_ready    : std_logic;
  signal result_cmd_firstIdx : std_logic_vector(INDEX_WIDTH_RESULT-1 downto 0);
  signal result_cmd_lastIdx  : std_logic_vector(INDEX_WIDTH_RESULT-1 downto 0);
  signal result_cmd_ctrl     : std_logic_vector(BUS_ADDR_WIDTH -1 downto 0);
  signal result_cmd_tag      : std_logic_vector(TAG_WIDTH_RESULT-1 downto 0);
  signal result_unlock_valid : std_logic;
  signal result_unlock_ready : std_logic;
  signal result_unlock_tag   : std_logic_vector(TAG_WIDTH_RESULT-1 downto 0);

  -----------------------------------------------------------------------------
  -- UserCore
  -----------------------------------------------------------------------------
  type state_t is (STATE_IDLE, STATE_RESET_START, STATE_REQUEST, STATE_BUSY, STATE_DONE);

  -- Control and status bits
  type cs_t is record
    reset_start : std_logic;
    done        : std_logic;
    busy        : std_logic;
  end record;

  type reg is record
    state : state_t;
    cs    : cs_t;

    command_element      : command_element_t;
    str_element_elem_out : str_element_elem_out_t;
    str_element_elem_in  : str_element_elem_in_t;

    reset_units : std_logic;
  end record;

  signal cr1_r, cr1_d : reg;
  signal cr2_r, cr2_d : reg;

  type state_result_t is (IDLE, COLUMNWRITE, WAIT_ACCEPT, UNLOCK);

  type reg_result is record
    state : state_result_t;
    cs    : cs_t;

    result_index : integer;

    command_result : command_result_t;

    str_result_elem_out : str_result_elem_out_t;
    str_result_elem_in  : str_result_elem_in_t;

    reset_units : std_logic;
  end record;

  signal cw_r, cw_d : reg_result;

  -- Accelerator signals
  signal qs, rs : cu_sched := cu_sched_empty;
  signal q, r   : cu_int;
  signal re     : cu_ext;

  signal el1_posit_in, el2_posit_in                              : std_logic_vector(POSIT_NBITS-1 downto 0);
  signal element1, element2                                      : value;
  signal el1_el2_valid                                           : std_logic;
  signal product                                                 : value_product;
  signal accum_result_raw                                        : value_accum_prod;
  signal accum_result                                            : std_logic_vector(POSIT_NBITS-1 downto 0);
  signal accum_inf, accum_zero                                   : std_logic;
  signal posit_done_mul, posit_done_accum, posit_truncated_accum : std_logic;
  signal reset_accum                                             : std_logic;
begin
  reset <= not reset_n;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- ELEMENT VECTOR 1
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Command Stream Slice
  -----------------------------------------------------------------------------
  slice_inst_element1 : StreamSlice
    generic map (
      DATA_WIDTH => 2 * BUS_ADDR_WIDTH + 2 * INDEX_WIDTH_ELEMENT
      ) port map (
        clk       => clk,
        reset     => cr1_d.reset_units,
        in_valid  => cr1_d.command_element.valid,
        in_ready  => cmd_element1_ready,
        in_data   => cr1_d.command_element.firstIdx & cr1_d.command_element.lastIdx & cr1_d.command_element.ctrl,
        out_valid => s_cmd_element1.valid,
        out_ready => s_cmd_element1.ready,
        out_data  => s_cmd_element1_tmp
        );

  s_cmd_element1.ctrl     <= s_cmd_element1_tmp(2 * BUS_ADDR_WIDTH - 1 downto 0);
  s_cmd_element1.lastIdx  <= s_cmd_element1_tmp(2 * BUS_ADDR_WIDTH + INDEX_WIDTH_ELEMENT - 1 downto 2 * BUS_ADDR_WIDTH);
  s_cmd_element1.firstIdx <= s_cmd_element1_tmp(2 * BUS_ADDR_WIDTH + 2 * INDEX_WIDTH_ELEMENT - 1 downto 2 * BUS_ADDR_WIDTH + INDEX_WIDTH_ELEMENT);

  -----------------------------------------------------------------------------
  -- ColumnReader
  -----------------------------------------------------------------------------
  element1_cr : ColumnReader
    generic map (
      BUS_ADDR_WIDTH     => BUS_ADDR_WIDTH,
      BUS_LEN_WIDTH      => BUS_LEN_WIDTH,
      BUS_DATA_WIDTH     => BUS_DATA_WIDTH,
      BUS_BURST_STEP_LEN => BUS_BURST_STEP_LEN,
      BUS_BURST_MAX_LEN  => BUS_BURST_MAX_LEN,
      INDEX_WIDTH        => INDEX_WIDTH_ELEMENT,
      CFG                => "listprim(32;epc=8)",
      CMD_TAG_ENABLE     => false,
      CMD_TAG_WIDTH      => 1
      )
    port map (
      bus_clk   => clk,
      bus_reset => cr1_r.reset_units,
      acc_clk   => clk,
      acc_reset => cr1_r.reset_units,

      cmd_valid    => s_cmd_element1.valid,
      cmd_ready    => s_cmd_element1.ready,
      cmd_firstIdx => s_cmd_element1.firstIdx,
      cmd_lastIdx  => s_cmd_element1.lastIdx,
      cmd_ctrl     => s_cmd_element1.ctrl,
      cmd_tag      => (others => '0'),  -- CMD_TAG_ENABLE is false

      unlock_valid => open,
      unlock_ready => '1',
      unlock_tag   => open,

      busReq_valid => bus_element1_req_valid,
      busReq_ready => bus_element1_req_ready,
      busReq_addr  => bus_element1_req_addr,
      busReq_len   => bus_element1_req_len,

      busResp_valid => bus_element1_rsp_valid,
      busResp_ready => bus_element1_rsp_ready,
      busResp_data  => bus_element1_rsp_data,
      busResp_last  => bus_element1_rsp_last,

      out_valid  => out_element1_valid,
      out_ready  => out_element1_ready,
      out_last   => out_element1_last,
      out_dvalid => out_element1_dvalid,
      out_data   => out_element1_data
      );

  -----------------------------------------------------------------------------
  -- Stream Conversion
  -----------------------------------------------------------------------------
  -- Output
  str_element1_elem_out <= cr1_d.str_element_elem_out;

  -- Convert the stream inputs and outputs to something readable
  conv_streams_element_in(out_element1_valid, out_element1_dvalid, out_element1_last, out_element1_data, str_element1_elem_in);
  conv_streams_element_out(str_element1_elem_out, out_element1_ready);


  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- ELEMENT VECTOR 2
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Command Stream Slice
  -----------------------------------------------------------------------------
  slice_inst_element2 : StreamSlice
    generic map (
      DATA_WIDTH => 2 * BUS_ADDR_WIDTH + 2 * INDEX_WIDTH_ELEMENT
      ) port map (
        clk       => clk,
        reset     => cr2_d.reset_units,
        in_valid  => cr2_d.command_element.valid,
        in_ready  => cmd_element2_ready,
        in_data   => cr2_d.command_element.firstIdx & cr2_d.command_element.lastIdx & cr2_d.command_element.ctrl,
        out_valid => s_cmd_element2.valid,
        out_ready => s_cmd_element2.ready,
        out_data  => s_cmd_element2_tmp
        );

  s_cmd_element2.ctrl     <= s_cmd_element2_tmp(2 * BUS_ADDR_WIDTH - 1 downto 0);
  s_cmd_element2.lastIdx  <= s_cmd_element2_tmp(2 * BUS_ADDR_WIDTH + INDEX_WIDTH_ELEMENT - 1 downto 2 * BUS_ADDR_WIDTH);
  s_cmd_element2.firstIdx <= s_cmd_element2_tmp(2 * BUS_ADDR_WIDTH + 2 * INDEX_WIDTH_ELEMENT - 1 downto 2 * BUS_ADDR_WIDTH + INDEX_WIDTH_ELEMENT);

  -----------------------------------------------------------------------------
  -- ColumnReader
  -----------------------------------------------------------------------------
  element2_cr : ColumnReader
    generic map (
      BUS_ADDR_WIDTH     => BUS_ADDR_WIDTH,
      BUS_LEN_WIDTH      => BUS_LEN_WIDTH,
      BUS_DATA_WIDTH     => BUS_DATA_WIDTH,
      BUS_BURST_STEP_LEN => BUS_BURST_STEP_LEN,
      BUS_BURST_MAX_LEN  => BUS_BURST_MAX_LEN,
      INDEX_WIDTH        => INDEX_WIDTH_ELEMENT,
      CFG                => "listprim(32;epc=8)",
      CMD_TAG_ENABLE     => false,
      CMD_TAG_WIDTH      => 1
      )
    port map (
      bus_clk   => clk,
      bus_reset => cr2_r.reset_units,
      acc_clk   => clk,
      acc_reset => cr2_r.reset_units,

      cmd_valid    => s_cmd_element2.valid,
      cmd_ready    => s_cmd_element2.ready,
      cmd_firstIdx => s_cmd_element2.firstIdx,
      cmd_lastIdx  => s_cmd_element2.lastIdx,
      cmd_ctrl     => s_cmd_element2.ctrl,
      cmd_tag      => (others => '0'),  -- CMD_TAG_ENABLE is false

      unlock_valid => open,
      unlock_ready => '1',
      unlock_tag   => open,

      busReq_valid => bus_element2_req_valid,
      busReq_ready => bus_element2_req_ready,
      busReq_addr  => bus_element2_req_addr,
      busReq_len   => bus_element2_req_len,

      busResp_valid => bus_element2_rsp_valid,
      busResp_ready => bus_element2_rsp_ready,
      busResp_data  => bus_element2_rsp_data,
      busResp_last  => bus_element2_rsp_last,

      out_valid  => out_element2_valid,
      out_ready  => out_element2_ready,
      out_last   => out_element2_last,
      out_dvalid => out_element2_dvalid,
      out_data   => out_element2_data
      );

  -----------------------------------------------------------------------------
  -- Stream Conversion
  -----------------------------------------------------------------------------
  -- Output
  str_element2_elem_out <= cr2_d.str_element_elem_out;

  -- Convert the stream inputs and outputs to something readable
  conv_streams_element_in(out_element2_valid, out_element2_dvalid, out_element2_last, out_element2_data, str_element2_elem_in);
  conv_streams_element_out(str_element2_elem_out, out_element2_ready);

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- RESULTS
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- ColumnWriter
  -----------------------------------------------------------------------------
  result_cw : ColumnWriter
    generic map (
      BUS_ADDR_WIDTH     => BUS_ADDR_WIDTH,
      BUS_LEN_WIDTH      => BUS_LEN_WIDTH,
      BUS_DATA_WIDTH     => BUS_DATA_WIDTH,
      BUS_STROBE_WIDTH   => BUS_DATA_WIDTH/8,
      BUS_BURST_STEP_LEN => BUS_BURST_STEP_LEN,
      BUS_BURST_MAX_LEN  => BUS_BURST_MAX_LEN,
      INDEX_WIDTH        => INDEX_WIDTH_RESULT,
      CFG                => "prim(32)",
      CMD_TAG_ENABLE     => true,
      CMD_TAG_WIDTH      => TAG_WIDTH_RESULT
      )
    port map (
      bus_clk   => clk,
      bus_reset => reset,
      acc_clk   => clk,
      acc_reset => reset,

      cmd_valid    => result_cmd_valid,
      cmd_ready    => result_cmd_ready,
      cmd_firstIdx => result_cmd_firstIdx,
      cmd_lastIdx  => result_cmd_lastIdx,
      cmd_ctrl     => result_cmd_ctrl,
      cmd_tag      => result_cmd_tag,

      unlock_valid => result_unlock_valid,
      unlock_ready => result_unlock_ready,
      unlock_tag   => result_unlock_tag,

      bus_wreq_valid => bus_result_wreq_valid,
      bus_wreq_ready => bus_result_wreq_ready,
      bus_wreq_addr  => bus_result_wreq_addr,
      bus_wreq_len   => bus_result_wreq_len,

      bus_wdat_valid  => bus_result_wdat_valid,
      bus_wdat_ready  => bus_result_wdat_ready,
      bus_wdat_data   => bus_result_wdat_data,
      bus_wdat_strobe => bus_result_wdat_strobe,
      bus_wdat_last   => bus_result_wdat_last,

      in_valid  => in_result_valid,
      in_ready  => in_result_ready,
      in_last   => in_result_last,
      in_dvalid => in_result_dvalid,
      in_data   => in_result_data
      );

  -----------------------------------------------------------------------------
  -- Stream Conversion
  -----------------------------------------------------------------------------
  -- Output
  str_result_elem_out <= cw_d.str_result_elem_out;

  -- Convert the stream inputs and outputs to something readable
  conv_streams_result_out(in_result_valid, in_result_dvalid, in_result_last, in_result_data, str_result_elem_out);
  conv_streams_result_in(str_result_elem_in, in_result_ready);


---------------------------------------------------------------------------------------------------
--    ____        _       _       _                     _
--   |  _ \      | |     | |     | |                   | |
--   | |_) | __ _| |_ ___| |__   | |     ___   __ _  __| | ___ _ __
--   |  _ < / _` | __/ __| '_ \  | |    / _ \ / _` |/ _` |/ _ \ '__|
--   | |_) | (_| | || (__| | | | | |___| (_) | (_| | (_| |  __/ |
--   |____/ \__,_|\__\___|_| |_| |______\___/ \__,_|\__,_|\___|_|
---------------------------------------------------------------------------------------------------
  r_reset_start <= cr1_r.cs.reset_start and cr2_r.cs.reset_start;
  r_done        <= cr1_r.cs.done and cr2_r.cs.done and cw_r.cs.done;
  r_busy        <= cr1_r.cs.busy or cr2_r.cs.busy;

  -- Registers
  loader_seq : process(clk) is
  begin
    if rising_edge(clk) then
      cr1_r <= cr1_d;
      cr2_r <= cr2_d;

      r_control_reset <= control_reset;
      r_control_start <= control_start;
      reset_start     <= r_reset_start;

      busy <= r_busy;
      done <= r_done;

      -- Offset Buffer Addresses
      r_element1_off_hi <= element1_off_hi;
      r_element1_off_lo <= element1_off_lo;

      r_element2_off_hi <= element2_off_hi;
      r_element2_off_lo <= element2_off_lo;

      -- Data Buffer Addresses
      r_element1_posit_hi <= element1_posit_hi;
      r_element1_posit_lo <= element1_posit_lo;

      r_element2_posit_hi <= element2_posit_hi;
      r_element2_posit_lo <= element2_posit_lo;

      r_result_data_hi <= result_data_hi;
      r_result_data_lo <= result_data_lo;

      r_batch_offset <= batch_offset;

      if control_reset = '1' then
        cu_reset(r);
        cr1_r.reset_units <= '1';
        cr2_r.reset_units <= '1';
      else
        r <= q;
      end if;
    end if;
  end process;

  result_write_comb : process(cw_r,
                              re,
                              str_result_elem_in,
                              control_start,
                              r_result_data_hi, r_result_data_lo,
                              result_cmd_ready,
                              result_unlock_valid, result_unlock_tag)

    variable cw_v         : reg_result;
    variable o            : out_record;
    variable score_line   : line;
    variable result_index : integer;
  begin
    cw_v := cw_r;

    -- ColumnReader Inputs:
    cw_v.str_result_elem_in := str_result_elem_in;

    -- Default ColumnWriter input
    cw_v.str_result_elem_out.data.valid  := cw_r.str_result_elem_out.data.valid;
    cw_v.str_result_elem_out.data.dvalid := cw_r.str_result_elem_out.data.dvalid;
    cw_v.str_result_elem_out.data.last   := cw_r.str_result_elem_out.data.last;
    cw_v.str_result_elem_out.data.data   := cw_r.str_result_elem_out.data.data;

    -- Disable command streams by default
    o.cmd.valid := '0';
    o.unl.ready := '0';

    -- Values buffer
    o.cmd.ctrl(BUS_ADDR_WIDTH-1 downto 0) := r_result_data_hi & r_result_data_lo;

    o.cmd.tag := (0 => '1', others => '0');

    -- Reset start is low by default.
    cw_v.cs.reset_start := '0';

    case cw_r.state is
      when IDLE =>
        re.outfifo.c.rd_en <= '0';
        if control_start = '1' then
          cw_v.cs.reset_start := '1';
          cw_v.state          := COLUMNWRITE;
          cw_v.cs.busy        := '1';
        end if;

      when COLUMNWRITE =>
        -- Write in case of valid output FIFO data
        if(re.outfifo.c.empty = '0') then
          cw_v.str_result_elem_out.data.valid  := '1';
          cw_v.str_result_elem_out.data.dvalid := '1';
          cw_v.str_result_elem_out.data.last   := '1';
          cw_v.str_result_elem_out.data.data   := re.outfifo.dout;

          re.outfifo.c.rd_en <= '1';

          o.cmd.firstIdx := slv(cw_v.result_index, VALUES_WIDTH_RESULT);
          o.cmd.lastIdx  := slv(cw_v.result_index + 1, VALUES_WIDTH_RESULT);

          cw_v.result_index := cw_r.result_index + 1;

          cw_v.state := WAIT_ACCEPT;
        end if;

      when WAIT_ACCEPT =>
        re.outfifo.c.rd_en <= '0';
        if result_cmd_ready = '1' then
          o.cmd.valid := '1';

          -- Command is accepted, wait for unlock.
          cw_v.state := UNLOCK;
        end if;

      when UNLOCK =>
        o.unl.ready := '1';
        if result_unlock_valid = '1' then
          cw_v.state   := COLUMNWRITE;
          cw_v.cs.busy := '0';
        end if;
    end case;

    -- Registered outputs
    cw_d <= cw_v;

    -- Combinatorial outputs
    result_cmd_valid    <= o.cmd.valid;
    result_cmd_firstIdx <= o.cmd.firstIdx;
    result_cmd_lastIdx  <= o.cmd.lastIdx;
    result_cmd_ctrl     <= o.cmd.ctrl;
    result_cmd_tag      <= o.cmd.tag;

    result_unlock_ready <= o.unl.ready;
  end process;

  result_write_seq : process(clk, r.wed.batches_total, result_unlock_valid) is
    variable result_count : integer range 0 to MAX_BATCHES := 0;
  begin
    if rising_edge(clk) then
      cw_r <= cw_d;

      if result_unlock_valid = '1' then
        result_count := result_count + 1;
        if(result_count = to_integer(r.wed.batches_total)) then  -- TODO how many results?
          cw_r.cs.done <= '1';
        end if;
      end if;

      -- Reset
      if reset = '1' then
        cw_r.state          <= IDLE;
        cw_r.cs.reset_start <= '0';
        cw_r.cs.busy        <= '0';
        cw_r.cs.done        <= '0';
        cw_r.result_index   <= 0;

        cw_r.str_result_elem_out.data.valid  <= '0';
        cw_r.str_result_elem_out.data.dvalid <= '0';
        cw_r.str_result_elem_out.data.last   <= '0';
        cw_r.str_result_elem_out.data.data   <= (others => '0');

        result_count := 0;
      end if;
    end if;
  end process;


  loader_comb : process(r,
                        re.element1_fifo, re.element2_fifo,
                        rs,
                        cr1_r, cr2_r,
                        control_start,
                        cmd_element1_ready, cmd_element2_ready,
                        str_element1_elem_in, str_element2_elem_in,
                        r_element1_off_hi, r_element1_off_lo, r_element2_off_hi, r_element2_off_lo,
                        r_element1_posit_hi, r_element1_posit_lo, r_element2_posit_hi, r_element2_posit_lo,
                        r_control_start,
                        r_control_reset)
    variable v            : cu_int;
    variable t            : std_logic;
    variable cr1_v, cr2_v : reg;

    variable element1_valid, element2_valid : std_logic := '0';
  begin
    cr1_v := cr1_r;
    cr2_v := cr2_r;

    -- ColumnReader Inputs:
    cr1_v.command_element.ready := cmd_element1_ready;
    cr2_v.command_element.ready := cmd_element2_ready;

    cr1_v.str_element_elem_in := str_element1_elem_in;
    cr2_v.str_element_elem_in := str_element2_elem_in;

    -- Default outputs:
    cr1_v.command_element.valid := '0';
    cr2_v.command_element.valid := '0';

    cr1_v.str_element_elem_out.len.ready := '0';
    cr2_v.str_element_elem_out.len.ready := '0';

    cr1_v.str_element_elem_out.posit.ready := '0';
    cr2_v.str_element_elem_out.posit.ready := '0';

    --------------------------------------------------------------------------------------------------- default assignments
    v := r;

    v.element1_rst := '0';
    v.element2_rst := '0';

    v.element1_wren := '0';
    v.element2_wren := '0';
    --------------------------------------------------------------------------------------------------- state machine
    case r.state is

      when LOAD_IDLE =>
        cr1_v.cs.done        := '0';
        cr1_v.cs.busy        := '0';
        cr1_v.cs.reset_start := '0';
        cr1_v.reset_units    := '1';

        cr2_v.cs.done        := '0';
        cr2_v.cs.busy        := '0';
        cr2_v.cs.reset_start := '0';
        cr2_v.reset_units    := '1';

        -- When start signal is received:
        if control_start = '1' then
          v.state              := LOAD_RESET_START;
          cr1_v.cs.reset_start := '1';
          cr2_v.cs.reset_start := '1';
        end if;

      when LOAD_RESET_START =>
        cr1_v.cs.done := '0';
        cr2_v.cs.done := '0';

        cr1_v.cs.busy := '1';
        cr2_v.cs.busy := '1';

        cr1_v.reset_units := '0';
        cr2_v.reset_units := '0';

        if control_start = '0' then
          v.wed.batches_total := to_unsigned(1, 32);
          v.wed.batches       := to_unsigned(1, 32);
          v.state             := LOAD_REQUEST_DATA;
        end if;

      -- Request all data
      when LOAD_REQUEST_DATA =>
        -- Reset all counters etc...
        v.element1_reads := (others => '0');
        v.element2_reads := (others => '0');
        v.filled         := '0';

        -- ColumnReader 1
        cr1_v.cs.done        := '0';
        cr1_v.cs.busy        := '1';
        cr1_v.cs.reset_start := '0';
        cr1_v.reset_units    := '0';
        -- ColumnReader 2
        cr2_v.cs.done        := '0';
        cr2_v.cs.busy        := '1';
        cr2_v.cs.reset_start := '0';
        cr2_v.reset_units    := '0';

        -- Elements
        -- First four argument registers are buffer addresses
        -- MSBs are index buffer address
        cr1_v.command_element.ctrl(127 downto 96) := r_element1_off_hi;
        cr1_v.command_element.ctrl(95 downto 64)  := r_element1_off_lo;

        cr2_v.command_element.ctrl(127 downto 96) := r_element2_off_hi;
        cr2_v.command_element.ctrl(95 downto 64)  := r_element2_off_lo;

        -- LSBs are data buffer address
        cr1_v.command_element.ctrl(63 downto 32) := r_element1_posit_hi;
        cr1_v.command_element.ctrl(31 downto 0)  := r_element1_posit_lo;

        cr2_v.command_element.ctrl(63 downto 32) := r_element2_posit_hi;
        cr2_v.command_element.ctrl(31 downto 0)  := r_element2_posit_lo;

        -- First and Last index for elements and reads
        cr1_v.command_element.firstIdx := slv(int(r_batch_offset) + int(r.wed.batches) - 1, INDEX_WIDTH_ELEMENT);
        cr1_v.command_element.lastIdx  := slv(int(r_batch_offset) + int(r.wed.batches), INDEX_WIDTH_ELEMENT);

        cr2_v.command_element.firstIdx := slv(int(r_batch_offset) + int(r.wed.batches) - 1, INDEX_WIDTH_ELEMENT);
        cr2_v.command_element.lastIdx  := slv(int(r_batch_offset) + int(r.wed.batches), INDEX_WIDTH_ELEMENT);

        -- Make command valid
        cr1_v.command_element.valid := '1';
        cr2_v.command_element.valid := '1';

        -- Wait for command accepted
        if cr1_v.command_element.ready = '1' and cr2_v.command_element.ready = '1' then
          dumpStdOut("Requested posit element array 1: " & integer'image(int(cr1_v.command_element.firstIdx)) & " ... " & integer'image(int(cr1_v.command_element.lastIdx)));
          dumpStdOut("Requested posit element array 2: " & integer'image(int(cr2_v.command_element.firstIdx)) & " ... " & integer'image(int(cr2_v.command_element.lastIdx)));
          v.state := LOAD_LOADX_LOADY;  -- Load reads and elements
        end if;

      when LOAD_LOADX_LOADY =>
        v.element_reads_valid := '0';

        cr1_v.cs.done        := '0';
        cr1_v.cs.busy        := '1';
        cr1_v.cs.reset_start := '0';
        cr1_v.reset_units    := '0';

        cr2_v.cs.done        := '0';
        cr2_v.cs.busy        := '1';
        cr2_v.cs.reset_start := '0';
        cr2_v.reset_units    := '0';

        -- Always ready to receive length
        cr1_v.str_element_elem_out.len.ready   := '1';
        cr2_v.str_element_elem_out.len.ready   := '1';
        -- Ready to receive posit
        cr1_v.str_element_elem_out.posit.ready := '1';
        cr2_v.str_element_elem_out.posit.ready := '1';

        -- Store the vector elements
        if cr1_v.str_element_elem_in.posit.valid = '1' then
          v.element1_reads := r.element1_reads + int(cr1_v.str_element_elem_in.posit.count);
          v.element1_wren  := '1';

          case int(cr1_v.str_element_elem_in.posit.count) is
            when 0      => v.element1_data := (others => '0');
            when 1      => v.element1_data := (255 downto 32 => '0') & cr1_v.str_element_elem_in.posit.data(31 downto 0);
            when 2      => v.element1_data := (255 downto 64 => '0') & cr1_v.str_element_elem_in.posit.data(63 downto 0);
            when 3      => v.element1_data := (255 downto 96 => '0') & cr1_v.str_element_elem_in.posit.data(95 downto 0);
            when 4      => v.element1_data := (255 downto 128 => '0') & cr1_v.str_element_elem_in.posit.data(127 downto 0);
            when 5      => v.element1_data := (255 downto 160 => '0') & cr1_v.str_element_elem_in.posit.data(159 downto 0);
            when 6      => v.element1_data := (255 downto 192 => '0') & cr1_v.str_element_elem_in.posit.data(191 downto 0);
            when 7      => v.element1_data := (255 downto 224 => '0') & cr1_v.str_element_elem_in.posit.data(223 downto 0);
            when 8      => v.element1_data := cr1_v.str_element_elem_in.posit.data(255 downto 0);
            when others => v.element1_data := (others => '0');
          end case;

          if cr1_v.str_element_elem_in.posit.last = '1' then
            v.element1_last := '1';
          end if;
        else
          v.element1_reads := r.element1_reads;
          v.element1_wren  := '0';
          v.element1_data  := (others => '0');
        end if;

        if cr2_v.str_element_elem_in.posit.valid = '1' then
          v.element2_reads := r.element2_reads + int(cr2_v.str_element_elem_in.posit.count);
          v.element2_wren  := '1';

          case int(cr2_v.str_element_elem_in.posit.count) is
            when 0      => v.element2_data := (others => '0');
            when 1      => v.element2_data := (255 downto 32 => '0') & cr2_v.str_element_elem_in.posit.data(31 downto 0);
            when 2      => v.element2_data := (255 downto 64 => '0') & cr2_v.str_element_elem_in.posit.data(63 downto 0);
            when 3      => v.element2_data := (255 downto 96 => '0') & cr2_v.str_element_elem_in.posit.data(95 downto 0);
            when 4      => v.element2_data := (255 downto 128 => '0') & cr2_v.str_element_elem_in.posit.data(127 downto 0);
            when 5      => v.element2_data := (255 downto 160 => '0') & cr2_v.str_element_elem_in.posit.data(159 downto 0);
            when 6      => v.element2_data := (255 downto 192 => '0') & cr2_v.str_element_elem_in.posit.data(191 downto 0);
            when 7      => v.element2_data := (255 downto 224 => '0') & cr2_v.str_element_elem_in.posit.data(223 downto 0);
            when 8      => v.element2_data := cr2_v.str_element_elem_in.posit.data(255 downto 0);
            when others => v.element2_data := (others => '0');
          end case;

          if cr2_v.str_element_elem_in.posit.last = '1' then
            v.element2_last := '1';
          end if;
        else
          v.element2_reads := r.element2_reads;
          v.element2_wren  := '0';
          v.element2_data  := (others => '0');
        end if;

        -- If FIFOs are full, process and read in elements again
        if(r.element1_reads >= 2032) then
          cr1_v.str_element_elem_out.posit.ready := '0';
        end if;
        if(r.element2_reads >= 2032) then
          cr2_v.str_element_elem_out.posit.ready := '0';
        end if;

        if(r.element1_reads >= 2032 and r.element2_reads >= 2032) then
          v.wed.batches         := r.wed.batches;
          v.element_reads_valid := '0';
          v.element1_last       := '0';
          v.element2_last       := '0';

          v.state := LOAD_WAIT_LAUNCH_PART;
        end if;

        if(r.element1_last = '1' and r.element2_last = '1') then
          v.wed.batches         := r.wed.batches - 1;
          v.element_reads_valid := '1';
          v.element1_last       := '0';
          v.element2_last       := '0';

          v.state := LOAD_LAUNCH;
        end if;

      when LOAD_WAIT_LAUNCH_PART =>
        if(cr1_v.str_element_elem_in.posit.valid = '1') then
          element1_valid := '1';
        end if;
        if(cr2_v.str_element_elem_in.posit.valid = '1') then
          element2_valid := '1';
        end if;

        if(element1_valid = '1' and element2_valid = '1') then
          v.wed.batches         := r.wed.batches;
          v.element_reads_valid := '1';

          v.state := LOAD_LAUNCH_PART;
        end if;

      when LOAD_LAUNCH_PART =>
        element1_valid := '0';
        element2_valid := '0';
        if r.filled = '1' then
          if rs.state = SCHED_DONE_PART then
            v.filled         := '0';
            v.element1_reads := (others => '0');
            v.element2_reads := (others => '0');

            -- We can start loading a new batch
            v.state := LOAD_LOADX_LOADY;
          end if;
        end if;

        -- If the scheduler is idle
        if rs.state = SCHED_IDLE and v.state /= LOAD_LOADX_LOADY and re.element1_fifo.c.empty = '0' and re.element2_fifo.c.empty = '0' then
          -- We can signal the scheduler to start processing:
          v.filled := '1';
        end if;

      -- A new batch is ready to be started
      when LOAD_LAUNCH =>
        -- If we told the scheduler to start a new batch
        if r.filled = '1' then
          -- And it's not idle anymore, it's busy with the new batch
          if rs.state /= SCHED_IDLE then
            -- We can reset the filled bit to 0.
            v.filled := '0';
            -- If there is still work to do:
            if v.wed.batches /= 0 then
              -- We can start loading a new batch
              v.state := LOAD_REQUEST_DATA;
            else
              v.state := LOAD_DONE;
            end if;
          end if;
        end if;

        -- If the scheduler is idle
        if rs.state = SCHED_IDLE and v.state /= LOAD_DONE and re.element1_fifo.c.empty = '0' and re.element2_fifo.c.empty = '0' then
          -- We can signal the scheduler to start processing:
          v.filled := '1';
        end if;

      -- State where we wait for the scheduler to stop
      when LOAD_DONE =>
        if rs.state = SCHED_IDLE then
          cr1_v.cs.done        := '1';
          cr1_v.cs.busy        := '0';
          cr1_v.cs.reset_start := '0';
          cr1_v.reset_units    := '0';

          cr2_v.cs.done        := '1';
          cr2_v.cs.busy        := '0';
          cr2_v.cs.reset_start := '0';
          cr2_v.reset_units    := '0';

          if r_control_reset = '1' or r_control_start = '1' then
            v.state := LOAD_IDLE;
          end if;
        end if;

      when others => null;
    end case;

    --------------------------------------------------------------------------------------------------- outputs
    -- drive input registers
    q <= v;

    cr1_d <= cr1_v;
    cr2_d <= cr2_v;
  end process;

  ---------------------------------------------------------------------------------------------------
  --  ______   _                                     _       ______   _____   ______    ____
  -- |  ____| | |                                   | |     |  ____| |_   _| |  ____|  / __ \
  -- | |__    | |   ___   _ __ ___     ___   _ __   | |_    | |__      | |   | |__    | |  | |  ___
  -- |  __|   | |  / _ \ | '_ ` _ \   / _ \ | '_ \  | __|   |  __|     | |   |  __|   | |  | | / __|
  -- | |____  | | |  __/ | | | | | | |  __/ | | | | | |_    | |       _| |_  | |      | |__| | \__ \
  -- |______| |_|  \___| |_| |_| |_|  \___| |_| |_|  \__|   |_|      |_____| |_|       \____/  |___/
  ---------------------------------------------------------------------------------------------------

  element1_fifo : element_fifo port map (
    rst       => r.element1_rst,
    wr_clk    => clk,
    rd_clk    => re.clk_kernel,
    din       => r.element1_data(255 downto 0),
    dout      => re.element1_fifo.dout,
    wr_en     => re.element1_fifo.c.wr_en,
    rd_en     => re.element1_fifo.c.rd_en,
    full      => re.element1_fifo.c.full,
    wr_ack    => re.element1_fifo.c.wr_ack,
    overflow  => re.element1_fifo.c.overflow,
    empty     => re.element1_fifo.c.empty,
    valid     => re.element1_fifo.c.valid,
    underflow => re.element1_fifo.c.underflow
    );
  re.element1_fifo.c.wr_en <= r.element1_wren;

  element2_fifo : element_fifo port map (
    rst       => r.element2_rst,
    wr_clk    => clk,
    rd_clk    => re.clk_kernel,
    din       => r.element2_data(255 downto 0),
    dout      => re.element2_fifo.dout,
    wr_en     => re.element2_fifo.c.wr_en,
    rd_en     => re.element2_fifo.c.rd_en,
    full      => re.element2_fifo.c.full,
    wr_ack    => re.element2_fifo.c.wr_ack,
    overflow  => re.element2_fifo.c.overflow,
    empty     => re.element2_fifo.c.empty,
    valid     => re.element2_fifo.c.valid,
    underflow => re.element2_fifo.c.underflow
    );
  re.element2_fifo.c.wr_en <= r.element2_wren;

  ---------------------------------------------------------------------------------------------------
  --   _____   _                  _
  --  / ____| | |                | |
  -- | |      | |   ___     ___  | | __
  -- | |      | |  / _ \   / __| | |/ /
  -- | |____  | | | (_) | | (__  |   <
  --  \_____| |_|  \___/   \___| |_|\_\
  ---------------------------------------------------------------------------------------------------
  -- In case the kernel has to run slower due to timing constraints not being met, use this to lower the clock frequency
  kernel_clock_gen : psl_to_kernel port map (
    clk_psl    => clk,
    clk_kernel => re.clk_kernel
    );

  -- Use this to keep everything in the same clock domain:
  -- re.clk_kernel <= clk;

---------------------------------------------------------------------------------------------------
--   ____            _                     _
--  / __ \          | |                   | |
-- | |  | |  _   _  | |_   _ __    _   _  | |_
-- | |  | | | | | | | __| | '_ \  | | | | | __|
-- | |__| | | |_| | | |_  | |_) | | |_| | | |_
--  \____/   \__,_|  \__| | .__/   \__,_|  \__|
--                        | |
--                        |_|
---------------------------------------------------------------------------------------------------
  re.outfifo.din(31 downto 0) <= rs.accum_write_result;
  re.outfifo.c.wr_en          <= rs.accum_write;

  outfifo : output_fifo
    port map (
      wr_clk    => re.clk_kernel,          -- in
      rd_clk    => clk,                    -- in
      din       => re.outfifo.din,         -- in
      wr_en     => re.outfifo.c.wr_en,     -- in
      rd_en     => re.outfifo.c.rd_en,     -- in
      dout      => re.outfifo.dout,        -- out
      full      => re.outfifo.c.full,      -- out
      wr_ack    => re.outfifo.c.wr_ack,    -- out
      overflow  => re.outfifo.c.overflow,  -- out
      empty     => re.outfifo.c.empty,     -- out
      valid     => re.outfifo.c.valid,     -- out
      underflow => re.outfifo.c.underflow  -- out
      );

  ---------------------------------------------------------------------------------------------------
  --     _____      _              _       _
  --    / ____|    | |            | |     | |
  --   | (___   ___| |__   ___  __| |_   _| | ___ _ __
  --    \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \ '__|
  --    ____) | (__| | | |  __/ (_| | |_| | |  __/ |
  --   |_____/ \___|_| |_|\___|\__,_|\__,_|_|\___|_|
  ---------------------------------------------------------------------------------------------------

  scheduler_comb : process(r, re, rs, accum_result, posit_done_accum)
    variable vs : cu_sched;
  begin
    vs := rs;

    vs.accum_write        := '0';
    vs.accum_write_result := (others => '0');
    vs.element_fifo_rd    := '0';

    vs.accum_cnt := rs.accum_cnt + 1;
    if(rs.accum_cnt = 15) then
      vs.accum_cnt := (others => '0');
    end if;

    case rs.state is
      when SCHED_IDLE =>
        vs.valid          := '0';
        -- Gather the lengths from other clock domain
        vs.element1_reads := r.element1_reads(31 downto 0);
        vs.element2_reads := r.element2_reads(31 downto 0);

        vs.accum_pass_cnt := (others => '0');

        if r.filled = '1' and rs.accum_cnt = 13 then
          vs.element_fifo_rd := '1';
          vs.state           := SCHED_STARTUP;
        end if;

      when SCHED_STARTUP =>
        vs.valid := '0';
        if rs.accum_cnt = 15 then
          vs.valid     := '1';          -- Enable data valid on the next cycle
          vs.startflag := '1';
          vs.state     := SCHED_PROCESSING;  -- Go to processing state
        end if;

      when SCHED_PROCESSING =>
        -- Unset the startflag
        vs.startflag := '0';

        if(rs.accum_cnt = 13) then
          if(re.element1_fifo.c.empty = '0' and re.element2_fifo.c.empty = '0') then
            vs.element_fifo_rd := '1';
          end if;
        end if;

        if(rs.accum_cnt = 4) then
          if(posit_done_accum = '1') then
            vs.accum_pass_cnt := rs.accum_pass_cnt + 1;
            dumpStdOut("PASS " & integer'image(int(vs.accum_pass_cnt)));

            if((re.element1_fifo.c.empty = '1' or re.element2_fifo.c.empty = '1') and rs.startflag = '0') then
              vs.valid := '0';          -- Next inputs are not valid anymore
              vs.state := SCHED_LAST;
            end if;
          end if;
        end if;

      when SCHED_LAST =>
        if(rs.accum_cnt = 4 and posit_done_accum = '1') then
          vs.accum_pass_cnt := rs.accum_pass_cnt + 1;
          dumpStdOut("PASS " & integer'image(int(vs.accum_pass_cnt)));

          if(r.state = LOAD_LAUNCH_PART) then
            vs.state := SCHED_DONE_PART;
          else
            vs.accum_write        := '1';
            vs.accum_write_result := accum_result;

            vs.state := SCHED_DONE;
          end if;
        end if;

      when SCHED_DONE_PART =>
        vs.state := SCHED_IDLE;

      when SCHED_DONE =>
        vs.accum_cnt := (others => '0');
        vs.state     := SCHED_IDLE;

      when others =>
        null;

    end case;

    qs <= vs;
  end process;

  scheduler_reg : process(re.clk_kernel)
  begin
    if rising_edge(re.clk_kernel) then
      if reset = '1' then
        rs.state <= SCHED_IDLE;
        rs.valid <= '0';
      else
        rs <= qs;
      end if;
    end if;
  end process;

  re.element1_fifo.c.rd_en <= rs.element_fifo_rd;
  re.element2_fifo.c.rd_en <= rs.element_fifo_rd;

  ---------------------------------------------------------------------------------------------------
  --  _____                _   _       _    _           _   _
  -- |  __ \              (_) | |     | |  | |         (_) | |
  -- | |__) | ___    ___   _  | |_    | |  | |  _ __    _  | |_   ___
  -- |  ___/ / _ \  / __| | | | __|   | |  | | | '_ \  | | | __| / __|
  -- | |    | (_) | \__ \ | | | |_    | |__| | | | | | | | | |_  \__ \
  -- |_|     \___/  |___/ |_|  \__|    \____/  |_| |_| |_|  \__| |___/
  ---------------------------------------------------------------------------------------------------

  reset_accum <= reset;                 -- TODO Laurens

  el1_posit_in <= re.element1_fifo.dout when re.element1_fifo.c.valid = '1' else x"00000000";
  el2_posit_in <= re.element2_fifo.dout when re.element2_fifo.c.valid = '1' else x"00000000";

  el1_el2_valid <= re.element1_fifo.c.valid and re.element2_fifo.c.valid;

  -- POSIT EXTRACTION
  gen_posit_extract_raw_es2 : if POSIT_ES = 2 generate
    extract_el1_inst : posit_extract_raw port map (
      in1      => el1_posit_in,
      absolute => open,
      result   => element1
      );
    extract_el2_inst : posit_extract_raw port map (
      in1      => el2_posit_in,
      absolute => open,
      result   => element2
      );
  end generate;
  gen_posit_extract_raw_es3 : if POSIT_ES = 3 generate
    extract_el1_inst : posit_extract_raw_es3 port map (
      in1      => el1_posit_in,
      absolute => open,
      result   => element1
      );
    extract_el2_inst : posit_extract_raw_es3 port map (
      in1      => el2_posit_in,
      absolute => open,
      result   => element2
      );
  end generate;

  -- POSIT MULTIPLICATION
  gen_mul_es2 : if POSIT_ES = 2 generate
    posit_mul_es2_inst : positmult_4_raw port map (
      clk    => re.clk_kernel,
      in1    => element1,
      in2    => element2,
      start  => el1_el2_valid,
      result => product,
      done   => posit_done_mul
      );
  end generate;
  gen_mul_es3 : if POSIT_ES = 3 generate
    posit_mul_es3_inst : positmult_4_raw_es3 port map (
      clk    => re.clk_kernel,
      in1    => element1,
      in2    => element2,
      start  => el1_el2_valid,
      result => product,
      done   => posit_done_mul
      );
  end generate;

  -- POSIT ACCUMULATION
  gen_accum_es2 : if POSIT_ES = 2 generate
    posit_accum_es2_inst : positaccum_prod_16_raw port map (
      clk       => re.clk_kernel,
      rst       => reset_accum,
      in1       => product,
      start     => posit_done_mul,
      result    => accum_result_raw,
      done      => posit_done_accum,
      truncated => posit_truncated_accum
      );
  end generate;
  gen_accum_es3 : if POSIT_ES = 3 generate
    posit_accum_es3_inst : positaccum_prod_16_raw_es3 port map (
      clk       => re.clk_kernel,
      rst       => reset_accum,
      in1       => product,
      start     => posit_done_mul,
      result    => accum_result_raw,
      done      => posit_done_accum,
      truncated => posit_truncated_accum
      );
  end generate;

  -- POSIT NORMALIZATION
  gen_normalize_es2 : if POSIT_ES = 2 generate
    posit_normalize_es2_inst : posit_normalize_accum_prod port map (
      in1       => accum_result_raw,
      truncated => posit_truncated_accum,
      result    => accum_result,
      inf       => accum_inf,
      zero      => accum_zero
      );
  end generate;
  gen_normalize_es3 : if POSIT_ES = 3 generate
    posit_normalize_es3_inst : posit_normalize_accum_prod_es3 port map (
      in1       => accum_result_raw,
      truncated => posit_truncated_accum,
      result    => accum_result,
      inf       => accum_inf,
      zero      => accum_zero
      );
  end generate;

end positdot_unit;
