library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity frame_alignment_tb is
end entity frame_alignment_tb;

architecture a1 of frame_alignment_tb is
  constant F : integer range 0 to 256 := 5;
  constant K : integer range 0 to 32 := 4;

  type test_vector is record
    ci_request_sync : std_logic;
    ci_realign : std_logic;
    di_char : character_vector;

    expected_aligned : std_logic;
    expected_error : std_logic;

  end record test_vector;

  type test_vector_array is array (natural range<>) of test_vector;
  constant test_vectors : test_vector_array :=
  (
  -- rq  scra real  kout  der mer   data   expec kout  der  mer  data       aler oct fram
    ('1', '0', ('1', '0', '0', "10111100", '0'), '0', '0'),
    ('1', '0', ('1', '0', '0', "10111100", '0'), '0', '0'),
    ('0', '0', ('1', '0', '0', "10111100", '0'), '0', '0'),
    ('0', '0', ('1', '0', '0', "10111100", '0'), '0', '0'),
    ('0', '0', ('0', '0', '0', "11000001", '1'), '0', '0'),  -- frame begins
    ('0', '0', ('0', '0', '0', "11000010", '1'), '0', '0'),
    ('0', '0', ('0', '0', '0', "11000011", '1'), '0', '0'),
    ('0', '0', ('0', '0', '0', "11000100", '1'), '0', '0'),
    ('0', '0', ('1', '0', '0', "11111100", '1'), '0', '0'),  -- frame ends
    ('0', '0', ('0', '0', '0', "00000001", '1'), '1', '0'),
    ('0', '0', ('1', '0', '0', "00000010", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00000011", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00000100", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00000000", '1'), '1', '0'),  -- frame begins
    ('0', '0', ('1', '0', '0', "11111100", '1'), '0', '1'),  -- frame begins, /A/
    ('0', '0', ('1', '0', '0', "11111100", '1'), '0', '1'),  -- frame begins, /A/
    ('0', '0', ('0', '0', '0', "01000001", '1'), '0', '1'),
    ('0', '0', ('0', '0', '0', "01000010", '1'), '0', '1'),
    ('0', '0', ('0', '0', '0', "01000011", '1'), '0', '1'),
    ('0', '0', ('0', '0', '0', "01000100", '1'), '0', '1'),
    ('0', '0', ('1', '0', '0', "11111100", '1'), '0', '1'),
    ('0', '1', ('0', '0', '0', "00100001", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00100010", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00100011", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00100100", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00000101", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00000001", '1'), '1', '0'),
    ('0', '0', ('0', '0', '0', "00000000", '1'), '1', '0')  -- frame begin
  );

  constant char_clk_period : time := 1 ns;
  constant frame_clk_period : time := 1 ns * F;

  signal char_clk : std_logic := '0';
  signal frame_clk : std_logic := '0';
  signal reset : std_logic := '0';

  signal di_char : character_vector;
  signal do_aligned_chars : std_logic_vector(8*F - 1 downto 0);
  signal co_frame_state : frame_state;

  signal ci_request_sync : std_logic;
  signal ci_realign : std_logic;
  signal co_aligned : std_logic;
  signal co_error : std_logic;

  signal test_data_index : integer := 0;

begin  -- architecture a1
  uut : entity work.frame_alignment
    generic map (
      SCRAMBLED => false,
      F         => F,
      K         => K)
    port map (
      ci_frame_clk     => frame_clk,
      ci_char_clk      => char_clk,
      ci_reset         => reset,
      ci_request_sync  => ci_request_sync,
      ci_realign       => ci_realign,
      di_char          => di_char,
      co_aligned       => co_aligned,
      co_error         => co_error,
      do_aligned_chars => do_aligned_chars,
      co_frame_state   => co_frame_state);

  clk_gen: process is
  begin -- process clk_gen
    wait for char_clk_period/2;
    char_clk <= not char_clk;
  end process clk_gen;

  frame_clk_gen: process is
  begin -- process clk_gen
    wait for frame_clk_period/2;
    frame_clk <= not frame_clk;
  end process frame_clk_gen;
  
  reset_gen: process is
  begin -- process reset_gen
    wait for char_clk_period*2;
    reset <= '1';
  end process reset_gen;

  test: process is
    variable test_vec : test_vector;
    variable prev_test_vec : test_vector;
  begin  -- process test
    wait for char_clk_period*2;

    for i in test_vectors'range loop
      test_data_index <= i;
      test_vec := test_vectors(i);
      di_char <= test_vec.di_char;
      ci_realign <= test_vec.ci_realign;
      ci_request_sync <= test_vec.ci_request_sync;

      if i > 0 then
        prev_test_vec := test_vectors(i - 1);

        assert co_aligned = prev_test_vec.expected_aligned report "The aligned does not match. Expected: " & std_logic'image(prev_test_vec.expected_aligned) &", Index: " & integer'image(i-1) severity error;
        assert co_error = prev_test_vec.expected_error report "The error does not match. Index: " & integer'image(i-1) severity error;
      end if;

      wait for char_clk_period;
    end loop;  -- i
    wait for 100 ms;
  end process test;
end architecture a1;
