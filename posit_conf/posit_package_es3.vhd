---------------------------------------------------------------------------------------------------
-- Posit Package
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.posit_common.all;

package posit_package is

  constant POSIT_NBITS : natural := 32;
  constant POSIT_ES    : natural := 3;

  -- POSIT SPECIFIC (Raw)
  subtype value is std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);

  constant value_empty : value := (POSIT_SERIALIZED_WIDTH_ES3-1 downto 1 => '0', others => '1');
  constant value_one   : value := (others                                => '0');

  subtype value_sum is std_logic_vector(POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 0);
  constant value_sum_empty : value_sum := (POSIT_SERIALIZED_WIDTH_SUM_ES3-1 downto 1 => '0', others => '1');

  subtype value_product is std_logic_vector(POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 0);
  constant value_product_empty : value_product := (POSIT_SERIALIZED_WIDTH_PRODUCT_ES3-1 downto 1 => '0', others => '1');

  subtype value_accum is std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_ES3-1 downto 0);
  constant value_accum_empty : value_accum := (POSIT_SERIALIZED_WIDTH_ACCUM_ES3-1 downto 1 => '0', others => '1');

  subtype value_accum_prod is std_logic_vector(POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3-1 downto 0);
  constant value_accum_prod_empty : value_accum_prod := (POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3-1 downto 1 => '0', others => '1');

  constant POSIT_SERIALIZED_WIDTH_ACCUM_PROD : natural := POSIT_SERIALIZED_WIDTH_ACCUM_PROD_ES3;

  function prod2val (a  : in value_product) return value;
  function sum2val (a   : in value_sum) return value;
  function accum2val (a : in value_accum) return value;

end package;

package body posit_package is
  -- Product layout:
  -- 67 1       sign
  -- 66 10      scale
  -- 56 54      fraction
  -- 2  1       inf
  -- 1  1       zero
  -- 0
  function prod2val (a : in value_product) return value is
    variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
  begin
    tmp(0)            := a(0);
    tmp(1)            := a(1);
    tmp(27 downto 2)  := a(55 downto 30);
    tmp(36 downto 28) := a(64 downto 56);
    tmp(37)           := a(66);
    assert signed(tmp(36 downto 28)) = signed(a(64 downto 56)) report "Scale loss (prod2val), val=" & integer'image(to_integer(signed(tmp(36 downto 28)))) & ", prod=" & integer'image(to_integer(signed(a(64 downto 56)))) severity error;
    return tmp;
  end function prod2val;

  -- Sum layout:
  -- 42 1       sign
  -- 41 9       scale
  -- 32 30      fraction
  -- 2  1       inf
  -- 1  1       zero
  -- 0
  function sum2val (a : in value_sum) return value is
    variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
  begin
    tmp(0)            := a(0);
    tmp(1)            := a(1);
    tmp(27 downto 2)  := a(31 downto 6);
    tmp(36 downto 28) := a(40 downto 32);
    tmp(37)           := a(41);
    assert signed(tmp(36 downto 28)) = signed(a(40 downto 32)) report "Scale loss (sum2val), val=" & integer'image(to_integer(signed(tmp(36 downto 28)))) & ", sum=" & integer'image(to_integer(signed(a(40 downto 32)))) severity error;
    return tmp;
  end function sum2val;

      -- Product Sum layout:
      -- 71 1       sign
      -- 70 10       scale
      -- 60 58     fraction
      -- 2   1       inf
      -- 1   1       zero
      -- 0
      -- function prodsum2val (a : in value_prod_sum) return value is
      --   variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
      -- begin
      --   tmp(0)            := a(0);
      --   tmp(1)            := a(1);
      --   tmp(27 downto 2)  := a(59 downto 34);
      --   tmp(36 downto 28) := a(68 downto 60);
      --   tmp(37)           := a(70);
      --   assert signed(tmp(36 downto 28)) = signed(a(68 downto 60)) report "Scale loss (prodsum2val), val=" & integer'image(to_integer(signed(tmp(36 downto 28)))) & ", sum=" & integer'image(to_integer(signed(a(68 downto 60)))) severity error;
      --   return tmp;
      -- end function prodsum2val;


  -- Accum layout:
  -- 264 1       sign
  -- 263 9       scale
  -- 254 252     fraction
  -- 2   1       inf
  -- 1   1       zero
  -- 0
  function accum2val (a : in value_accum) return value is
    variable tmp : std_logic_vector(POSIT_SERIALIZED_WIDTH_ES3-1 downto 0);
  begin
    tmp(0)            := a(0);
    tmp(1)            := a(1);
    tmp(27 downto 2)  := a(253 downto 228);
    tmp(36 downto 28) := a(262 downto 254);
    tmp(37)           := a(263);
    assert signed(tmp(36 downto 28)) = signed(a(262 downto 254)) report "Scale loss (accum2val), val=" & integer'image(to_integer(signed(tmp(36 downto 28)))) & ", sum=" & integer'image(to_integer(signed(a(262 downto 254)))) severity error;
    return tmp;
  end function accum2val;

  -- Accum Product layout:
  -- 265 1       sign
  -- 264 10      scale
  -- 254 252     fraction
  -- 2   1       inf
  -- 1   1       zero
  -- 0

end package body;
