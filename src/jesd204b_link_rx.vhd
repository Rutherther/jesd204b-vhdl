-------------------------------------------------------------------------------
-- Title      : JESD204B receiver
-------------------------------------------------------------------------------
-- File       : jesd204b_link_rx.vhd
-------------------------------------------------------------------------------
-- Description: A top level entity for a JESD204B receiver.
-- Holds data_link and transport_layers.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.transport_pkg.all;
use work.data_link_pkg.all;
use work.jesd204b_pkg.all;

entity jesd204b_link_rx is
  generic (
    K_character  : std_logic_vector(7 downto 0) := "10111100";  -- Sync character
    R_character  : std_logic_vector(7 downto 0) := "00011100";  -- ILAS first
                                        -- frame character
    A_character  : std_logic_vector(7 downto 0) := "01111100";  -- Multiframe
                                        -- alignment character
    Q_character  : std_logic_vector(7 downto 0) := "10011100";  -- ILAS 2nd
                                        -- frame 2nd character
    ADJCNT       : integer                      := 0;
    ADJDIR       : integer                      := 0;
    BID          : integer                      := 0;
    DID          : integer                      := 0;
    HD           : std_logic                    := '0';
    JESDV        : integer                      := 1;
    PHADJ        : integer                      := 0;
    SUBCLASSV    : integer                      := 0;
    K            : integer;             -- Number of frames in a
                                        -- multiframe
    CS           : integer;             -- Number of control bits per sample
    M            : integer;             -- Number of converters
    S            : integer;             -- Number of samples
    L            : integer;             -- Number of lanes
    F            : integer;             -- Number of octets in a frame
    CF           : integer;             -- Number of control words
    N            : integer;             -- Size of a sample
    Nn           : integer;             -- Size of a word (sample + ctrl if CF
    ERROR_CONFIG : error_handling_config        := (2, 0, 5, 5, 5);
    SCRAMBLING   : std_logic                    := '0');
  port (
    ci_char_clk     : in std_logic;     -- Character clock
    ci_frame_clk    : in std_logic;     -- Frame clock
    ci_reset        : in std_logic;     -- Reset (asynchronous, active low)
    ci_request_sync : in std_logic;     -- Request synchronization

    co_nsynced : out std_logic;  -- Whether receiver is synced (active low)
    co_error   : out std_logic;

    di_transceiver_data : in  lane_input_array(0 to L-1);  -- Data from transceivers
    do_samples          : out samples_array(0 to M - 1, 0 to S - 1);
    co_frame_state      : out frame_state;
-- Output samples
    co_correct_data     : out std_logic);  -- Whether samples are correct user
                                           -- data
end entity jesd204b_link_rx;

architecture a1 of jesd204b_link_rx is
  constant link_config : link_config :=
    (ADJCNT, ADJDIR, BID, CF, CS, DID, F, HD, JESDV, K, L, LID, M, N, Nn, PHADJ, S, SCRAMBLING, SUBCLASSV, RES1, RES2, X, 0);
  -- == DATA LINK ==
  -- outputs
  signal data_link_ready_vector : std_logic_vector(L-1 downto 0) := (others => '0');
  signal data_link_synced_vector : std_logic_vector(L-1 downto 0) := (others => '0');
  signal data_link_aligned_chars_array : lane_character_array(0 to L-1)(F*8-1 downto 0);
  signal data_link_frame_state_array : frame_state_array(0 to L-1);
  -- inputs
  signal data_link_start : std_logic := '0';

  -- == DESCRAMBLER ==
  signal descrambler_aligned_chars_array : lane_character_array(0 to L-1)(F*8-1 downto 0);

  -- == TRANSPORT ==
  signal transport_chars_array : lane_character_array(0 to L-1)(F*8-1 downto 0);
  signal transport_frame_state_array : frame_state_array(0 to L-1);

  type lane_configs_array is array (0 to L-1) of link_config;
  signal lane_configuration_array : lane_configs_array;

  signal all_ones : std_logic_vector(L-1 downto 0) := (others => '1');

  end function ConfigsMatch;
begin  -- architecture a1
  -- nsynced is active LOW, set '0' if all ready
  co_nsynced <= '0' when data_link_synced_vector = all_ones else '1';
  -- choose the first config.
  co_lane_config <= lane_configuration_array(0);

  -- start lanes data after all are ready
  data_link_start <= '1' when data_link_ready_vector = all_ones else '0';

  -- characters either from scrambler if scrambling enabled or directly from data_link
  transport_chars_array <= scrambler_aligned_chars_array when SCRAMBLING = '1' else data_link_aligned_chars_array;
  transport_frame_state_array <= data_link_frame_state_array; -- TODO: buffer
                                                              -- frame_state if
                                                              -- scrambling

  -- error '1' if configs do not match
  co_error <= not ConfigsMatch(lane_configuration_array);

  data_links : for i in 0 to L-1 generate
    data_link_layer : entity work.data_link_layer
      generic map (
        K_character  => K_character,
        R_character  => R_character,
        A_character  => A_character,
        Q_character  => Q_character,
        ERROR_CONFIG => ERROR_CONFIG,
        SCRAMBLING   => SCRAMBLING,
        F            => F,
        K            => K)
      port map (
        ci_char_clk      => ci_char_clk,
        ci_frame_clk     => ci_frame_clk,
        ci_reset         => ci_reset,
        do_lane_config   => lane_configuration_array(i),
        co_lane_ready    => data_link_ready_vector(i),
        ci_lane_start    => data_link_start,
        ci_request_sync  => ci_request_sync,
        co_synced        => data_link_synced_vector(i),
        di_10b           => di_transceiver_data(i),
        do_aligned_chars => data_link_aligned_chars_array(i),
        co_frame_state   => data_link_frame_state_array(i));

    scrambler_gen: if SCRAMBLING = '1' generate
      scrambler: entity work.descrambler
        generic map (
          F => F)
        port map (
          ci_frame_clk => ci_frame_clk,
          ci_reset    => ci_reset,
          di_char     => data_link_aligned_chars_array(i),
          do_char     => descrambler_aligned_chars_array(i));
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
      ci_frame_clk    => ci_frame_clk,
      ci_reset        => ci_reset,
      di_lanes_data   => transport_chars_array,
      ci_frame_states => transport_frame_state_array,
      co_frame_state  => co_frame_state,
      do_samples_data => do_samples);

end architecture a1;
