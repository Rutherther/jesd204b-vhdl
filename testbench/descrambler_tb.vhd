library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.data_link_pkg.all;

entity descrambler_tb is
end entity descrambler_tb;

architecture a1 of descrambler_tb is
  constant clk_period : time := 1 ns;    -- The clock period

  signal clk : std_logic := '0';        -- The clock
  signal reset : std_logic := '0';      -- The reset

  signal di_char : frame_character;
  signal do_char : frame_character;

begin  -- architecture a1
  uut: entity work.descrambler
    port map (
      di_char =>  di_char,
      do_char => do_char,
      ci_reset => reset,
      ci_char_clk => clk
    );

  clk <= not clk after clk_period/2;
  reset <= '1' after clk_period*2;

  test: process is
  begin  -- process test
    wait for 200 ms;
  end process test;
end architecture a1;
