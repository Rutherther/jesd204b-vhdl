library ieee;
use work.data_link_pkg.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ilas_parser is
  generic (
    K_character  : std_logic_vector(7 downto 0) := "10111100";
    R_character  : std_logic_vector(7 downto 0) := "00011100";
    A_character  : std_logic_vector(7 downto 0) := "01111100";
    Q_character  : std_logic_vector(7 downto 0) := "10011100";  -- 9C
    multiframes_count : integer                      := 4);

  port (
    ci_char_clk        : in  std_logic;
    ci_reset           : in  std_logic;
    ci_F               : in  integer range 0 to 256;
    ci_K               : in  integer range 0 to 32;
    ci_state           : in  link_state;
    di_char            : in  character_vector;
    do_config          : out link_config;
    co_finished        : out std_logic;
    co_error           : out std_logic;
    co_wrong_chksum    : out std_logic;
    co_unexpected_char : out std_logic);

end entity ilas_parser;

architecture a1 of ilas_parser is
  constant link_config_length : integer := 112;
  signal octets_in_multiframe : integer range 0 to 8192 := 0;
  signal link_config_data : std_logic_vector(link_config_length-1 downto 0) := (others => '0');
  signal reg_processing_ilas : std_logic := '0';
  signal reg_multiframe_index : integer := 0;
  signal reg_octet_index : integer := 0;

  signal next_processing_ilas : std_logic := '0';
  signal next_multiframe_index : integer := 0;
  signal next_octet_index : integer := 0;

  signal finished : std_logic := '0';
  signal err : std_logic := '0';


  function getOctetUpIndex (
    octet_index : integer)
    return integer is
  begin  -- function getByteUpIndex
    return link_config_length - 1 - 8 * octet_index;
  end function getOctetUpIndex;

  function getDataByIndex (
    data        : std_logic_vector(link_config_length-1 downto 0);
    octet_index : integer;
    bit_index   : integer;
    length      : integer)
    return std_logic_vector is
    variable up_index : integer;
  begin  -- function getDataByIndex
    up_index := getOctetUpIndex(octet_index);
    return data(up_index - 7 + bit_index + length - 1 downto up_index - 7 + bit_index);
  end function getDataByIndex;

  function getBitByIndex (
    data        : std_logic_vector(link_config_length-1 downto 0);
    octet_index : integer;
    bit_index   : integer)
    return std_logic is
    variable up_index : integer;
  begin  -- function getBitByIndex
    up_index := getOctetUpIndex(octet_index);
    return data(up_index - 7 + bit_index);
  end function getBitByIndex;
begin  -- architecture a1
  --octets_in_multiframe <= ci_F * CI_K;
  octets_in_multiframe <= 17;
  -- ILAS
    -- one multiframe is sent
    -- 4 frames in a multiframe
    -- second frame contains ILAS at third character
    -- each start of a frame should have /R/
    -- each end of a frame should have /A/
    -- second frame:
      -- second_character: /K28.0/
      -- third_character: starts ILAS

  -- if anything does not match (/R/, /A/, /K28.0/, checksum), set error
  -- and co_wrong_chksum or co_unexpected_char. Stop processing.
  -- The controller will then request new synchronization try.

  set_next: process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_octet_index <= 0;
      reg_multiframe_index <= 0;
      reg_processing_ilas <= '0';
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      reg_octet_index <= next_octet_index;
      reg_multiframe_index <= next_multiframe_index;
      reg_processing_ilas <=  next_processing_ilas;
    end if;
  end process set_next;

  check_chars: process (ci_char_clk, ci_reset) is
    variable up_index : integer range 7 to link_config_length-1;
    variable processing_ilas : std_logic;
  begin  -- process check_chars
    processing_ilas := next_processing_ilas or reg_processing_ilas;
    if ci_reset = '0' then              -- asynchronous reset (active low)
      err <= '0';
      co_unexpected_char <= '0';
      co_wrong_chksum <= '0';
      finished <= '0';
      link_config_data <= (others => '0');
    elsif ci_char_clk'event and ci_char_clk = '1' and (processing_ilas = '0' or ci_state = INIT) then
      err <= '0';
      co_unexpected_char <= '0';
      co_wrong_chksum <= '0';

      if ci_state /= DATA and ci_state /= ILS then
        link_config_data <= (others => '0');
        finished <= '0';
      end if;
    elsif ci_char_clk'event and ci_char_clk = '1' and err = '1' then
      if next_processing_ilas = '0' then
        err <= '0';
        co_unexpected_char <= '0';
        co_wrong_chksum <= '0';
      end if;
      -- If there is an error, stop processing.
    elsif ci_char_clk'event and ci_char_clk = '1' and processing_ilas = '1' then  -- rising clock edge
      if reg_octet_index = 0 then       -- Should be /R/
        if di_char.d8b /= R_character or di_char.kout = '0' then
          err <= '1';
          co_unexpected_char <= '1';
        end if;
      elsif di_char.d8b = R_character and di_char.kout = '1' then
        err <= '1';
        co_unexpected_char <= '1';
      elsif reg_octet_index = octets_in_multiframe - 1 then
        if di_char.d8b /= A_character or di_char.kout = '0' then  -- Should be /A/
          err <= '1';
          co_unexpected_char <= '1';
        elsif reg_multiframe_index = 3 and err = '0' then
          finished <= '1';
        end if;
      elsif di_char.d8b = A_character and di_char.kout = '1' then
        err <= '1';
        co_unexpected_char <= '1';
      elsif reg_multiframe_index = 1 then
        if reg_octet_index = 1 and (di_char.d8b /= Q_character or di_char.kout = '0') then  -- Should be /Q/
          err <= '1';
          co_unexpected_char <= '1';
        elsif reg_octet_index > 1 and reg_octet_index < 16 then    -- This is config data
          up_index := getOctetUpIndex(reg_octet_index - 2);
          link_config_data(up_index downto up_index - 7) <= di_char.d8b;
        end if;

        if reg_octet_index = 15 then    -- This is a checksum
          -- TODO: calculate checksum
          if di_char.d8b = "00000000" then
            co_wrong_chksum <=  '1';
            err <= '1';
          end if;
        end if;
      elsif reg_multiframe_index > multiframes_count - 1 then
        err <= '1';
      end if;
    end if;
  end process check_chars;

  co_finished <= finished;
  co_error <= '1' when err = '1' and ci_state = ILS else '0';

  next_processing_ilas <= '0' when ci_state = INIT or finished = '1' else
                          '0' when ci_state = CGS and reg_processing_ilas = '1' else
                          '0' when reg_multiframe_index = 3 and reg_octet_index = octets_in_multiframe - 1 else
                          '1' when ci_state = CGS and not (di_char.d8b = K_character and di_char.kout = '1') else
                          '1' when reg_processing_ilas = '1' or ci_state = ILS else
                          '0';

  -- octet, multiframe index
  next_multiframe_index <= 0 when reg_processing_ilas = '0' and next_processing_ilas = '0' else
                           (reg_multiframe_index + 1) when reg_octet_index = octets_in_multiframe - 1 else
                           reg_multiframe_index;
  next_octet_index <= 0 when (next_processing_ilas = '0' and reg_processing_ilas = '0') or (next_processing_ilas = '0' and reg_processing_ilas = '1') else
                      (reg_octet_index + 1) mod octets_in_multiframe;

  -- config
  do_config.DID <= to_integer(unsigned(getDataByIndex(link_config_data, 0, 0, 8)));
  do_config.ADJDIR <= getBitByIndex(link_config_data, 2, 6);
  do_config.ADJCNT <= to_integer(unsigned(getDataByIndex(link_config_data, 1, 4, 4)));
  do_config.BID <= to_integer(unsigned(getDataByIndex(link_config_data, 1, 0, 4)));
  do_config.PHADJ <= getBitByIndex(link_config_data, 2, 5);
  do_config.LID <= to_integer(unsigned(getDataByIndex(link_config_data, 2, 0, 5)));
  do_config.SCR <= getBitByIndex(link_config_data, 3, 7);
  do_config.L <= to_integer(unsigned(getDataByIndex(link_config_data, 3, 0, 5))) + 1;
  do_config.F <= to_integer(unsigned(getDataByIndex(link_config_data, 4, 0, 8))) + 1;
  do_config.K <= to_integer(unsigned(getDataByIndex(link_config_data, 5, 0, 5))) + 1;
  do_config.M <= to_integer(unsigned(getDataByIndex(link_config_data, 6, 0, 8))) + 1;
  do_config.CS <= to_integer(unsigned(getDataByIndex(link_config_data, 7, 6, 2)));
  do_config.N <= to_integer(unsigned(getDataByIndex(link_config_data, 7, 0, 5))) + 1;
  do_config.SUBCLASSV <= to_integer(unsigned(getDataByIndex(link_config_data, 8, 5, 3)));
  do_config.Nn <= to_integer(unsigned(getDataByIndex(link_config_data, 8, 0, 5))) + 1;
  do_config.JESDV <= to_integer(unsigned(getDataByIndex(link_config_data, 9, 5, 3)));
  do_config.S <= to_integer(unsigned(getDataByIndex(link_config_data, 9, 0, 5))) + 1;
  do_config.HD <= getBitByIndex(link_config_data, 10, 7);
  do_config.CF <= to_integer(unsigned(getDataByIndex(link_config_data, 9, 0, 5)));
  do_config.RES1 <= getDataByIndex(link_config_data, 11, 0, 8);
  do_config.RES2 <= getDataByIndex(link_config_data, 12, 0, 8);
  do_config.CHKSUM <= to_integer(unsigned(getDataByIndex(link_config_data, 13, 0, 8)));
  do_config.X <=  getBitByIndex(link_config_data, 2, 7) & getDataByIndex(link_config_data, 3, 5, 2) & getDataByIndex(link_config_data, 5, 5, 3) & getBitByIndex(link_config_data, 7, 5) & getDataByIndex(link_config_data, 10, 5, 2);
end architecture a1;
