library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;

entity char_alignment_tb is
end entity char_alignment_tb;


architecture a1 of char_alignment_tb is
  type data_array is array (0 to 200) of std_logic_vector(9 downto 0);
  type test_vector is record            -- A vector for testing
    data_count      : integer;          -- The count of 10b encoded data
    data : data_array;
    synced_after    : integer;  -- The amount of clock cycles to turn synced to 1 after
    expected_data : data_array;
    expected_aligned_after   : integer;  -- The amount of clock cycles after the aligned should be 1
    expected_alignment_index : integer;  -- The correct alignment index to be set after aligned_after clock cyles
  end record test_vector;

  type test_vector_array is array (natural range <>) of test_vector;
  constant test_vectors : test_vector_array := (
    (
      data_count => 10,
      synced_after => 4,
      expected_aligned_after => 4,
      expected_alignment_index => 0,
      data => (0 => "0011111010", 1 => "0000000000", 2 => "1111111111", 3 => "0101010101", 4 => "1111100000", 5 => "0000011111", others => "0000000000"),
      expected_data => (0 => "0011111010", 1 => "0000000000", 2 => "1111111111", 3 => "0101010101", 4 => "1111100000", 5 => "0000011111", others => "0000000000")
    ),
    (
      data_count => 10,
      synced_after => 4,
      expected_aligned_after => 4,
      expected_alignment_index => 1,
      data => (0 => "0111110100", 1 => "0000010100", 2 => "1010101011", 3 => "0101010101", 4 => "1111000000", 5 => "0000111110", 6 => "0000000000", others => "0000000000"),
      expected_data => (0 => "0011111010", 1 => "0000001010", 2 => "0101010101", 3 => "1010101010", 4 => "1111100000", 5 => "0000011111", others => "0000000000")
    )
  );

  constant clk_period : time := 1 ns;    -- The clock period

  signal clk : std_logic := '0';        -- The clock
  signal reset : std_logic := '0';      -- The reset

  signal ci_synced : std_logic := '0';     -- Whether synced
  signal di_10b : std_logic_vector(9 downto 0) := (others => '0');  -- The 10b data input
  signal do_10b : std_logic_vector(9 downto 0);
  signal co_aligned : std_logic;

  signal test_data_index : integer := 0;
  signal cycle_num : integer := 0;

begin  -- architecture a1
  uut : entity work.char_alignment
    port map (
      ci_link_clk => clk,
      ci_reset    => reset,
      di_chars    => di_10b,
      do_chars    => do_10b,
      ci_synced   => ci_synced,
      co_aligned  => co_aligned);

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
  begin  -- process test
    wait for clk_period*3;
    for i in test_vectors'range loop
      test_vec := test_vectors(i);
      test_data_index <= i;

      for cycle in 0 to test_vectors(i).data_count loop
        cycle_num <= cycle;
        di_10b <= test_vec.data(cycle);
        if cycle >= test_vec.synced_after then
          ci_synced <= '1';
        else
          ci_synced <= '0';
        end if;

        if cycle = test_vec.expected_aligned_after then
          assert (co_aligned = '1') report "Not aligned after " & integer'image(test_vec.expected_aligned_after) & ", index: " & integer'image(i) severity error;
        end if;

        if cycle >= test_vec.synced_after then
          assert (do_10b = test_vec.expected_data(cycle - 2)) report "The data does not match, data index: " & integer'image(i) & ", expected: " & vec2str(test_vec.expected_data(cycle - 2)) & ", got: " & vec2str(do_10b) severity error;
        end if;

        wait for clk_period;
      end loop;  -- cycle
    end loop;  -- i
  end process test;
end architecture a1;
