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
    K_CHAR       : std_logic_vector(7 downto 0) := "10111100";  -- Sync character
    R_CHAR       : std_logic_vector(7 downto 0) := "00011100";  -- ILAS first
                                        -- frame character
    A_CHAR       : std_logic_vector(7 downto 0) := "01111100";  -- Multiframe
                                        -- alignment character
    Q_CHAR       : std_logic_vector(7 downto 0) := "10011100";  -- ILAS 2nd
                                        -- frame 2nd character
    ADJCNT            : integer range 0 to 15        := 0;
    ADJDIR            : std_logic                    := '0';
    BID               : integer range 0 to 15        := 0;
    DID               : integer range 0 to 255       := 0;
    HD                : std_logic                    := '0';
    JESDV             : integer range 0 to 7         := 1;
    PHADJ             : std_logic                    := '0';
    SUBCLASSV         : integer range 0 to 7         := 0;
    K                 : integer range 1 to 32;  -- Number of frames in a
                                                -- multiframe
    CS                : integer range 0 to 3;  -- Number of control bits per sample
    M                 : integer range 1 to 256;  -- Number of converters
    S                 : integer range 1 to 32;  -- Number of samples
    L                 : integer range 1 to 32;  -- Number of lanes
    F                 : integer range 1 to 256;  -- Number of octets in a frame
    CF                : integer range 0 to 32;  -- Number of control words
    N                 : integer range 1 to 32;  -- Size of a sample
    Nn                : integer range 1 to 32;  -- Size of a word (sample + ctrl if CF
    ALIGN_BUFFER_SIZE : integer                      := 255;  -- Size of a
                                                              -- buffer that is
                                                              -- used for
                                                              -- aligning lanes
    RX_BUFFER_DELAY   : integer range 1 to 32        := 1;
    ERROR_CONFIG      : error_handling_config        := (2, 0, 5, 5, 5);
    SCRAMBLING        : std_logic                    := '0');
  port (
    ci_char_clk       : in std_logic;   -- Character clock
    ci_frame_clk      : in std_logic;   -- Frame clock
    ci_multiframe_clk : in std_logic;  -- Mutliframe clock (subclass 1, 2 only)
    ci_reset          : in std_logic;   -- Reset (asynchronous, active low)
    ci_request_sync   : in std_logic;   -- Request synchronization

    co_nsynced : out std_logic;  -- Whether receiver is synced (active low)
    co_error   : out std_logic;

    di_data : in  lane_input_array(0 to L-1);  -- Data from transceivers
    do_samples          : out samples_array(0 to M - 1, 0 to S - 1);
    co_frame_state      : out frame_state;  -- Output samples
    co_correct_data     : out std_logic);  -- Whether samples are correct user
                                           -- data
end entity jesd204b_link_rx;

architecture a1 of jesd204b_link_rx is
  signal request_sync : std_logic;
  signal request_sync_event : std_logic;

  signal reg_synced : std_logic;
  signal next_synced : std_logic;
  -- == DATA LINK ==
  -- outputs
  signal data_link_ready_vector : std_logic_vector(L-1 downto 0) := (others => '0');
  signal data_link_synced_vector : std_logic_vector(L-1 downto 0) := (others => '0');
  signal data_link_aligned_chars_array : lane_character_array(0 to L-1)(F*8-1 downto 0);
  signal data_link_frame_state_array : frame_state_array(0 to L-1);
  -- inputs
  signal data_link_start : std_logic := '0';

  -- subclass 1 support
  signal frame_index : integer;

  -- == DESCRAMBLER ==
  signal descrambler_aligned_chars_array : lane_character_array(0 to L-1)(F*8-1 downto 0);

  -- == TRANSPORT ==
  signal transport_chars_array : lane_character_array(0 to L-1)(F*8-1 downto 0);
  signal transport_frame_state_array : frame_state_array(0 to L-1);

  type lane_configs_array is array (0 to L-1) of link_config;
  signal lane_configuration_array : lane_configs_array;

  signal all_ones : std_logic_vector(L-1 downto 0) := (others => '1');

  function ConfigsMatch (
    config_array : lane_configs_array)
    return std_logic is
    variable matches : std_logic := '1';
  begin  -- function ConfigsMatch
    for i in 0 to L-2 loop
      if config_array(i).ADJCNT /= ADJCNT or
        config_array(i).LID /= i or
        config_array(i).ADJDIR /= ADJDIR or
        config_array(i).BID /= BID or
        config_array(i).CF /= CF or
        config_array(i).CS /= CS or
        config_array(i).DID /= DID or
        config_array(i).F /= F or
        config_array(i).HD /= HD or
        config_array(i).JESDV /= JESDV or
        config_array(i).K /= K or
        config_array(i).L /= L or
        config_array(i).M /= M or
        config_array(i).N /= N or
        config_array(i).Nn /= Nn or
        config_array(i).PHADJ /= PHADJ or
        config_array(i).S /= S or
        config_array(i).SCR /= SCRAMBLING or
        config_array(i).SUBCLASSV /= SUBCLASSV
      then
        matches := '0';
      end if;
    end loop;  -- i

      return matches;
  end function ConfigsMatch;
begin  -- architecture a1
  -- nsynced is active LOW, set '0' if all ready
  sync_combination: entity work.synced_combination
    generic map (
      SUBCLASSV => SUBCLASSV,
      N         => L,
      INVERT   => '0')
    port map (
      ci_frame_clk      => ci_frame_clk,
      ci_multiframe_clk => ci_multiframe_clk,
      ci_reset          => ci_reset,
      ci_lmfc_aligned   => '1',
      ci_synced_array   => data_link_synced_vector,
      co_nsynced        => co_nsynced);

  request_sync_gen: process (ci_char_clk, ci_reset) is
  begin  -- process request_sync
    if ci_reset = '0' then              -- asynchronous reset (active low)
      request_sync_event <= '0';
      reg_synced <= '0';
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      reg_synced <= next_synced;

      if request_sync_event = '1' then
        request_sync_event <= '0';
      elsif next_synced = '0' and reg_synced = '1' then
        -- if any of the data links becomes desynchronized,
        -- request sync on every one of them.
        request_sync_event <= '1';
      end if;
    end if;
  end process request_sync_gen;

  -- start lanes data after all are ready
  start_lanes_subclass_0: if SUBCLASSV = 0 generate
    data_link_start <= '1' when data_link_ready_vector = all_ones else '0';
  end generate start_lanes_subclass_0;

  start_lanes_subclass_1: if SUBCLASSV = 1 generate
    set_frame_index: process (ci_frame_clk, ci_multiframe_clk, ci_reset) is
    begin  -- process set_frame_idnex
      if ci_reset = '0' then            -- asynchronous reset (active low)
        frame_index <= 0;
      elsif ci_multiframe_clk'event and ci_multiframe_clk = '1' then  -- rising clock edge
        frame_index <= 0;
      elsif ci_frame_clk'event and ci_frame_clk = '1' then  -- rising clock edge
        frame_index <= frame_index + 1;
      end if;
    end process set_frame_index;
    data_link_start <= '1' when frame_index = RX_BUFFER_DELAY and data_link_ready_vector = all_ones else '0';
  end generate start_lanes_subclass_1;

  -- characters either from scrambler if scrambling enabled or directly from data_link
  transport_chars_array <= descrambler_aligned_chars_array when SCRAMBLING = '1' else data_link_aligned_chars_array;
  transport_frame_state_array <= data_link_frame_state_array; -- TODO: buffer
                                                              -- frame_state if
                                                              -- scrambling
  -- error '1' if configs do not match
  co_error <= not ConfigsMatch(lane_configuration_array);
  co_correct_data <= co_frame_state.user_data;

  next_synced <= '1' when data_link_synced_vector = all_ones else '0';
  request_sync <= request_sync_event or ci_request_sync;

  data_links : for i in 0 to L-1 generate
    data_link_layer : entity work.data_link_layer
      generic map (
        ALIGN_BUFFER_SIZE => ALIGN_BUFFER_SIZE,
        K_CHAR       => K_CHAR,
        R_CHAR       => R_CHAR,
        A_CHAR       => A_CHAR,
        Q_CHAR       => Q_CHAR,
        ERROR_CONFIG      => ERROR_CONFIG,
        SCRAMBLING        => SCRAMBLING,
        SUBCLASSV         => SUBCLASSV,
        F                 => F,
        K                 => K)
      port map (
        ci_char_clk      => ci_char_clk,
        ci_frame_clk     => ci_frame_clk,
        ci_reset         => ci_reset,
        do_lane_config   => lane_configuration_array(i),
        co_lane_ready    => data_link_ready_vector(i),
        ci_lane_start    => data_link_start,
        ci_request_sync  => request_sync,
        co_synced        => data_link_synced_vector(i),
        di_10b           => di_data(i),
        do_aligned_chars => data_link_aligned_chars_array(i),
        co_frame_state   => data_link_frame_state_array(i));

    descrambler_gen: if SCRAMBLING = '1' generate
      descrambler: entity work.descrambler
        generic map (
          F => F)
        port map (
          ci_frame_clk => ci_frame_clk,
          ci_reset    => ci_reset,
          di_data     => data_link_aligned_chars_array(i),
          do_data     => descrambler_aligned_chars_array(i));
    end generate descrambler_gen;
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
