library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.posit_common.all;
use work.posit_package.all;

package cu_snap_package is

  type op_type is (INVALID_OP, VECTOR_DOT, VECTOR_ADD, VECTOR_MULT);
  function op2op (a : in std_logic_vector(31 downto 0)) return op_type;

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
    LOAD_WAIT_LAUNCH_PART,
    LOAD_LAUNCH_PART,
    LOAD_LAUNCH,
    LOAD_DONE
    );

  type cu_int is record
    state : cu_state;
    wed   : wed_type;

    operation : op_type;

    element1_reads      : unsigned(31 downto 0);
    element2_reads      : unsigned(31 downto 0);
    element_reads_valid : std_logic;

    element1_data : std_logic_vector(255 downto 0);  -- 8 elements per burst
    element2_data : std_logic_vector(255 downto 0);

    element1_last : std_logic;
    element2_last : std_logic;

    element1_full : std_logic;
    element2_full : std_logic;

    element1_wren : std_logic;
    element2_wren : std_logic;

    element1_rst : std_logic;
    element2_rst : std_logic;

    element1_nonempty_sticky : std_logic;
    element2_nonempty_sticky : std_logic;

    filled : std_logic;
  end record;

  type cu_sched_state is (
    SCHED_WAIT_START,
    SCHED_IDLE,
    SCHED_LOAD_FIRST,
    SCHED_STARTUP,

    SCHED_VECTOR_DOT_PROCESSING,
    SCHED_VECTOR_DOT_LAST,
    SCHED_VECTOR_DOT_FINAL_ACCUM_COLLECT,
    SCHED_VECTOR_DOT_FINAL_ACCUM,

    SCHED_VECTOR_ADD_PROCESSING,

    SCHED_VECTOR_MULT_PROCESSING,

    SCHED_DONE
    );

  type cu_sched is record
    state     : cu_sched_state;         -- State of the scheduler process
    valid     : std_logic;              -- Valid bit
    startflag : std_logic;

    operation          : op_type;
    result_length      : unsigned(31 downto 0);
    element1_reads     : unsigned(31 downto 0);
    element2_reads     : unsigned(31 downto 0);
    accum_cnt          : unsigned(3 downto 0);
    accum_pass_cnt     : unsigned(31 downto 0);
    accum_write        : std_logic;
    accum_write_result : std_logic_vector(31 downto 0);
    element_fifo_rd    : std_logic;
    accum_fifo_rd      : std_logic;
    accum_final_cnt    : unsigned(4 downto 0);
    accum_fifo_data    : value_accum_prod;
    accum_fifo_wren    : std_logic;
    accum_fifo_rst     : std_logic;
  end record;

  constant cu_sched_empty : cu_sched := (
    state              => SCHED_IDLE,
    valid              => '0',
    startflag          => '0',
    operation          => INVALID_OP,
    result_length      => (others => '0'),
    element1_reads     => (others => '0'),
    element2_reads     => (others => '0'),
    accum_cnt          => (others => '0'),
    accum_pass_cnt     => (others => '0'),
    accum_write        => '0',
    accum_write_result => (others => '0'),
    element_fifo_rd    => '0',
    accum_fifo_rd      => '0',
    accum_final_cnt    => (others => '0'),
    accum_fifo_data    => (others => '0'),
    accum_fifo_wren    => '0',
    accum_fifo_rst     => '0'
    );

  type fifo_controls is record
    rd_en  : std_logic;
    rd_en1 : std_logic;

    valid : std_logic;

    almost_full : std_logic;
    wr_en       : std_logic;
    wr_ack      : std_logic;

    empty : std_logic;
    full  : std_logic;

    overflow  : std_logic;
    underflow : std_logic;

    prog_full  : std_logic;
    prog_empty : std_logic;

    rst : std_logic;

    rd_rst : std_logic;
    wr_rst : std_logic;

    rd_rst_busy : std_logic;
    wr_rst_busy : std_logic;
  end record;

  type outfifo_item is record
    din  : std_logic_vector(31 downto 0);
    dout : std_logic_vector(31 downto 0);
    c    : fifo_controls;
  end record;

  type elementfifo_item is record
    din  : std_logic_vector(255 downto 0);
    dout : std_logic_vector(31 downto 0);
    c    : fifo_controls;
  end record;

  type accum_fifo_item is record
    dout : value_accum_prod;
    c    : fifo_controls;
  end record;

  type cu_ext is record
    outfifo : outfifo_item;

    element1_fifo : elementfifo_item;
    element2_fifo : elementfifo_item;

    accum_fifo : accum_fifo_item;

    clk_kernel : std_logic;
  end record;

  procedure cu_reset (signal r : inout cu_int);

  component psl_to_kernel is
    port (
      clk_psl    : in  std_logic;
      clk_kernel : out std_logic
      );
  end component;

end package cu_snap_package;

package body cu_snap_package is
  function op2op (a : in std_logic_vector(31 downto 0)) return op_type is
  begin
    case a is
      when x"00000001" => return VECTOR_DOT;
      when x"00000002" => return VECTOR_ADD;
      when x"00000003" => return VECTOR_MULT;
      when others      => return INVALID_OP;
    end case;
  end function;

  procedure cu_reset (signal r : inout cu_int) is
  begin
    r.state <= LOAD_IDLE;

    r.operation <= INVALID_OP;

    r.element1_reads <= (others => '0');
    r.element1_data  <= (others => '0');

    r.element2_reads <= (others => '0');
    r.element2_data  <= (others => '0');

    r.element_reads_valid <= '0';

    r.element1_last <= '0';
    r.element2_last <= '0';

    r.element1_full <= '0';
    r.element2_full <= '0';

    r.element1_wren <= '0';
    r.element2_wren <= '0';

    r.element1_rst <= '1';
    r.element2_rst <= '1';

    r.element1_nonempty_sticky <= '0';
    r.element2_nonempty_sticky <= '0';

    r.filled <= '0';
  end procedure cu_reset;
end package body cu_snap_package;
