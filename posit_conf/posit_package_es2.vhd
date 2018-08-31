---------------------------------------------------------------------------------------------------
-- Posit Package
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.posit_common.all;

package posit_package is

  constant POSIT_NBITS            : natural := 32;
  constant POSIT_ES               : natural := 2;

  -- POSIT SPECIFIC (Raw)
  subtype value is std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);

  constant value_empty : value := (POSIT_SERIALIZED_WIDTH_ES2-1 downto 1 => '0', others => '1');
  constant value_one   : value := (others                                => '0');

  subtype value_sum is std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 0);
  constant value_sum_empty : value_sum := (POSIT_SERIALIZED_WIDTH_SUM_ES2-1 downto 1 => '0', others => '1');

  subtype value_product is std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 0);
  constant value_product_empty : value_product := (POSIT_SERIALIZED_WIDTH_PRODUCT_ES2-1 downto 1 => '0', others => '1');

  subtype value_accum is std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1 downto 0);
  constant value_accum_empty : value_accum := (POSIT_SERIALIZED_WIDTH_ACCUM_ES2-1 downto 1 => '0', others => '1');

  subtype value_accum_prod is std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1 downto 0);
  constant value_accum_prod_empty : value_accum_prod := (POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2-1 downto 1 => '0', others => '1');

  constant POSIT_SERIALIZED_WIDTH_ACCUM_PROD : natural := POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES2;

  function prod2val (a : in value_product) return value;
  function sum2val (a  : in value_sum) return value;
  function accum2val (a : in value_accum) return value;
  -- function prodsum2val (a : in value_prod_sum) return value;

end package;

package body posit_package is
  -- Product layout:
  -- 68 1       sign
  -- 67 9       scale
  -- 58 56      fraction
  -- 2  1       inf
  -- 1  1       zero
  -- 0
  function prod2val (a : in value_product) return value is
    variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
  begin
    tmp(0)            := a(0);
    tmp(1)            := a(1);
    tmp(28 downto 2)  := a(57 downto 31);
    tmp(36 downto 29) := a(65 downto 58);
    tmp(37)           := a(67);
    assert signed(tmp(36 downto 29)) = signed(a(65 downto 58)) report "Scale loss (prod2val), val=" & integer'image(to_integer(signed(tmp(36 downto 29)))) & ", prod=" & integer'image(to_integer(signed(a(65 downto 58)))) severity error;
    return tmp;
  end function prod2val;

  -- Sum layout:
  -- 42 1       sign
  -- 41 8       scale
  -- 33 31      fraction
  -- 2  1       inf
  -- 1  1       zero
  -- 0
  function sum2val (a : in value_sum) return value is
    variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
  begin
    tmp(0)            := a(0);
    tmp(1)            := a(1);
    tmp(28 downto 2)  := a(32 downto 6);
    tmp(36 downto 29) := a(40 downto 33);
    tmp(37)           := a(41);
    assert signed(tmp(36 downto 29)) = signed(a(40 downto 33)) report "Scale loss (sum2val), val=" & integer'image(to_integer(signed(tmp(36 downto 29)))) & ", sum=" & integer'image(to_integer(signed(a(40 downto 33)))) severity error;
    return tmp;
  end function sum2val;

    -- Product Sum layout:
    -- 72 1       sign
    -- 71 9       scale
    -- 62 60     fraction
    -- 2   1       inf
    -- 1   1       zero
    -- 0
    -- function prodsum2val (a : in value_prod_sum) return value is
    --   variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
    -- begin
    --   tmp(0)            := a(0);
    --   tmp(1)            := a(1);
    --   tmp(28 downto 2)  := a(61 downto 35);
    --   tmp(36 downto 29) := a(69 downto 62);
    --   tmp(37)           := a(71);
    --   assert signed(tmp(36 downto 29)) = signed(a(69 downto 62)) report "Scale loss (prodsum2val), val=" & integer'image(to_integer(signed(tmp(36 downto 29)))) & ", sum=" & integer'image(to_integer(signed(a(69 downto 62)))) severity error;
    --   return tmp;
    -- end function prodsum2val;

    -- Product Sum layout:
    -- 72 1       sign
    -- 71 9       scale
    -- 62 60     fraction
    -- 2   1       inf
    -- 1   1       zero
    -- 0
    -- function prodsum2val (a : in value_prod_sum) return value is
    --   variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES2-1 downto 0);
    -- begin
    --   tmp(0)            := a(0);
    --   tmp(1)            := a(1);
    --   tmp(28 downto 2)  := a(61 downto 35);
    --   tmp(36 downto 29) := a(69 downto 62);
    --   tmp(37)           := a(71);
    --   assert signed(tmp(36 downto 29)) = signed(a(69 downto 62)) report "Scale loss (prodsum2val), val=" & integer'image(to_integer(signed(tmp(36 downto 29)))) & ", sum=" & integer'image(to_integer(signed(a(69 downto 62)))) severity error;
    --   return tmp;
    -- end function prodsum2val;

  -- Accum layout:
  -- 158 1       sign
  -- 157 8       scale
  -- 149 147     fraction
  -- 2   1       inf
  -- 1   1       zero
  -- 0
  function accum2val (a : in value_accum) return value is
    variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
  begin
    tmp(0)            := a(0);
    tmp(1)            := a(1);
    tmp(28 downto 2)  := a(148 downto 122);
    tmp(36 downto 29) := a(156 downto 149);
    tmp(37)           := a(157);
    assert signed(tmp(36 downto 29)) = signed(a(156 downto 149)) report "Scale loss (accum2val), val=" & integer'image(to_integer(signed(tmp(36 downto 29)))) & ", sum=" & integer'image(to_integer(signed(a(156 downto 149)))) severity error;
    return tmp;
  end function accum2val;

  -- Accum Product layout:
  -- 159 1       sign
  -- 158 9       scale
  -- 149 147     fraction
  -- 2   1       inf
  -- 1   1       zero
  -- 0

end package body;
