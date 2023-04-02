-------------------------------------------------------------------------------
-- Title      : controller of data link layer
-------------------------------------------------------------------------------
-- File       : link_controller.vhd
-------------------------------------------------------------------------------
-- Description: Controller for link layer, handling CGS and ILAS.
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

-- What does it do?
-- Well, it manages the states (init, cgs, ilas, data)
-- It sends sync if needed (irecoverrable error detected). It holds? ILAS data.
-- It should get all the control outputs from lane_alignment,
-- frame_alignment, an8b10bdecoder, char_alignment.
-- It should get the current data from an8b10bdecoder

entity link_controller is
  generic (
    SUBCLASSV   : integer range 0 to 1 := 0;
    F           : integer range 1 to 256;     -- Number of octets in a frame
    K           : integer range 1 to 32;  -- Number of frames in a multiframe
    K_character : std_logic_vector(7 downto 0) := "10111100");  -- Sync character
  port (
    ci_multiframe_clk : in std_logic;   -- Multiframe clock
    ci_frame_clk      : in std_logic;   -- Frame clock
    ci_char_clk       : in std_logic;   -- Character clock
    ci_reset          : in std_logic;   -- Reset (asynchronous, active low)
    di_char           : in character_vector;  -- Output character from 8b10b decoder

    do_config : out link_config;  -- Config found in ILAS

    ci_lane_alignment_error   : in std_logic;  -- Signals a problem with lane
                                             -- alignment in this data link
                                             -- (see lane alighnment component)
    ci_lane_alignment_aligned : in std_logic;  -- Signals that lane is
                                               -- correctly aligned (see
                                               -- lane_alignment component)
    ci_lane_alignment_ready   : in std_logic;  -- Signals that the lane received
                                             -- /A/ and is waiting to start
                                             -- sending data (see
                                             -- lane_alignment component)

    ci_frame_alignment_error   : in std_logic;  -- Signals that the frame was misaligned.
    ci_frame_alignment_aligned : in std_logic;  -- Signals that the frame end
                                                -- was found and did not change.

    ci_resync : in std_logic;  -- Whether to start syncing again.

    co_synced              : out std_logic;  -- Whether the lane is synced (received
                                        -- 4 /K/ characters and proceeds correctly)
    co_state               : out link_state;  -- The state of the lane.
    co_uncorrectable_error : out std_logic;  -- Detected an uncorrectable
                                             -- error, has to resync (ilas
                                             -- parsing error)
    co_error               : out std_logic);          -- Detected any error, processing may
                                        -- differ
end entity link_controller;

architecture a1 of link_controller is
  constant SYNC_COUNT : integer range 0 to 4 := 4;
  constant FULL_SYNCHRONIZATION_AFTER : integer range 0 to 4 := 4;
  signal synced : std_logic := '0';
  signal full_synchronization : std_logic := '0'; -- Assumed after 4 /K/
                                                  -- characters + 4 more 8b10b
                                                  -- correct characters
  signal correct_8b10b_characters : integer range 0 to FULL_SYNCHRONIZATION_AFTER;

  signal reg_state : link_state := INIT;
  signal reg_k_counter : integer range 0 to 15 := 0;

  signal ilas_finished : std_logic := '0';
  signal ilas_error : std_logic := '0';
  signal ilas_wrong_chksum : std_logic := '0';
  signal ilas_unexpected_char : std_logic := '0';
begin  -- architecture a1
  ilas: entity work.ilas_parser
    generic map (
      F                  => F,
      K                  => K)
    port map (
      ci_char_clk        => ci_char_clk,
      ci_reset           => ci_reset,
      ci_state           => reg_state,
      di_char            => di_char,
      do_config          => do_config,
      co_finished        => ilas_finished,
      co_error           => ilas_error,
      co_wrong_chksum    => ilas_wrong_chksum,
      co_unexpected_char => ilas_unexpected_char);

  set_state: process (ci_char_clk, ci_reset) is
    variable char_error : std_logic;
  begin  -- process set_state
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_state <= INIT;
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      char_error := di_char.disparity_error or di_char.missing_error;

      if correct_8b10b_characters < FULL_SYNCHRONIZATION_AFTER and char_error = '0' then
        correct_8b10b_characters <= correct_8b10b_characters + 1;
      end if;

      if ci_resync = '1' or (full_synchronization = '0' and char_error = '1') then
        reg_state <= INIT;
        reg_k_counter <= 0;
      elsif reg_state = CGS then
        if reg_k_counter < SYNC_COUNT then
          correct_8b10b_characters <= 1;
          if di_char.d8b = K_character and di_char.kout = '1' then
            reg_k_counter <= reg_k_counter + 1;
          else
            reg_k_counter <= 0;
          end if;
        elsif di_char.d8b /= K_character or di_char.kout = '0' then
          reg_state <= ILS;
        end if;
      elsif di_char.d8b = K_character and di_char.kout = '1' then
        reg_state <= CGS;
        reg_k_counter <= 0;
      elsif reg_state = ILS then
        if ilas_finished = '1' then
          reg_state <= DATA;
        elsif ilas_error = '1' then
          reg_state <= INIT;
        end if;
      elsif reg_state = DATA then
        -- uncorrectable error? resync.
      end if;
    end if;
  end process set_state;

  synced_subclass_0: if SUBCLASSV = 0 generate
    set_synced: process(ci_frame_clk, ci_reset) is
    begin
      if ci_reset = '0' then
        co_synced <= '0';
      elsif ci_frame_clk'event and ci_frame_clk = '1' then
        co_synced <= synced;
      end if;
    end process set_synced;
  end generate synced_subclass_0;

  synced_subclass_1: if SUBCLASSV = 1 generate
    set_synced: process(ci_multiframe_clk, ci_reset) is
    begin
      if ci_reset = '0' then
        co_synced <= '0';
      elsif ci_multiframe_clk'event and ci_multiframe_clk = '1' then
        co_synced <= synced;
      end if;
    end process set_synced;
  end generate synced_subclass_1;

  synced <= '0' when reg_state = INIT or (reg_state = CGS and reg_k_counter < SYNC_COUNT) else '1';
  full_synchronization <= '0' when synced = '0' or correct_8b10b_characters < FULL_SYNCHRONIZATION_AFTER else '1';

  co_state <= reg_state;
  -- TODO: add ILAS errors, add CGS error in case sync does not happen for long
  -- time
  co_error <= ci_lane_alignment_error or ci_frame_alignment_error or di_char.missing_error or di_char.disparity_error;
  co_uncorrectable_error <= ilas_error;

end architecture a1;
