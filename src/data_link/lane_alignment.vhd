-------------------------------------------------------------------------------
-- Title      : Lane alignment
-------------------------------------------------------------------------------
-- File       : lane_alignment.vhd
-------------------------------------------------------------------------------
-- Description: Ensures all lanes are aligned to the same character.
-- Buffers after receiving first /A/ character until ci_start is set.
-- Then starts sending the data from the buffer.
-- That ensures all the lanes start at the same position.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity lane_alignment is
  generic (
    F               : integer range 1 to 256;  -- Number of octets in a frame
    K               : integer range 1 to 32;  -- Number of frames in a multiframe
    BUFFER_SIZE     : integer                      := 256;  -- How many octets to keep
    R_CHAR     : std_logic_vector(7 downto 0) := "00011100";  -- The /R/ character
    DUMMY_CHAR : link_character             := ('1', '0', '0', "10111100", '0'));
-- Character to send before the buffer is ready and started

  port (
    ci_char_clk           : in  std_logic;  -- Character clock
    ci_reset              : in  std_logic;  -- Reset (asynchronous, active low)
    ci_start              : in  std_logic;  -- Start sending the data from the
                                            -- buffer.
    ci_state              : in  link_state;  -- State of the lane
    ci_realign            : in  std_logic;  -- Whether to realign to the last
                                            -- found alignment character
    di_char               : in  link_character;  -- Character from 8b10b decoder
    co_ready              : out std_logic;  -- Whether /A/ was received and
                                            -- waiting for start
    co_aligned            : out std_logic;  -- Whether the alignment is still correct
    co_correct_sync_chars : out integer;  -- How many alignment characters on
                                          -- correct place were found in a row
    co_error              : out std_logic;  -- Whether there is an error
    do_char               : out link_character);  -- The aligned output character

end entity lane_alignment;

architecture a1 of lane_alignment is
  type buffer_array is array (0 to BUFFER_SIZE) of link_character;
  signal buff : buffer_array := (others => ('0', '0', '0', "00000000", '0'));

  signal reg_ready : std_logic := '0';
  signal reg_started : std_logic := '0';
  signal reg_error : std_logic := '0';

  signal reg_write_index : integer range 0 to BUFFER_SIZE := 0;
  signal reg_read_index  : integer range 0 to BUFFER_SIZE := 0;

  signal next_write_index : integer range 0 to BUFFER_SIZE-1 := 0;
  signal next_read_index  : integer range 0 to BUFFER_SIZE-1 := 0;
  signal next_ready       : std_logic                        := '0';
  signal next_started     : std_logic                        := '0';
  signal next_error       : std_logic                        := '0';
begin  -- architecture a1
  set_next : process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_write_index <= 0;
      reg_read_index  <= 0;
      reg_ready       <= '0';
      reg_started     <= '0';
      reg_error       <= '0';
      buff            <= (others => ('0', '0', '0', "00000000", '0'));
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      reg_write_index       <= next_write_index;
      reg_read_index        <= next_read_index;
      reg_ready             <= next_ready;
      reg_started           <= next_started;
      reg_error             <= next_error;
      buff(reg_write_index).d8b <= di_char.d8b;
      buff(reg_write_index).kout <= di_char.kout;
      buff(reg_write_index).disparity_error <= di_char.disparity_error;
      buff(reg_write_index).missing_error <= di_char.missing_error;
		if ci_state = DATA then
			buff(reg_write_index).user_data <= '1';
		else
			buff(reg_write_index).user_data <= '0';
		end if;
    end if;
  end process set_next;

  co_ready <= reg_ready;
  co_error <= reg_error;
  -- TODO handle realignment ?

  next_write_index <= ((reg_write_index + 1) mod BUFFER_SIZE) when reg_ready = '1' or next_ready = '1' else
                      0;
  next_read_index <= ((reg_read_index + 1) mod BUFFER_SIZE) when reg_started = '1' else
                     0;

  next_ready <= '0' when ci_state = INIT else
                '1' when reg_ready = '1' or (di_char.kout = '1' and di_char.d8b = R_CHAR and (ci_state = CGS or ci_state = ILS)) else
                '0';
  next_started <= '0' when reg_ready = '0' or ci_state = CGS else
                  '1' when (ci_start = '1' or reg_started = '1') else
                  '0';
  co_aligned <= reg_started;            -- TODO: check for misalignment
  next_error <= '0' when ci_state = INIT else
                '1' when reg_error = '1' else
                '1' when reg_ready = '1' and reg_started = '0' and (reg_write_index = 0) else
                '0';

  do_char <= DUMMY_CHAR when ci_state = INIT or reg_started = '0' else
             buff(reg_read_index);

end architecture a1;
