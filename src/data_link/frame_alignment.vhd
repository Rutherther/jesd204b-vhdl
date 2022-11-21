library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity frame_alignment is
  generic (
    sync_char      : std_logic_vector(7 downto 0) := "10111100";
    A_char         : std_logic_vector(7 downto 0) := "01111100";
    F_char         : std_logic_vector(7 downto 0) := "11111100";
    F_replace_data : std_logic_vector(7 downto 0) := "11111100";  -- The character to replace with upon receiving /F/ with scrambled data
    A_replace_data : std_logic_vector(7 downto 0) := "01111100");  -- The character to replace with upon receiving /A/ with scrambled data
  port (
    ci_char_clk           : in  std_logic;
    ci_reset              : in  std_logic;
    ci_F                  : in  integer range 0 to 256;  -- The number of octets in a frame
    ci_K                  : in  integer range 0 to 32;  -- The number of frames in a multiframe
    ci_request_sync       : in  std_logic;  -- Whether sync is requested
    ci_scrambled          : in  std_logic;  -- Whether the data is scrambled
    ci_realign            : in  std_logic;
    di_char               : in  character_vector;  -- The received character
    co_aligned            : out std_logic;
    co_error              : out std_logic;
    co_correct_sync_chars : out integer;
    do_char               : out frame_character);  -- The output character
end entity frame_alignment;

architecture a1 of frame_alignment is
  type alignment_state is (INIT, RECEIVED_K, ALIGNED, MISALIGNED);
  signal reg_state : alignment_state := INIT;

  signal reg_last_frame_data : std_logic_vector(7 downto 0) := "00000000";

  signal next_is_last_octet : std_logic := '0';
  signal next_is_last_frame : std_logic := '0';

  signal is_f : std_logic := '0';
  signal is_a : std_logic := '0';

  signal is_wrong_char : std_logic := '0';

  signal reg_octet_index : integer range 0 to 256 := 0;
  signal reg_frame_index : integer range 0 to 32 := 0;
  signal reg_correct_sync_chars : integer := 0;
  signal reg_known_sync_char_position : integer range 0 to 256;

  signal next_octet_index : integer range 0 to 256 := 0;
  signal next_frame_index : integer range 0 to 32 := 0;
  signal next_char : character_vector := ('0', '0', '0', "00000000", '0');
begin  -- architecture a1
  set_next: process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_frame_index <= 0;
      reg_octet_index <= 0;
      do_char <= ('0', '0', '0', "00000000", 0, 0, '0');
      reg_state <= INIT;
      reg_correct_sync_chars <= 0;
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      do_char.kout <= next_char.kout;
      do_char.d8b <= next_char.d8b;
      do_char.disparity_error <= next_char.disparity_error;
      do_char.missing_error <= next_char.missing_error;
      do_char.user_data <= next_char.user_data;
      do_char.frame_index <= reg_frame_index;

      -- set last_frame_data if this is the last frame and not /F/ or /A/
      if next_is_last_octet = '1' and not (is_f = '1' or is_a = '1') then
        reg_last_frame_data <= di_char.d8b;
      end if;

      if ci_request_sync = '1' then
        reg_state <= INIT;
        reg_frame_index <= 0;
        reg_octet_index <= 0;
        do_char.octet_index <= 0;
        do_char.frame_index <= 0;
      elsif di_char.kout = '1' and di_char.d8b = sync_char then
        reg_state <= RECEIVED_K;
        reg_frame_index <= 0;
        reg_octet_index <= 0;
        do_char.octet_index <= 0;
        do_char.frame_index <= 0;
      elsif reg_state = INIT then
        reg_frame_index <= 0;
        reg_octet_index <= 0;
        do_char.octet_index <= 0;
        do_char.frame_index <= 0;
      elsif reg_state = RECEIVED_K then
        reg_frame_index <= 0;
        reg_octet_index <= 0;
        do_char.octet_index <= 0;
        do_char.frame_index <= 0;

        if di_char.d8b /= sync_char or di_char.kout = '0' then
          reg_state <= ALIGNED;
        end if; -- switch to aligned
      else
        reg_frame_index <= next_frame_index;
        reg_octet_index <= next_octet_index;
        do_char.octet_index <= next_octet_index;
        do_char.frame_index <= next_frame_index;
        if reg_state = ALIGNED then
          if is_wrong_char = '1' then
            reg_state <= MISALIGNED;
            reg_correct_sync_chars <= 1;
            reg_known_sync_char_position <= reg_octet_index;
          end if;
        elsif reg_state = MISALIGNED then
          if is_wrong_char = '1' then
            if reg_known_sync_char_position = reg_octet_index then
              reg_correct_sync_chars <= reg_correct_sync_chars + 1;
            else
              reg_known_sync_char_position <= reg_octet_index;
              reg_correct_sync_chars <= 1;
            end if;
          elsif is_wrong_char = '0' and (is_f = '1' or is_a = '1') then
            reg_correct_sync_chars <= 0;
            reg_state <= ALIGNED;
          elsif ci_realign = '1' then
            reg_correct_sync_chars <= 0;
            reg_octet_index <= (reg_octet_index + ((ci_F - 1) - reg_known_sync_char_position)) mod ci_F;
            do_char.octet_index <= (reg_octet_index + ((ci_F - 1) - reg_known_sync_char_position)) mod ci_F;

            reg_frame_index <= reg_frame_index + 1;
            do_char.frame_index <= reg_frame_index + 1;
            reg_state <= ALIGNED;
          end if;
        end if;
      end if; -- in RECEIVED_K
    end if; -- clk, reset
  end process set_next;

  is_wrong_char <= (is_f and not next_is_last_octet) or (is_a and not (next_is_last_octet and next_is_last_frame));
  next_char.kout <= di_char.kout when is_f = '0' and is_a = '0' else '0';
  next_char.d8b <= di_char.d8b when is_f = '0' and is_a = '0' else
                 reg_last_frame_data when ci_scrambled = '0' else
                 F_replace_data when is_f = '1' else
                 A_replace_data;
  next_char.disparity_error <= di_char.disparity_error;
  next_char.missing_error <= di_char.missing_error;
  next_char.user_data <= di_char.user_data;

  next_is_last_octet <= '1' when next_octet_index = ci_F - 1 else '0';
  next_is_last_frame <= '1' when next_frame_index = ci_K - 1 else '0';

  is_f <= '1' when di_char.d8b = F_char and di_char.kout = '1' else '0';
  is_a <= '1' when di_char.d8b = A_char and di_char.kout = '1' else '0';

  next_frame_index <= reg_frame_index when reg_octet_index < (ci_F - 1) else
                      (reg_frame_index + 1) mod ci_K;
  next_octet_index <= (reg_octet_index + 1) mod ci_F;

  co_correct_sync_chars <= reg_correct_sync_chars;
  co_error <= '1' when reg_state = MISALIGNED else '0';
  co_aligned <= '1' when reg_state = ALIGNED else '0';
end architecture a1;
