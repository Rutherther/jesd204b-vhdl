library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.data_link_pkg.all;

entity frame_alignment_tb is
end entity frame_alignment_tb;

architecture a1 of frame_alignment_tb is
  type test_vector is record
    ci_request_sync : std_logic;
    ci_scrambled : std_logic;
    ci_enable_realign : std_logic;
    di_char : character_vector;

    expected_char : frame_character;
    expected_aligned : std_logic;
    expected_misaligned : std_logic;

  end record test_vector;

  type test_vector_array is array (natural range<>) of test_vector;
  constant test_vectors : test_vector_array :=
  (
  -- rq  scra real  kout  der mer   data   expec kout  der  mer  data       almisal oct fram
    ('0', '0', '0', ('1', '0', '0', "10111100", '0'), ('1', '0', '0', "10111100", 0, 0, '0'), '0', '0'),
    ('0', '0', '0', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 0, 0, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "10101010", '0'), ('0', '0', '0', "10101010", 1, 0, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "01010101", '0'), ('0', '0', '0', "01010101", 2, 0, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "01010101", '0'), ('0', '0', '0', "01010101", 3, 0, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "01010101", '0'), ('0', '0', '0', "01010101", 4, 0, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "11111111", '0'), ('0', '0', '0', "11111111", 0, 1, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "11111111", '0'), ('0', '0', '0', "11111111", 1, 1, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "11111111", '0'), ('0', '0', '0', "11111111", 2, 1, '0'), '1', '0'),
    ('0', '0', '0', ('0', '0', '0', "11111111", '0'), ('0', '0', '0', "11111111", 3, 1, '0'), '1', '0'),
    ('0', '0', '0', ('1', '0', '0', "11111100", '0'), ('0', '0', '0', "01010101", 4, 1, '0'), '1', '0'),
    ('0', '0', '0', ('1', '0', '0', "11111100", '0'), ('0', '0', '0', "01010101", 0, 2, '0'), '1', '0'),
    ('0', '0', '0', ('1', '0', '0', "11111100", '0'), ('0', '0', '0', "01010101", 1, 2, '0'), '0', '1'),
    ('0', '0', '0', ('0', '0', '0', "11110000", '0'), ('0', '0', '0', "11110000", 2, 2, '0'), '0', '1'),
    ('0', '0', '0', ('0', '0', '0', "11110000", '0'), ('0', '0', '0', "11110000", 3, 2, '0'), '0', '1'),
    ('0', '0', '0', ('1', '0', '0', "11111100", '0'), ('0', '0', '0', "01010101", 4, 2, '0'), '1', '0'),
    ('1', '1', '1', ('0', '0', '0', "11111100", '0'), ('0', '0', '0', "11111100", 0, 0, '0'), '0', '0'),
    ('0', '1', '1', ('1', '0', '0', "10111100", '0'), ('1', '0', '0', "10111100", 0, 0, '0'), '0', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 0, 0, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 1, 0, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 2, 0, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 3, 0, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 4, 0, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 0, 1, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 1, 1, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 2, 1, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "00000000", '0'), ('0', '0', '0', "00000000", 3, 1, '0'), '1', '0'),
    ('0', '1', '1', ('1', '0', '0', "11111100", '0'), ('0', '0', '0', "11111100", 4, 1, '0'), '1', '0'),
    ('0', '1', '1', ('1', '0', '0', "01111100", '0'), ('0', '0', '0', "01111100", 0, 2, '0'), '1', '0'),
    ('0', '1', '1', ('1', '0', '0', "01111100", '0'), ('0', '0', '0', "01111100", 4, 2, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "11111111", '0'), ('0', '0', '0', "11111111", 0, 3, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "11111111", '0'), ('0', '0', '0', "11111111", 1, 3, '0'), '1', '0'),
    ('0', '1', '1', ('0', '0', '0', "11111111", '0'), ('0', '0', '0', "11111111", 2, 3, '0'), '1', '0')
  );

  constant clk_period : time := 1 ns;

  constant F : integer range 0 to 256 := 5;
  constant K : integer range 0 to 32 := 4;

  signal clk : std_logic := '0';
  signal reset : std_logic := '0';

  signal di_char : character_vector;
  signal do_char : frame_character;

  signal ci_request_sync : std_logic;
  signal ci_enable_realign : std_logic;
  signal ci_scrambled : std_logic;
  signal co_aligned : std_logic;
  signal co_misaligned : std_logic;

  signal test_data_index : integer := 0;

begin  -- architecture a1
  uut : entity work.frame_alignment
    port map (
      ci_char_clk       => clk,
      ci_reset          => reset,
      ci_F              => F,
      ci_K              => K,
      ci_scrambled      => ci_scrambled,
      ci_request_sync   => ci_request_sync,
      ci_enable_realign => ci_enable_realign,
      di_char           => di_char,
      co_aligned        => co_aligned,
      co_misaligned     => co_misaligned,
      do_char           => do_char);

  clk <= not clk after clk_period/2;
  reset <= '1' after clk_period*2;

  test: process is
    variable test_vec : test_vector;
    variable prev_test_vec : test_vector;
  begin  -- process test
    wait for clk_period*2;

    for i in test_vectors'range loop
      test_data_index <= i;
      test_vec := test_vectors(i);
      di_char <= test_vec.di_char;
      ci_scrambled <= test_vec.ci_scrambled;
      ci_enable_realign <= test_vec.ci_enable_realign;
      ci_request_sync <= test_vec.ci_request_sync;

      if i > 0 then
        prev_test_vec := test_vectors(i - 1);

        assert co_aligned = prev_test_vec.expected_aligned report "The aligned does not match. Expected: " & std_logic'image(prev_test_vec.expected_aligned) &", Index: " & integer'image(i-1) severity error;
        assert co_misaligned = prev_test_vec.expected_misaligned report "The misaligned does not match. Index: " & integer'image(i-1) severity error;
        assert do_char = prev_test_vec.expected_char report "The character does not match. Index: " & integer'image(i-1) severity error;
      end if;

      wait for clk_period;
    end loop;  -- i
    wait for 100 ms;
  end process test;
end architecture a1;
