library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.jesd204b_pkg.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity jesd204b_rx_kchars_tb is
end entity jesd204b_rx_kchars_tb;

-- first send some zeros
-- then just send k28.3 indefinitely

architecture a1 of jesd204b_rx_kchars_tb is
  constant K            : integer := 5;
  constant CS           : integer := 0;
  constant M            : integer := 2;  -- Count of converters
  constant S            : integer := 1;  -- Count of samples
  constant L            : integer := 2;  -- Count of lanes
  constant F            : integer := 5;  -- Count of octets in a frame per lane
  constant CF           : integer := 1;  -- Count of control word bits
  constant N            : integer := 4;  -- Sample size
  constant Nn           : integer := 4;

  type test_vector is record
    data : lane_input_array(0 to L-1);
  end record test_vector;

  type test_vector_array is array (natural range <>) of test_vector;

  constant char_offset : integer := 2;
  constant char_prepend : std_logic_vector(char_offset-1 downto 0) := "00";
  constant test_vectors : test_vector_array :=
  (
    (data => ("0000000000", "0000000000")),
    (data => ("0000000000", "0000000000")),
    (data => ("0000000000", "0000000000")),
    (data => ("0000000000", "0000000000")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101")),
    (data => ("0011111010", "0011111010")),
    (data => ("1100000101", "1100000101"))
  );

  constant char_clk_period : time := 1 ns;    -- The clock period
  constant frame_clk_period : time := 1 ns * F;    -- The clock period

  signal di_transceiver_data : lane_input_array(L-1 downto 0);

  signal char_clk : std_logic := '0';        -- The clock
  signal frame_clk : std_logic := '0';        -- The clock
  signal reset : std_logic := '0';      -- The reset

  signal test_vec_index : integer := 0;

  signal co_nsynced : std_logic;
  signal co_error : std_logic;
  signal do_samples : samples_array (M-1 downto 0, S-1 downto 0)
    (data(N - 1 downto 0), ctrl_bits(CS - 1 downto 0));
  signal co_correct_data : std_logic;

begin  -- architecture a1
  uut : entity work.jesd204b_link_rx
    generic map (
      K  => K,
      CS => CS,
      M  => M,
      S  => S,
      L  => L,
      F  => F,
      CF => CF,
      N  => N,
      Nn => Nn)
    port map (
      ci_char_clk         => char_clk,
      ci_frame_clk        => frame_clk,
      ci_multiframe_clk   => '0',
      ci_reset            => reset,
      ci_request_sync     => '0',
      di_transceiver_data => di_transceiver_data,
      co_nsynced          => co_nsynced,
      co_error            => co_error,
      do_samples          => do_samples,
      co_correct_data     => co_correct_data);

  char_clk <= not char_clk after char_clk_period/2;
  frame_clk <= not frame_clk after frame_clk_period/2;
  reset <= '1' after char_clk_period*2;

  test: process is
  begin  -- process test
    wait for char_clk_period*2;

    for i in test_vectors'range loop
      test_vec_index <= i;
      if i = 0 then
        for c in 0 to L-1 loop
          di_transceiver_data(c) <= char_prepend & test_vectors(0).data(c)(9 downto char_offset);
        end loop;  -- l
      else
        for c in 0 to L-1 loop
          di_transceiver_data(c) <= test_vectors(i-1).data(c)(char_offset - 1 downto 0) & test_vectors(i).data(c)(9 downto char_offset);
        end loop;  -- l
      end if;
      wait for char_clk_period;
    end loop;  -- i

    wait for 1000 ms;
  end process test;
end architecture a1;
