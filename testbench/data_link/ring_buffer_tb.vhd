library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.data_link_pkg.all;

entity ring_buffer_tb is

end entity ring_buffer_tb;

architecture a1 of ring_buffer_tb is
  type test_vector is record
    di_character : std_logic_vector(7 downto 0);
    ci_read      : std_logic;
    ci_adjust_position      : integer;
  end record test_vector;

  type test_vector_array is array (natural range <>) of test_vector;

  constant test_vectors : test_vector_array :=
  (
      ("00000000", '0', 0),
      ("00000001", '0', 0),
      ("00000010", '0', 0),
      ("00000011", '0', 0),
      ("00000100", '0', 0),
      ("11111111", '0', 0),
      ("00000110", '0', 0),
      ("00000111", '1', 2),
      ("00001000", '0', 0),
      ("00001001", '0', 0),
      ("11111111", '0', 0),
      ("00000001", '0', 0),
      ("00000010", '1', 0),
      ("00000011", '0', 0),
      ("00000100", '0', 0),
      ("11111111", '0', 0),
      ("00000000", '0', 0),
      ("00000000", '1', 0),
      ("01000000", '0', 0),
      ("01000000", '0', 0),
      ("11111111", '0', 0),
      ("01000000", '0', 0),
      ("01000000", '0', 0),
      ("01000000", '0', 0),
      ("01000000", '0', 0),
      ("11111111", '1', 0),
      ("01000000", '0', 0),
      ("01000000", '1', 0),
      ("01000000", '0', 0)
  );
  signal F : integer := 5;

  constant clk_period : time := 1 ns;
  signal clk : std_logic := '0';
  signal reset : std_logic := '0';
  signal ci_read : std_logic;
  signal ci_adjust_position : integer;
  signal di_character : std_logic_vector(7 downto 0);
  signal co_read : std_logic_vector(F*8-1 downto 0);
  signal co_size : integer;
  signal co_filled : std_logic;

  signal test_data_index : integer := 0;
begin  -- architecture a1
  uut : entity work.ring_buffer
    generic map (
      READ_SIZE   => F,
      BUFFER_SIZE => 2*F
    )
    port map (
      ci_clk             => clk,
      ci_reset           => reset,
      di_character       => di_character,
      ci_adjust_position => ci_adjust_position,
      ci_read            => ci_read,
      co_read            => co_read,
      co_size            => co_size,
      co_filled          => co_filled);

  clk <= not clk after clk_period/2;
  reset <= '1' after clk_period*2;

  test: process is
  begin  -- process test
    wait for clk_period*2;

    for i in test_vectors'range loop
      test_data_index <= i;
      di_character <= test_vectors(i).di_character;
      ci_read <= test_vectors(i).ci_read;
      ci_adjust_position <= test_vectors(i).ci_adjust_position;

      wait for clk_period;
    end loop;  -- i

    wait for 100 ms;
  end process test;

end architecture a1;
