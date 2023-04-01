-------------------------------------------------------------------------------
-- Title      : data link
-------------------------------------------------------------------------------
-- File       : data_link_layer.vhd
-------------------------------------------------------------------------------
-- Description: A wrapper entity for data link components.
-- Receives 10b characters, outputs aligned frame 8b characters
-- Connects:
--
-- ############################## DATA LINK ###################################
--  char_alignment => 8b10bdecoder => lane_alignment => frame_alignment
--  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--    error_handler
--  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--    link_controller
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity data_link_layer is
  generic (
    K_character  : std_logic_vector(7 downto 0) := "10111100";  -- K sync character
    R_character  : std_logic_vector(7 downto 0) := "00011100";  -- ILAS
                                        -- multiframe start
    A_character  : std_logic_vector(7 downto 0) := "01111100";  -- multiframe end
    Q_character  : std_logic_vector(7 downto 0) := "10011100";  -- 2nd ILAS frame
                                        -- 2nd character
    ERROR_CONFIG : error_handling_config        := (2, 0, 5, 5, 5);  -- Configuration
                                        -- for the error
    SCRAMBLING   : std_logic                    := '0';  -- Whether scrambling is enabled
    F            : integer                      := 2;  -- Number of octets in a frame
    K            : integer                      := 1);  -- Number of frames in a mutliframe
  port (
    ci_char_clk  : in std_logic;        -- Character clock
    ci_frame_clk : in std_logic;        -- Frame clock
    ci_reset     : in std_logic;        -- Reset (asynchronous, active low)

    -- link configuration
    do_lane_config : out link_config;  -- Configuration of the link

    -- synchronization
    co_lane_ready : out std_logic;  -- Received /A/, waiting for lane sync
    ci_lane_start : in  std_logic;  -- Start sending data from lane buffer
    ci_request_sync : in std_logic; -- Request resynchronization

    -- input, output
    co_synced        : out std_logic;  -- Whether the lane is synced
    di_10b           : in  std_logic_vector(9 downto 0);  -- The 10b input character
    do_aligned_chars : out std_logic_vector(8*F - 1 downto 0);
    co_frame_state   : out frame_state);  -- The aligned frame output character
end entity data_link_layer;

architecture a1 of data_link_layer is
  signal char_alignment_do_10b : std_logic_vector(9 downto 0);

  signal decoder_do_char : character_vector;

  signal error_handler_co_request_sync : std_logic;

  signal lane_alignment_ci_realign            : std_logic := '0';
  signal lane_alignment_co_aligned            : std_logic;
  signal lane_alignment_co_error              : std_logic;
  signal lane_alignment_co_ready              : std_logic;
  signal lane_alignment_do_char               : character_vector;
  signal lane_alignment_co_correct_sync_chars : integer;

  signal frame_alignment_ci_request_sync       : std_logic;
  signal frame_alignment_ci_realign            : std_logic := '0';
  signal frame_alignment_co_aligned            : std_logic;
  signal frame_alignment_co_error              : std_logic;
  signal frame_alignment_do_aligned_chars      : std_logic_vector(8*F - 1 downto 0);
  signal frame_alignment_co_frame_state        : frame_state;
  signal frame_alignment_co_correct_sync_chars : integer;

  signal link_controller_co_synced : std_logic;
  signal link_controller_co_state  : link_state;
  signal link_controller_do_config : link_config;
  signal link_controller_ci_resync : std_logic;

begin  -- architecture a1
  do_lane_config <= link_controller_do_config;
  co_lane_ready <= lane_alignment_co_ready;
  co_synced <= link_controller_co_synced;
  do_aligned_chars <= frame_alignment_do_aligned_chars;
  co_frame_state <= frame_alignment_co_frame_state;
  co_synced <= link_controller_co_synced;

  frame_alignment_ci_request_sync <= not link_controller_co_synced;

  -- DATA LINK LAYER
  --         --------------------> LINK CONTROLLER <-------------
  --          |            |                         |        |
  --  FRAME ALIGNMENT <= LANE ALIGNMENT <= 8b10b DECODER <= CHAR ALIGNMENT

  -- error handling
  error_handling : entity work.error_handler
    generic map (
      F => F,
      CONFIG => ERROR_CONFIG)
    port map (
      ci_char_clk                      => ci_char_clk,
      ci_reset                         => ci_reset,
      ci_state                         => link_controller_co_state,
      di_char                          => decoder_do_char,
      ci_lane_alignment_error          => lane_alignment_co_error,
      ci_frame_alignment_error         => frame_alignment_co_error,
      ci_lane_alignment_correct_count  => lane_alignment_co_correct_sync_chars,
      ci_frame_alignment_correct_count => frame_alignment_co_correct_sync_chars,
      co_frame_alignment_realign       => frame_alignment_ci_realign,
      co_lane_alignment_realign        => lane_alignment_ci_realign,
      co_request_sync                  => error_handler_co_request_sync);

  -- link controller
  link_controller_ci_resync <= error_handler_co_request_sync or ci_request_sync;
  link_controller : entity work.link_controller
    generic map (
      F => F,
      K => K)
    port map (
      ci_frame_clk               => ci_frame_clk,
      ci_char_clk                => ci_char_clk,
      ci_reset                   => ci_reset,
      ci_resync                  => link_controller_ci_resync,
      ci_lane_alignment_error    => lane_alignment_co_error,
      ci_lane_alignment_aligned  => lane_alignment_co_aligned,
      ci_lane_alignment_ready    => lane_alignment_co_ready,
      ci_frame_alignment_error   => frame_alignment_co_error,
      ci_frame_alignment_aligned => frame_alignment_co_aligned,
      di_char                    => decoder_do_char,
      co_synced                  => link_controller_co_synced,
      co_state                   => link_controller_co_state,
      do_config                  => link_controller_do_config);

  -- char alignment
  char_alignment: entity work.char_alignment
    port map (
      ci_char_clk => ci_char_clk,
      ci_reset    => ci_reset,
      ci_synced   => link_controller_co_synced,
      di_10b      => di_10b,
      do_10b      => char_alignment_do_10b);

  -- 8b10b decoder
  an8b10b_decoder: entity work.an8b10b_decoder
    port map (
      ci_char_clk => ci_char_clk,
      ci_reset    => ci_reset,
      di_10b      => char_alignment_do_10b,
      do_char      => decoder_do_char);

  -- lane alignment
  lane_alignment : entity work.lane_alignment
    generic map (
      F => F,
      K => K)
    port map (
      ci_char_clk           => ci_char_clk,
      ci_reset              => ci_reset,
      ci_state              => link_controller_co_state,
      ci_realign            => lane_alignment_ci_realign,
      co_ready              => lane_alignment_co_ready,
      ci_start              => ci_lane_start,
      di_char               => decoder_do_char,
      co_correct_sync_chars => lane_alignment_co_correct_sync_chars,
      do_char               => lane_alignment_do_char);

  -- frame alignment
  frame_alignment : entity work.frame_alignment
    generic map (
      SCRAMBLING => SCRAMBLING,
      F          => F,
      K         => K)
    port map (
      ci_char_clk           => ci_char_clk,
      ci_frame_clk          => ci_frame_clk,
      ci_reset              => ci_reset,
      co_frame_state        => frame_alignment_co_frame_state,
      do_aligned_chars      => frame_alignment_do_aligned_chars,
      co_correct_sync_chars => frame_alignment_co_correct_sync_chars,
      ci_request_sync       => frame_alignment_ci_request_sync,
      ci_realign            => frame_alignment_ci_realign,
      co_aligned            => frame_alignment_co_aligned,
      co_error              => frame_alignment_co_error,
      di_char               => lane_alignment_do_char);

end architecture a1;
