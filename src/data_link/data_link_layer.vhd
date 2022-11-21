library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity data_link_layer is
  generic (
    K_character  : std_logic_vector(7 downto 0) := "10111100";
    R_character  : std_logic_vector(7 downto 0) := "00011100";
    A_character  : std_logic_vector(7 downto 0) := "01111100";
    Q_character  : std_logic_vector(7 downto 0) := "10011100");
  port (
    ci_char_clk : in std_logic;
    ci_reset    : in std_logic;

    -- lane configuration
    ci_F : in integer range 0 to 256;
    ci_K : in integer range 0 to 32;
    ci_scrambled  : in std_logic;
    do_lane_config : out link_config;

    -- synchronization
    co_lane_ready : out std_logic;      -- Received /A/, waiting for lane sync
    ci_lane_start : in std_logic;       -- Start sending data from lane buffer

    -- errors
    ci_error_config : in error_handling_config;

    -- input, output
    co_synced : out std_logic;
    di_10b : in std_logic_vector(9 downto 0);
    do_char : out frame_character);
end entity data_link_layer;

architecture a1 of data_link_layer is
  signal char_alignment_do_10b : std_logic_vector(9 downto 0);

  signal decoder_do_char : character_vector;

  signal lane_alignment_ci_realign : std_logic := '0';
  signal lane_alignment_co_aligned : std_logic;
  signal lane_alignment_co_error : std_logic;
  signal lane_alignment_co_ready : std_logic;
  signal lane_alignment_do_char : character_vector;
  signal lane_alignment_co_correct_sync_chars : integer;

  signal frame_alignment_ci_request_sync : std_logic;
  signal frame_alignment_ci_realign : std_logic := '0';
  signal frame_alignment_co_aligned : std_logic;
  signal frame_alignment_co_error : std_logic;
  signal frame_alignment_do_char : frame_character;
  signal frame_alignment_co_correct_sync_chars : integer;

  signal link_controller_co_synced : std_logic;
  signal link_controller_co_state : link_state;
  signal link_controller_do_config : link_config;
  signal link_controller_ci_resync : std_logic;

begin  -- architecture a1
  do_lane_config <= link_controller_do_config;
  co_lane_ready <= lane_alignment_co_ready;
  co_synced <= link_controller_co_synced;
  do_char <= frame_alignment_do_char;

  frame_alignment_ci_request_sync <= not link_controller_co_synced;

  -- DATA LINK LAYER
  --         --------------------> LINK CONTROLLER <-------------
  --          |            |                         |        |
  --  FRAME ALIGNMENT <= LANE ALIGNMENT <= 8b10b DECODER <= CHAR ALIGNMENT

  -- error handling
  error_handling : entity work.error_handler
    port map (
      ci_char_clk                      => ci_char_clk,
      ci_reset                         => ci_reset,
      ci_state                         => link_controller_co_state,
      ci_F                             => ci_F,
      di_char                          => decoder_do_char,
      ci_config                        => ci_error_config,
      ci_lane_alignment_error          => lane_alignment_co_error,
      ci_frame_alignment_error         => frame_alignment_co_error,
      ci_lane_alignment_correct_count  => lane_alignment_co_correct_sync_chars,
      ci_frame_alignment_correct_count => frame_alignment_co_correct_sync_chars,
      co_frame_alignment_realign       => frame_alignment_ci_realign,
      co_lane_alignment_realign        => lane_alignment_ci_realign,
      co_request_sync                  => link_controller_ci_resync);

  -- link controller
  link_controller : entity work.link_controller
    port map (
      ci_char_clk                => ci_char_clk,
      ci_reset                   => ci_reset,
      ci_resync                  => link_controller_ci_resync,
      ci_F                       => ci_F,
      ci_K                       => ci_K,
      ci_lane_alignment_error    => lane_alignment_co_error,
      ci_lane_alignment_aligned  => lane_alignment_co_aligned,
      ci_lane_alignment_ready    => lane_alignment_co_ready,
      ci_frame_alignment_error   => frame_alignment_co_error,
      ci_frame_alignment_aligned => frame_alignment_co_aligned,
      di_char                    => decoder_do_char,
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
  lane_alignment: entity work.lane_alignment
    port map (
      ci_char_clk => ci_char_clk,
      ci_reset    => ci_reset,
      ci_F        => ci_F,
      ci_K        => ci_K,
      ci_state    => link_controller_co_state,
      co_ready    => lane_alignment_co_ready,
      ci_start    => ci_lane_start,
      di_char     => decoder_do_char,
      do_char     => lane_alignment_do_char);

  -- frame alignment
  frame_alignment : entity work.frame_alignment
    port map (
      ci_char_clk           => ci_char_clk,
      ci_reset              => ci_reset,
      ci_scrambled          => ci_scrambled,
      ci_F                  => ci_F,
      ci_K                  => ci_K,
      co_correct_sync_chars => frame_alignment_co_correct_sync_chars,
      ci_request_sync       => frame_alignment_ci_request_sync,
      ci_realign            => frame_alignment_ci_realign,
      co_aligned            => frame_alignment_co_aligned,
      co_error              => frame_alignment_co_error,
      di_char               => lane_alignment_do_char);

end architecture a1;
