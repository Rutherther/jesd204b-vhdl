library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.jesd204b_pkg.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity jesd204b_multipoint_rx_data_tb is
end entity jesd204b_multipoint_rx_data_tb;

architecture a1 of jesd204b_multipoint_rx_data_tb is
  constant LANES : integer := 2;
  constant LINKS : integer := 2;
  constant F : integer := 2;
  constant K : integer := 9;
  constant CONFIG : link_config_array(0 to LINKS - 1) :=
  (
    (0, '0', 0, 0, 2, 0, 2, '0', 1, 9, 1, 0, 1, 14, 16, '0', 1, '0', 0, "00000000", "00000000", "000000000", 0),
    (0, '0', 0, 0, 2, 0, 2, '0', 1, 9, 1, 0, 1, 14, 16, '0', 1, '0', 0, "00000000", "00000000", "000000000", 0)
  );

  type octet_data is record
    data : std_logic_vector(7 downto 0);
    k : std_logic;
  end record octet_data;

  type lane_data_array is array (natural range <>) of octet_data;
  type test_vector is record
    data : lane_data_array(0 to LANES-1);
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
    (data => (("10111100", '1'), ("10111100", '1'))),
    (data => (("10111100", '1'), ("10111100", '1'))),
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
    (data => (("10101010", '0'), ("01010101", '0'))),  -- data
    (data => (("10101001", '0'), ("01010110", '0'))),
    (data => (("11111111", '0'), ("00000000", '0'))),  -- data
    (data => (("11111110", '0'), ("00000001", '0'))),
    (data => (("00000001", '0'), ("11111110", '0'))),  -- data
    (data => (("11111111", '0'), ("00000000", '0')))
  );

  constant char_clk_period : time := 1 ns;    -- The clock period
  constant frame_clk_period : time := 1 ns * CONFIG(0).F;    -- The clock period
  constant sysref_period : time := char_clk_period * CONFIG(0).K * CONFIG(0).F;    -- The clock period

  signal di_data : lane_input_array(0 to LANES-1);
  signal di_lane_data : lane_data_array(0 to LANES-1);

  signal sysref    : std_logic := '0';
  signal char_clk  : std_logic := '0';  -- The clock
  signal frame_clk : std_logic := '0';  -- The clock
  signal reset     : std_logic := '0';  -- The reset

  signal test_vec_index : integer := 0;

  signal co_nsynced : std_logic;
  signal co_error : std_logic;
  signal do_samples : simple_samples_array (0 to 1) (0 to CONFIG(0).M - 1, 0 to CONFIG(0).S - 1)
    (data(CONFIG(0).N - 1 downto 0), ctrl_bits(CONFIG(0).CS - 1 downto 0));
  signal co_correct_data : std_logic;

begin  -- architecture a1
  uut : entity work.jesd204b_multipoint_link_rx
    generic map (
      DATA_RATE => 10,
      MULTIFRAME_RATE => F*K,
      RX_BUFFER_DELAY => 6,
      LINKS      => LINKS,
      LANES      => LANES,
      CONVERTERS => 2,
      CONFIG     => CONFIG)
    port map (
      ci_device_clk       => char_clk,
      ci_char_clk         => char_clk,
      ci_frame_clk        => frame_clk,
      ci_sysref           => sysref,
      ci_reset            => reset,
      ci_request_sync     => '0',
      di_data => di_data,
      co_nsynced          => co_nsynced,
      co_error            => co_error,
      do_samples          => do_samples,
      co_correct_data     => co_correct_data);

  encoders: for i in 0 to LANES-1 generate
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
  sysref <= not sysref after sysref_period/2;
  reset <= '1' after char_clk_period*2;

  frame_clk_gen: process is
  begin  -- process frame_clk_gen
    wait for char_clk_period/2;

    while true loop
      frame_clk <= not frame_clk;
      wait for frame_clk_period/2;
    end loop;
  end process frame_clk_gen;

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
