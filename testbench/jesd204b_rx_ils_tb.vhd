library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.jesd204b_pkg.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity jesd204b_rx_ils_tb is
end entity jesd204b_rx_ils_tb;

architecture a1 of jesd204b_rx_ils_tb is
  constant K            : integer := 3;
  constant CS           : integer := 0;
  constant M            : integer := 2;  -- Count of converters
  constant S            : integer := 1;  -- Count of samples
  constant L            : integer := 2;  -- Count of lanes
  constant F            : integer := 6;  -- Count of octets in a frame per lane
  constant CF           : integer := 1;  -- Count of control word bits
  constant N            : integer := 4;  -- Sample size
  constant Nn           : integer := 4;

  type octet_data is record
    data : std_logic_vector(7 downto 0);
    k : std_logic;
  end record octet_data;

  type lane_data_array is array (natural range <>) of octet_data;
  type test_vector is record
    data : lane_data_array(0 to L-1);
  end record test_vector;

  type test_vector_array is array (natural range <>) of test_vector;

  constant char_offset : integer := 2;
  constant char_prepend : std_logic_vector(char_offset-1 downto 0) := "00";
  constant test_vectors : test_vector_array :=
  (
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("00011100", '1'), ("00011100", '1'))), -- 1st ILAS multiframe start
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("01111100", '1'), ("01111100", '1'))), -- 1st ILAS multiframe end
    (data => (("00011100", '1'), ("00011100", '1'))), -- 2nd ILAS multiframe start
    (data => (("10011100", '1'), ("10011100", '1'))), -- configuration start delimiter
    (data => (("10101010", '0'), ("10101010", '0'))), -- DID
    (data => (("01111110", '0'), ("01111110", '0'))), -- ADJCNT,BID
    (data => (("01101010", '0'), ("01101010", '0'))), -- X,ADJDIR,PHADJ,LID
    (data => (("11011110", '0'), ("11011110", '0'))), -- SCR,X,L
    (data => (("11001100", '0'), ("11001100", '0'))), -- F
    (data => (("01011111", '0'), ("01011111", '0'))), -- X, K
    (data => (("00110011", '0'), ("00110011", '0'))), -- M
    (data => (("10000011", '0'), ("10000011", '0'))), -- CS,X,N
    (data => (("00111101", '0'), ("00111101", '0'))), -- SUBCLASSV,Nn
    (data => (("00000000", '0'), ("00000000", '0'))), -- JESDV,S
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("01111100", '1'), ("01111100", '1'))), -- 2nd ILAS multiframe end
    (data => (("00011100", '1'), ("00011100", '1'))), -- 3rd ILAS multiframe start
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("01111100", '1'), ("01111100", '1'))), -- 3rd ILAS multiframe end
    (data => (("00011100", '1'), ("00011100", '1'))), -- 4th ILAS multiframe start
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("00000000", '0'), ("00000000", '0'))),
    (data => (("01111100", '1'), ("01111100", '1'))), -- 4th ILAS multiframe end
    (data => (("00000000", '0'), ("00000000", '0'))),  -- data
    (data => (("11111111", '0'), ("11111111", '0')))
  );

  constant char_clk_period : time := 1 ns;    -- The clock period
  constant frame_clk_period : time := 1 ns * F;    -- The clock period

  signal di_data : lane_input_array(L-1 downto 0);
  signal di_lane_data : lane_data_array(L-1 downto 0);

  signal char_clk : std_logic := '0';        -- The clock
  signal frame_clk : std_logic := '0';        -- The clock
  signal reset : std_logic := '0';      -- The reset

  signal test_vec_index : integer := 0;

  signal co_nsynced : std_logic;
  signal co_error : std_logic;
  signal do_samples : samples_array (M-1 downto 0, S-1 downto 0)(N-1 downto 0);
  signal do_ctrl_bits : ctrl_bits_array (M-1 downto 0, S-1 downto 0)(CS-1 downto 0);
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
      ci_char_clk       => char_clk,
      ci_frame_clk      => frame_clk,
      ci_multiframe_clk => '0',
      ci_reset          => reset,
      ci_request_sync   => '0',
      di_data           => di_data,
      co_nsynced        => co_nsynced,
      co_error          => co_error,
      do_samples        => do_samples,
      do_ctrl_bits      => do_ctrl_bits,
      co_correct_data   => co_correct_data);

  encoders: for i in 0 to L-1 generate
    encoder: entity work.an8b10b_encoder
      port map (
        reset   => reset,
        clk     => char_clk,
        ena     => '1',
        KI      => di_lane_data(i).k,
        datain  => di_lane_data(i).data,
        dataout => di_data(i));
  end generate encoders;

  char_clk <= not char_clk after char_clk_period/2;
  frame_clk <= not frame_clk after frame_clk_period/2;
  reset <= '1' after char_clk_period*2;

  test: process is
  begin  -- process test
    wait for char_clk_period*2;

    for i in test_vectors'range loop
      test_vec_index <= i;
      di_lane_data <= test_vectors(i).data;
      wait for char_clk_period;
    end loop;  -- i

    wait for 1000 ms;
  end process test;
end architecture a1;
