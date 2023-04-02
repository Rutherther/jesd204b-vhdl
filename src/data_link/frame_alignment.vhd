-------------------------------------------------------------------------------
-- Title      : frame alignment
-------------------------------------------------------------------------------
-- File       : frame_alignment.vhd
-------------------------------------------------------------------------------
-- Description: Retrieves alignment of octet in a frame.
-- Aligns using /A/ and /F/ characters. If these characters are on wrong spot,
-- returns an error. May realign if requested.

-- IF lane alignment is in use (more lanes are there), do not realign using
-- frame alignment. Realign using lane alignment. ci_realign of frame alignment
-- should remain low at all times.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity frame_alignment is
  generic (
    SCRAMBLING : std_logic; -- Whether data are scrambled
    F : integer range 0 to 256 := 8; -- Number of octets in a frame
    K : integer range 0 to 32 := 1; -- Number of frames in a multiframe
    sync_char      : std_logic_vector(7 downto 0) := "10111100";  -- K
                                                                  -- character
                                                                  -- for syncing
    A_char         : std_logic_vector(7 downto 0) := "01111100";  -- Last
                                                                  -- character
                                                                  -- in multiframe
    F_char         : std_logic_vector(7 downto 0) := "11111100";  -- Last
                                                                  -- character
                                                                  -- in frame
    F_replace_data : std_logic_vector(7 downto 0) := "11111100";  -- The character to replace with upon receiving /F/ with scrambled data
    A_replace_data : std_logic_vector(7 downto 0) := "01111100");  -- The character to replace with upon receiving /A/ with scrambled data
  port (
    ci_char_clk           : in  std_logic;  -- Character clock
    ci_frame_clk          : in  std_logic;  -- Frame clock
    ci_reset              : in  std_logic;  -- Reset (asynchronous, active low)
    ci_request_sync       : in  std_logic;  -- Whether sync is requested
    ci_realign            : in  std_logic;  -- Whether to realign to last
                                            -- alignment character
    di_char               : in  character_vector;  -- The received character
    co_aligned            : out std_logic;  -- Whether the alignment is right
    co_error              : out std_logic;  -- Whether there was an error with
                                            -- the alignment
    co_correct_sync_chars : out integer;  -- Number of alignment characters on
                                          -- same position in a row
    do_aligned_chars      : out std_logic_vector(8*F - 1 downto 0);
    co_frame_state        : out frame_state);  -- Errors for current or next frame
      -- a characters in a frame
end entity frame_alignment;

architecture a1 of frame_alignment is
  type alignment_state is (INIT, ALIGNED, MISALIGNED);
  signal reg_state : alignment_state := INIT;

  signal next_frame_state : frame_state;

  signal buffer_character : std_logic_vector(7 downto 0) := "00000000";
  signal buffer_raw_adjust_position : integer := 0;
  signal buffer_adjust_position : integer := 0;
  signal buffer_align_to : integer := 0;
  signal buffer_read_position : integer := 0;
  signal buffer_write_position : integer := 0;
  signal buffer_filled : std_logic := '0';

  signal reg_last_frame_data : std_logic_vector(7 downto 0) := "00000000";

  signal next_is_last_octet : std_logic := '0';
  signal next_is_last_frame : std_logic := '0';

  signal is_f : std_logic := '0';
  signal is_a : std_logic := '0';

  signal is_wrong_char : std_logic := '0';

  signal reg_correct_sync_chars : integer := 0;
  signal reg_known_sync_char_position : integer range 0 to 256;

  signal next_octet_index : integer range 0 to F := 0;
  signal next_adjusted_octet_index : integer range 0 to F := 0;
begin  -- architecture a1
  data_buffer: entity work.ring_buffer
    generic map (
      BUFFER_SIZE    => F*2,
      READ_SIZE      => F,
      CHARACTER_SIZE => 8)
    port map (
      ci_clk                => ci_char_clk,
      ci_reset              => ci_reset,
      ci_adjust_position    => buffer_adjust_position,
      ci_read               => ci_frame_clk,
      di_character          => buffer_character,
      co_read               => do_aligned_chars,
      co_read_position      => buffer_read_position,
      co_write_position     => buffer_write_position,
      co_filled             => buffer_filled);

  next_frame: process (ci_frame_clk) is
  begin  -- process next_frame
    if ci_reset = '0' then
      co_frame_state <= ('0', '0', '0', '0', '0', '0', '0', '0');
    elsif ci_frame_clk'event and ci_frame_clk = '1' then  -- rising clock edge
      co_frame_state <= next_frame_state;
    end if;
  end process next_frame;

  set_next: process (ci_char_clk, ci_frame_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '1' and ci_frame_clk'event and ci_frame_clk = '1' then
      if reg_state /= INIT then
        next_frame_state <= ('1', '0', '0', '0', '0', '0', '0', '0');
      end if;
    end if;

    if ci_reset = '0' then              -- asynchronous reset (active
      reg_state <= INIT;
      reg_last_frame_data <= (others => '0');
      next_frame_state <= ('0', '0', '0', '0', '0', '0', '0', '0');
      buffer_align_to <= -1;
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      -- set last_frame_data if this is the last frame and not /F/ or /A/
      if next_is_last_octet = '1' and not (is_f = '1' or is_a = '1') then
        reg_last_frame_data <= di_char.d8b;
      end if;

      if ci_request_sync = '1' then
        reg_state <= INIT;
        next_frame_state <= ('0', '0', '0', '0', '0', '0', '0', '0');
      elsif reg_state = INIT then
      next_frame_state <= ('0', '0', '0', '0', '0', '0', '0', '0');
        -- if a or f, align to it and move to aligned
        if is_a = '1' or is_f = '1' then
          -- align to current character.
          buffer_align_to <= next_octet_index;
          next_frame_state <= ('1', '0', '0', '0', '0', '0', '0', '0');
          reg_state <= ALIGNED;
        end if;
      else
        if di_char.kout = '1' and not (is_a = '1' or is_f = '1') then
          next_frame_state.invalid_characters <= '1';
        end if;
        if di_char.disparity_error = '1' then
          next_frame_state.disparity_error <= '1';
        end if;
        if di_char.missing_error then
          next_frame_state.not_in_table_error <= '1';
        end if;
        if di_char.user_data = '0' then
          next_frame_state.user_data <= '0';
        end if;
        if reg_state = ALIGNED then
          if is_wrong_char = '1' then
            next_frame_state.wrong_alignment <= '1';
            reg_state <= MISALIGNED;
            reg_correct_sync_chars <= 1;
            reg_known_sync_char_position <= next_octet_index;
          end if;
        elsif reg_state = MISALIGNED then
          next_frame_state.wrong_alignment <= '1';
          if is_wrong_char = '1' then
            if reg_known_sync_char_position = next_octet_index then
              reg_correct_sync_chars <= reg_correct_sync_chars + 1;
            else
              reg_known_sync_char_position <= next_octet_index;
              reg_correct_sync_chars <= 1;
            end if;
          elsif is_wrong_char = '0' and (is_f = '1' or is_a = '1') then
            reg_correct_sync_chars <= 0;
            reg_state <= ALIGNED;
          elsif ci_realign = '1' then
            -- align to last known sync char position
            buffer_align_to <= reg_known_sync_char_position + buffer_read_position;
            reg_state <= ALIGNED;
          end if;
        end if;
      end if;
    end if; -- clk, reset
  end process set_next;

  co_correct_sync_chars <= reg_correct_sync_chars;
  buffer_raw_adjust_position <= (buffer_align_to + 1 - buffer_read_position) mod F;
  buffer_adjust_position <= buffer_raw_adjust_position when buffer_raw_adjust_position <= F/2 + 1
                            else buffer_raw_adjust_position - F;

  is_wrong_char <= (is_f and not next_is_last_octet) or (is_a and not next_is_last_octet);
  buffer_character <= di_char.d8b when is_f = '0' and is_a = '0' else
                 reg_last_frame_data when SCRAMBLING = '0' else
                 F_replace_data when is_f = '1' else
                 A_replace_data;

  next_adjusted_octet_index <= (buffer_write_position - buffer_read_position - buffer_adjust_position) mod F;
  next_octet_index <= (buffer_write_position - buffer_read_position) mod F;
  next_is_last_octet <= '1' when next_adjusted_octet_index = F - 1 else '0';

  is_f <= '1' when di_char.d8b = F_char and di_char.kout = '1' else '0';
  is_a <= '1' when di_char.d8b = A_char and di_char.kout = '1' else '0';

  co_error <= '1' when reg_state = MISALIGNED else '0';
  co_aligned <= '1' when reg_state = ALIGNED else '0';
end architecture a1;
