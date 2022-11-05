library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;

entity an8b10bdecoder_tb is
end entity an8b10bdecoder_tb;

architecture a1 of an8b10bdecoder_tb is
  type test_vector is record
    di_10b                      : std_logic_vector(9 downto 0);
    expected_do_8b              : std_logic_vector(7 downto 0);
    expected_co_kout            : std_logic;
    expected_co_error           : std_logic;
    expected_co_missing_error   : std_logic;
    expected_co_disparity_error : std_logic;
  end record test_vector;

  type test_vector_array is array (natural range<>) of test_vector;
  constant test_vectors : test_vector_array :=
  (
    --data          exp data  kout  err miss disp
    ("0011111010", "10111100", '1', '0', '0', '0'),  -- RD = -1
    ("1100000101", "10111100", '1', '0', '0', '0'),  -- RD = +1
    ("1100000101", "10111100", '1', '1', '0', '1'),  -- RD = +1 .. wrong
    ("0011111010", "10111100", '1', '0', '0', '0'),  -- RD = -1
    ("0110001011", "00000000", '0', '0', '0', '0'),  -- RD = +1
    ("0110000101", "01000000", '0', '0', '0', '0'),  -- RD = +1
    ("1010110101", "01011111", '0', '0', '0', '0'),  -- RD = -1
    ("1010110101", "01011111", '0', '1', '0', '1'),  -- RD = -1 .. wrong
    ("0101001110", "11111111", '0', '0', '0', '0'),  -- RD = +1
    ("0101001110", "11111111", '0', '0', '0', '0'),  -- RD = +1
    ("1100010110", "11000011", '0', '0', '0', '0'),  -- RD = +1
    ("0110001100", "01100000", '0', '0', '0', '0'),  -- RD = +1
    ("1100011100", "01100011", '0', '0', '0', '0'),  -- RD = -1
    ("0000000000", "00000000", '0', '1', '1', '1'),  -- END
    ("1111111111", "00000000", '0', '1', '1', '1'),  -- END
    ("0000000000", "00000000", '0', '1', '1', '1')  -- END
  );

  constant clk_period : time := 1 ns;
  signal clk : std_logic := '0';
  signal reset : std_logic := '0';

  signal di_10b : std_logic_vector(9 downto 0) := (others => '0');
  signal do_8b : std_logic_vector(7 downto 0);

  signal co_kout : std_logic;
  signal co_error : std_logic;
  signal co_missing_error : std_logic;
  signal co_disparity_error : std_logic;

  signal test_data_index : integer := 0;
begin  -- architecture a1
  uut: entity work.an8b10b_decoder
    port map (
      ci_char_clk        => clk,
      ci_reset           => reset,
      di_10b             => di_10b,
      do_8b              => do_8b,
      co_kout            => co_kout,
      co_missing_error   => co_missing_error,
      co_disparity_error => co_disparity_error,
      co_error           => co_error);

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
      di_10b <= test_vec.di_10b;

      if i > 0 then
        prev_test_vec := test_vectors(i - 1);
        assert do_8b = prev_test_vec.expected_do_8b report "The output data does not match, expected: " & vec2str(prev_test_vec.expected_do_8b) & " got: " & vec2str(do_8b) & ", index: " & integer'image(i-1) severity error;
        assert co_kout = prev_test_vec.expected_co_kout report "The kout does not match. index: " & integer'image(i-1) severity error;
        assert co_error = prev_test_vec.expected_co_error report "The error does not match. index: " & integer'image(i-1) severity error;
        assert co_missing_error = prev_test_vec.expected_co_missing_error report "The missing error does not match. index: " & integer'image(i-1) severity error;
        assert co_disparity_error = prev_test_vec.expected_co_disparity_error report "The disparity error does not match. index: " & integer'image(i-1) severity error;
      end if;

      wait for clk_period;
    end loop;  -- i
    wait for 100 ms;
  end process test;

end architecture a1;
