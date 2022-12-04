library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity lane_alignment is
  generic (
    buffer_size     : integer          := 256;
    alignment_character : std_logic_vector(7 downto 0) := "01111100";
    dummy_character : character_vector := ('1', '0', '0', "10111100", '0'));

  port (
    ci_char_clk           : in  std_logic;
    ci_reset              : in  std_logic;
    ci_start              : in  std_logic;
    ci_state              : in  link_state;
    ci_realign            : in  std_logic;
    ci_F                  : in  integer range 0 to 256;
    ci_K                  : in  integer range 0 to 32;
    di_char               : in  character_vector;
    co_ready              : out std_logic;
    co_aligned            : out std_logic;
    co_correct_sync_chars : out integer;
    co_error              : out std_logic;
    do_char               : out character_vector);

end entity lane_alignment;

architecture a1 of lane_alignment is
  type buffer_array is array (0 to buffer_size) of character_vector;
  signal buff : buffer_array := (others => ('0', '0', '0', "00000000", '0'));

  signal reg_ready : std_logic := '0';
  signal reg_started : std_logic := '0';
  signal reg_error : std_logic := '0';

  signal reg_write_index : integer := 0;
  signal reg_read_index : integer := 0;

  signal next_write_index : integer range 0 to buffer_size-1 := 0;
  signal next_read_index  : integer range 0 to buffer_size-1 := 0;
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
      buff(reg_write_index) <= di_char;
    end if;
  end process set_next;

  co_ready <= reg_ready;
  co_error <= reg_error;
  -- TODO handle realignment ?

  next_write_index <= ((reg_write_index + 1) mod buffer_size) when reg_ready = '1' or next_ready = '1' else
                      0;
  next_read_index <= ((reg_read_index + 1) mod buffer_size) when reg_started = '1' else
                     0;

  next_ready <= '0' when ci_state = INIT else
                '1' when reg_ready = '1' or (di_char.kout = '1' and di_char.d8b = alignment_character and (ci_state = CGS or ci_state = ILS)) else
                '0';
  next_started <= '0' when reg_ready = '0' else
                  '1' when reg_ready = '1' and (ci_start = '1' or reg_started = '1') else
                  '0';
  co_aligned <= reg_started;            -- TODO: check for misalignment
  next_error <= '0' when ci_state = INIT else
                '1' when reg_error = '1' else
                '1' when reg_ready = '1' and reg_started = '0' and (reg_write_index = 0) else
                '0';

  do_char <= dummy_character when ci_state = INIT or reg_started = '0' else
             buff(reg_read_index);
  -- TODO do_char.user_data <= '1' when ci_state = DATA and reg_started = '1' else '0';

end architecture a1;
