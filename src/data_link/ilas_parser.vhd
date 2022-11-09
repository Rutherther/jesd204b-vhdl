library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.data_link_pkg.all;

entity ilas_parser is
  generic (
    R_character  : std_logic_vector(7 downto 0) := "00011100";
    A_character  : std_logic_vector(7 downto 0) := "01111100";
    Q_character  : std_logic_vector(7 downto 0) := "01011100";
    frames_count : integer                      := 4);

  port (
    ci_char_clk        : in  std_logic;
    ci_reset           : in  std_logic;
    ci_F               : in  integer range 0 to 256;
    ci_state           : in  link_state;
    di_char            : in  character_vector;
    do_config          : out link_config;
    co_finished        : out std_logic;
    co_error           : out std_logic;
    co_wrong_chksum    : out std_logic;
    co_unexpected_char : out std_logic);

end entity ilas_parser;

architecture a1 of ilas_parser is
  constant link_config_length : integer := 111;
  signal link_config_data : std_logic_vector(link_config_length downto 0) := (others => '0');
  signal reg_processing_ilas : std_logic := '0';
  signal reg_frame_index : integer := 0;
  signal reg_octet_index : integer := 0;

  signal next_processing_ilas : std_logic := '0';

  signal processing_ilas : std_logic := '0';

  function getOctetUpIndex (
    octet_index : integer)
    return integer is
  begin  -- function getByteUpIndex
    return link_config_length - 1 - 8 * octet_index;
  end function getByteUpIndex;

  function getDataByIndex (
    data        : std_logic_vector(link_config_length downto 0);
    octet_index : integer;
    bit_index   : integer;
    length      : integer)
    return std_logic_vector is
    variable up_index : integer;
  begin  -- function getDataByIndex
    up_index := getOctetUpIndex(data, octet_index);
    return data(up_index downto up_index - 7)(bit_index + length downto bit_index);
  end function getDataByIndex;
begin  -- architecture a1

  -- ILAS
    -- one multiframe is sent
    -- 4 frames in a multiframe
    -- second frame contains ILAS at third character
    -- each start of a frame should have /R/
    -- each end of a frame should have /A/
    -- second frame:
      -- second_character: /K28.0/
      -- third_character: starts ILAS

  -- if anything does not match (/R/, /A/, /K28.0/, checksum), set co_error
  -- and co_wrong_chksum or co_unexpected_char. Stop processing.
  -- The controller will then request new synchronization try.

  check_chars: process (ci_char_clk, ci_reset) is
    variable up_index : integer;
  begin  -- process check_chars
    if ci_reset = '0' then              -- asynchronous reset (active low)
      co_error <= '0';
      co_unexpected_char <= '0';
      co_wrong_chksum <= '0';
      link_config_data <= (others => '0');
    elsif ci_char_clk'event and ci_char_clk = '1' and processing_ilas = '0' then
      co_error <= '0';
      co_unexpected_char <= '0';
      co_wrong_chksum <= '0';
      link_config_data <= (others => '0');
    elsif ci_char_clk'event and ci_char_clk = '1' and processing_ilas = '1' then  -- rising clock edge
      if reg_octet_index = 0 then       -- Should be /R/
        if di_char.d8b /= R_character then
          co_error <= '1';
          co_unexpected_char <= '1';
        end if;
      elsif reg_octet_index = ci_F - 1 then
        if di_char.d8b /= A_character then  -- Should be /A/
          co_error <= '1';
          co_unexpected_char <= '1';
        end if;
      elsif reg_frame_index = 1 then
        if reg_octet_index = 1 and di_char.d8b /= Q_character then  -- Should be /Q/
          co_error <= '1';
          co_unexpected_char <= '1';
        elsif reg_octet_index > 1 and reg_octet_index < 16 then    -- This is config data
          up_index := getOctetUpIndex(reg_octet_index - 2);
          link_config_data(up_index downto up_index - 7) <= di_char.d8b;
        end if;

        if reg_octet_index = 15 then    -- This is a checksum

        end if;
      end if;
    end if;
  end process check_chars;

  processing_ilas <= next_processing_ilas or reg_processing_ilas;

  next_processing_ilas <= '0' when ci_state = INIT else
                          '1' when reg_processing_ilas = '1' or ci_state = ILAS
                          else '0';

  -- config
  do_config.ADJCNT <= to_integer(unsigned(getDataByIndex(link_config_data, 0, 0, 8)));
  do_config.ADJDIR <= getDataByIndex(link_config_data, 2, 6, 1);

end architecture a1;
