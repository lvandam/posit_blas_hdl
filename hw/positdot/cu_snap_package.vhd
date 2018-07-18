library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.posit_common.all;

package cu_snap_package is

  constant MAX_BATCHES : natural := 3;

  type wed_type is record
    batch_size    : unsigned(31 downto 0);
    batches       : unsigned(31 downto 0);
    batches_total : unsigned(31 downto 0);
  end record;

  type cu_state is (
    LOAD_IDLE,
    LOAD_RESET_START,
    LOAD_REQUEST_DATA,
    LOAD_LOADX_LOADY,
    LOAD_LAUNCH,
    LOAD_DONE
    );

  type cu_int is record
    state : cu_state;
    wed   : wed_type;

    element1_reads      : unsigned(31 downto 0);
    element2_reads      : unsigned(31 downto 0);
    element_reads_valid : std_logic;

    element1_data : std_logic_vector(255 downto 0); -- 8 elements per burst
    element2_data : std_logic_vector(255 downto 0);

    element1_wren : std_logic;
    element2_wren : std_logic;

    filled : std_logic;
  end record;

  type cu_sched_state is (
    SCHED_IDLE,
    SCHED_STARTUP,
    SCHED_PROCESSING,
    SCHED_EMPTY_FIFOS,
    SCHED_DONE
    );

  type cu_sched is record
    state     : cu_sched_state;         -- State of the scheduler process
    valid     : std_logic;              -- Valid bit
    startflag : std_logic;

    element1_reads     : unsigned(31 downto 0);
    element2_reads     : unsigned(31 downto 0);
    accum_cnt          : unsigned(3 downto 0);
    accum_pass_cnt     : unsigned(31 downto 0);
    accum_write        : std_logic;
    accum_write_result : std_logic_vector(31 downto 0);
    accum_fifo_rd      : std_logic;
  end record;

  constant cu_sched_empty : cu_sched := (
    state              => SCHED_IDLE,
    valid              => '0',
    startflag          => '0',
    element1_reads     => (others => '0'),
    element2_reads     => (others => '0'),
    accum_cnt          => (others => '0'),
    accum_pass_cnt     => (others => '0'),
    accum_write        => '0',
    accum_write_result => (others => '0'),
    accum_fifo_rd      => '0'
    );

  type fifo_controls is record
    rd_en  : std_logic;
    rd_en1 : std_logic;

    valid : std_logic;

    wr_en  : std_logic;
    wr_ack : std_logic;

    empty : std_logic;
    full  : std_logic;

    overflow  : std_logic;
    underflow : std_logic;

    rst    : std_logic;
    rd_rst : std_logic;
    wr_rst : std_logic;
  end record;

  type outfifo_item is record
    din  : std_logic_vector(31 downto 0);
    dout : std_logic_vector(31 downto 0);
    c    : fifo_controls;
  end record;

  type accumfifo_es2_item is record
    din  : std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2 - 1 downto 0);
    dout : std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2 - 1 downto 0);
    c    : fifo_controls;
  end record;

  type accumfifo_es3_item is record
    din  : std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3 - 1 downto 0);
    dout : std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3 - 1 downto 0);
    c    : fifo_controls;
  end record;

  type elementfifo_item is record
    din  : std_logic_vector(255 downto 0);
    dout : std_logic_vector(31 downto 0);
    c    : fifo_controls;
  end record;

  type cu_ext is record
    outfifo : outfifo_item;

    accum_fifo_es2     : accumfifo_es2_item;
    accum_fifo_out_es2 : std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2 - 1 downto 0);

    accum_fifo_es3     : accumfifo_es3_item;
    accum_fifo_out_es3 : std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3 - 1 downto 0);

    element1_fifo : elementfifo_item;
    element2_fifo : elementfifo_item;

    accum_fifo_empty : std_logic;

    clk_kernel : std_logic;
  end record;

  procedure cu_reset (signal r : inout cu_int);

end package cu_snap_package;

package body cu_snap_package is
  procedure cu_reset (signal r : inout cu_int) is
  begin
    r.state <= LOAD_IDLE;

    r.element1_reads <= (others => '0');
    r.element1_data  <= (others => '0');

    r.element2_reads <= (others => '0');
    r.element2_data  <= (others => '0');

    r.element_reads_valid <= '0';

    r.element1_wren <= '0';
    r.element2_wren <= '0';

    r.filled <= '0';
  end procedure cu_reset;

end package body cu_snap_package;
