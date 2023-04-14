library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.data_link_pkg.all;

entity lane_alignment_tb is
end entity lane_alignment_tb;

architecture a1 of lane_alignment_tb is
  type test_vector is record
    ci_state : link_state;
    ci_start : std_logic;
    di_char  : link_character;

    expected_char : link_character;
    expected_ready : std_logic;
    expected_aligned : std_logic;
    expected_error : std_logic;

  end record test_vector;

  type test_vector_array is array (natural range<>) of test_vector;
  constant test_vectors : test_vector_array :=
  (
   --st   star  kout  der mer   data  userd expect kout  der mer   data       ready align err
    (INIT, '0', ('0', '0', '0', "00000000", '0'), ('1', '0', '0', "10111100", '0'), '0', '0', '0'),
    (CGS,  '0', ('1', '0', '0', "10111100", '0'), ('1', '0', '0', "10111100", '0'), '0', '0', '0'),
    (CGS,  '0', ('1', '0', '0', "10111100", '0'), ('1', '0', '0', "10111100", '0'), '0', '0', '0'),
    (CGS,  '0', ('1', '0', '0', "10111100", '0'), ('1', '0', '0', "10111100", '0'), '0', '0', '0'),
    (CGS,  '0', ('1', '0', '0', "10111100", '0'), ('1', '0', '0', "10111100", '0'), '0', '0', '0'),
    (ILS,  '0', ('1', '0', '0', "00011100", '0'), ('1', '0', '0', "10111100", '0'), '1', '0', '0'),
    (ILS,  '0', ('0', '0', '0', "00000000", '0'), ('1', '0', '0', "10111100", '0'), '1', '0', '0'),
    (ILS,  '0', ('0', '0', '0', "00000001", '0'), ('1', '0', '0', "10111100", '0'), '1', '0', '0'),
    (ILS,  '0', ('0', '0', '0', "00000010", '0'), ('1', '0', '0', "10111100", '0'), '1', '0', '0'),
    (DATA, '1', ('0', '0', '0', "00000011", '0'), ('1', '0', '0', "00011100", '0'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00000100", '0'), ('0', '0', '0', "00000000", '0'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00000101", '0'), ('0', '0', '0', "00000001", '0'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00000110", '0'), ('0', '0', '0', "00000010", '0'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00000111", '0'), ('0', '0', '0', "00000011", '1'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00001000", '0'), ('0', '0', '0', "00000100", '1'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00001001", '0'), ('0', '0', '0', "00000101", '1'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00001010", '0'), ('0', '0', '0', "00000110", '1'), '1', '1', '0'),
    (DATA, '1', ('0', '0', '0', "00001011", '0'), ('0', '0', '0', "00000111", '1'), '1', '1', '0')
  );

  constant clk_period : time := 1 ns;

  constant F : integer range 0 to 256 := 5;
  constant K : integer range 0 to 32 := 4;

  signal clk : std_logic := '0';
  signal reset : std_logic := '0';

  signal ci_start : std_logic := '0';
  signal ci_state : link_state := INIT;

  signal di_char : link_character;
  signal do_char : link_character;

  signal co_aligned : std_logic;
  signal co_error : std_logic;
  signal co_ready : std_logic := '0';

  signal test_data_index : integer := 0;

begin  -- architecture a1
  uut : entity work.lane_alignment
    generic map (
      F => F,
      K => K)
    port map (
      ci_char_clk => clk,
      ci_reset    => reset,
      ci_start    => ci_start,
      ci_state    => ci_state,
      di_char     => di_char,
      co_aligned  => co_aligned,
      co_error    => co_error,
      co_ready    => co_ready,
      do_char     => do_char,
      ci_realign  => '0');

  clk_gen: process is
  begin -- process clk_gen
    wait for clk_period/2;
	 clk <= not clk;
  end process clk_gen;
  
  reset_gen: process is
  begin -- process reset_gen
    wait for clk_period*2;
    reset <= '1';
  end process reset_gen;

  test: process is
    variable test_vec : test_vector;
    variable prev_test_vec : test_vector;
  begin  -- process test
    wait for clk_period*2;

    for i in test_vectors'range loop
      test_data_index <= i;
      test_vec := test_vectors(i);
      di_char <= test_vec.di_char;
      ci_start <= test_vec.ci_start;
      ci_state <= test_vec.ci_state;

      if i > 0 then
        prev_test_vec := test_vectors(i - 1);

        assert co_aligned = prev_test_vec.expected_aligned report "The aligned does not match. Expected: " & std_logic'image(prev_test_vec.expected_aligned) &", Index: " & integer'image(i-1) severity error;
        assert co_error = prev_test_vec.expected_error report "The error does not match. Index: " & integer'image(i-1) severity error;
        assert co_ready = prev_test_vec.expected_ready report "The ready does not match. Index: " & integer'image(i-1) severity error;
        assert do_char = prev_test_vec.expected_char report "The character does not match. Index: " & integer'image(i-1) severity error;
      end if;

      wait for clk_period;
    end loop;  -- i
    wait for 100 ms;
  end process test;
end architecture a1;
