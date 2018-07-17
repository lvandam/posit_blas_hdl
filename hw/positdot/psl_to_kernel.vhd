library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity psl_to_kernel is
  port (
     clk_psl            : in  std_logic;
     clk_kernel         : out std_logic
  );
end psl_to_kernel;

architecture rtl of psl_to_kernel is
    signal clk : std_logic := '0';
begin
  process(clk_psl)
  begin
    if rising_edge(clk_psl) then
      clk <= not(clk);
    end if;
    clk_kernel <= clk;
  end process;
end architecture rtl;
