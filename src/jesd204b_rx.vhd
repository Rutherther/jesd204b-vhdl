library ieee;
use ieee.std_logic_1164.all;
use work.transport_pkg.all;
use work.data_link_pkg.all;
use work.jesd204b_pkg.all;

entity jesd204b_rx is
  generic (
    K_character  : std_logic_vector(7 downto 0) := "10111100";
    R_character  : std_logic_vector(7 downto 0) := "00011100";
    A_character  : std_logic_vector(7 downto 0) := "01111100";
    Q_character  : std_logic_vector(7 downto 0) := "10011100";
    K            : integer                      := 1;
    CS           : integer                      := 1;  -- Number of control bits per sample
    M            : integer                      := 1;  -- Number of converters
    S            : integer                      := 1;  -- Number of samples
    L            : integer                      := 1;  -- Number of lanes
    F            : integer                      := 2;  -- Number of octets in a frame
    CF           : integer                      := 0;  -- Number of control words
    N            : integer                      := 12;  -- Size of a sample
    Nn           : integer                      := 16;  -- Size of a word (sample + ctrl if CF
    ERROR_CONFIG : error_handling_config        := (2, 0, 5, 5, 5);
    SCRAMBLING   : std_logic                    := '0');
  port (
    ci_char_clk  : in std_logic;
    ci_frame_clk : in std_logic;
    ci_reset     : in std_logic;

    co_lane_config : out link_config;
    co_nsynced     : out std_logic;
    co_error       : out std_logic;

    di_transceiver_data : in  lane_input_array(L-1 downto 0);
    do_samples          : out samples_array(M - 1 downto 0, S - 1 downto 0);
    co_correct_data     : out std_logic);
end entity jesd204b_rx;

architecture a1 of jesd204b_rx is
  -- == DATA LINK ==
  -- outputs
  signal data_link_ready_vector : std_logic_vector(L-1 downto 0) := (others => '0');
  signal data_link_synced_vector : std_logic_vector(L-1 downto 0) := (others => '0');
  signal data_link_chars_array : frame_character_array(0 to L-1);
  -- inputs
  signal data_link_start : std_logic := '0';

  -- == DESCRAMBLER ==
  signal scrambler_chars_array : frame_character_array(0 to L-1);

  -- == TRANSPORT ==
  signal transport_chars_array : frame_character_array(0 to L-1);

  type lane_configs_array is array (0 to L-1) of link_config;
  signal lane_configuration_array : lane_configs_array;

  signal all_ones : std_logic_vector(L-1 downto 0) := (others => '0');

  function ConfigsMatch (
    config_array : lane_configs_array)
    return std_logic is
    variable matches : std_logic := '1';
  begin  -- function ConfigsMatch
    for i in 0 to L-2 loop
      if config_array(i) /= config_array(i+1) then
        matches := '0';
      end if;

      return matches;
    end loop;  -- i
  end function ConfigsMatch;
begin  -- architecture a1
  -- nsynced is active LOW, set '0' if all ready
  co_nsynced <= '0' when data_link_synced_vector = all_ones else '1';
  -- choose the first config.
  co_lane_config <= lane_configuration_array(0);

  -- start lanes data after all are ready
  data_link_start <= '1' when data_link_ready_vector = all_ones else '0';

  -- characters either from scrambler if scrambling enabled or directly from data_link
  transport_chars_array <= scrambler_chars_array when SCRAMBLING = '1' else data_link_chars_array;

  -- error '1' if configs do not match
  co_error <= not ConfigsMatch(lane_configuration_array);

  data_links: for i in 0 to L-1 generate
    data_link_layer: entity work.data_link_layer
      generic map (
        K_character => K_character,
        R_character => R_character,
        A_character => A_character,
        Q_character => Q_character,
        ERROR_CONFIG => ERROR_CONFIG,
        SCRAMBLING => SCRAMBLING,
        F => F,
        K => K)
      port map (
        ci_char_clk     => ci_char_clk,
        ci_reset        => ci_reset,
        do_lane_config  => lane_configuration_array(i),
        co_lane_ready   => data_link_ready_vector(i),
        ci_lane_start   => data_link_start,
        ci_error_config => ERROR_CONFIG,
        co_synced       => data_link_synced_vector(i),
        di_10b          => di_transceiver_data(i),
        do_char         => data_link_chars_array(i));

    scrambler_gen: if SCRAMBLING = '1' generate
      scrambler: entity work.descrambler
        port map (
          ci_char_clk => ci_char_clk,
          ci_reset    => ci_reset,
          di_char     => data_link_chars_array(i),
          do_char     => scrambler_chars_array(i));
    end generate scrambler_gen;
  end generate data_links;

  transport_layer : entity work.transport_layer
    generic map (
      CS => CS,
      M  => M,
      S  => S,
      L  => L,
      F  => F,
      CF => CF,
      N  => N,
      Nn => Nn)
    port map (
      ci_char_clk     => ci_char_clk,
      ci_frame_clk    => ci_frame_clk,
      ci_reset        => ci_reset,
      di_lanes_data   => transport_chars_array,
      co_correct_data => co_correct_data,
      do_samples_data => do_samples);

end architecture a1;
