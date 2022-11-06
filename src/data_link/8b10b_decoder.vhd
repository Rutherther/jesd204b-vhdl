library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.data_link_pkg.all;

entity an8b10b_decoder is
  port (
    ci_char_clk : in  std_logic;        -- The character clock
    ci_reset    : in  std_logic;        -- The reset
    di_10b      : in  std_logic_vector(9 downto 0);  -- The 8b10b encoded input data
    do_char     : out character_vector;  -- The output character vector
    co_error    : out std_logic);       -- Whether there is an error
                                        -- (disparity or invalid character)
end entity an8b10b_decoder;

architecture a1 of an8b10b_decoder is
  type a5b6b_array is array (0 to 63) of std_logic_vector(4 downto 0);
  type a3b4b_array is array (0 to 15) of std_logic_vector(2 downto 0);
  constant a5b6b_alphabet : a5b6b_array := (
    39 => "00000", 24 => "00000", 29 => "00001", 34 => "00001",
    45 => "00010", 18 => "00010", 49 => "00011", 53 => "00100",
    10 => "00100", 41 => "00101", 25 => "00110", 56 => "00111",
    7 => "00111", 57 => "01000", 6 => "01000", 37 => "01001",
    21 => "01010", 52 => "01011", 13 => "01100", 44 => "01101",
    28 => "01110", 23 => "01111", 40 => "01111", 27 => "10000",
    36 => "10000", 35 => "10001", 19 => "10010", 50 => "10011",
    11 => "10100", 42 => "10101", 26 => "10110", 58 => "10111",
    5 => "10111", 51 => "11000", 12 => "11000", 38 => "11001",
    22 => "11010", 54 => "11011", 9 => "11011", 14 => "11100",
    46 => "11101", 17 => "11101", 30 => "11110", 33 => "11110",
    43 => "11111", 20 => "11111",
    others => (others => '0'));  -- Alphabet for decoding 5b6b code
  constant a3b4b_alphabet : a3b4b_array := (
    4 => "000", 11 => "000", 9 => "001", 5 => "010",
    3 => "011", 12 => "011", 2 => "100", 13 => "100",
    10 => "101", 6 => "110", 1 => "111", 14 => "111",
    8 => "111", 7 => "111",
    others => (others => '0'));  -- Alphabet for decoding 3b4b code
  constant ctrl_3b4b_alphabet : a3b4b_array := (
    4 => "000", 9 => "001", 5 => "010",
    3 => "011", 2 => "100", 10 => "101",
    6 => "110", 8 => "111",
    others => (others => '0'));         -- Alphabet for decoding control 3b4b code
  constant ctrl_5b6b_alphabet : a5b6b_array := (
    15 => "11100", 58 => "10111", 54 => "11011",
    46 => "11101", 30 => "11110",
    others => (others => '0'));         -- Alphabet for decoding control 5b6b code

  signal reg_do_8b : std_logic_vector(7 downto 0) := (others => '0');
  signal reg_rd : std_logic := '0';         -- The current running disparity
                                            -- (0 for RD = -1)

  signal next_disparity_error : std_logic;
  signal next_missing_error : std_logic;
  signal next_error : std_logic;
  signal next_kout : std_logic := '0';
  signal next_rd : std_logic := '0';
  signal change_rd : std_logic := '0';
  signal next_do_8b : std_logic_vector(7 downto 0) := (others => '0');

  signal data_4b : std_logic_vector(3 downto 0) := "0000";
  signal data_6b : std_logic_vector(5 downto 0) := "000000";
  signal data_4b_int : integer range 0 to 15 := 0;
  signal data_6b_int : integer range 0 to 63 := 0;
  signal data_4b_int_neg : integer range 0 to 15 := 0;
  signal data_6b_int_neg : integer range 0 to 63 := 0;

  function IsMissingCharacter(
    cdata_4b_int : integer range 0 to 15;
    cdata_6b_int : integer range 0 to 63
  ) return std_logic is
    variable d : std_logic;
  begin
    if cdata_4b_int = 0 or cdata_4b_int = 15 then
      return '1';
    end if;
    if cdata_6b_int < 5 then
      return '1';
    end if;
    if cdata_6b_int > 58 then
      return '1';
    end if;

    if cdata_6b_int = 8 or cdata_6b_int = 16 or cdata_6b_int = 47 or cdata_6b_int = 55 then
      return '1';
    end if;

    return '0';
  end function;

  function IsControlCharacter (
    data : std_logic_vector(9 downto 0)) return std_logic is
  begin
    if data(9 downto 4) = "001111" or data(9 downto 4) = "110000" then
      return '1';
    end if;

    if data = "1110101000" or data = "1101101000" or data = "1011101000" or data = "0111101000" then
      return '1';
    end if;
    if data = not "1110101000" or data = not "1101101000" or data = not "1011101000" or data = not "0111101000" then
      return '1';
    end if;
    return '0';
  end function;

  function IsDisparityCorrect (
    cdata_4b : std_logic_vector(3 downto 0);
    cdata_6b : std_logic_vector(5 downto 0);
    rd   : std_logic)
    return std_logic is
    variable ones_6b : integer range 0 to 63 := 0;
    variable ones_4b : integer range 0 to 15 := 0;
    variable correct_rd : std_logic;
  begin  -- function IsDisparityCorrect
    correct_rd := rd;

    for i in 0 to 5 loop
      if cdata_6b(i) = '1' then
        ones_6b := ones_6b + 1;
      end if;

      if i < 4 and cdata_4b(i) = '1' then
        ones_4b := ones_4b + 1;
      end if;
    end loop;  -- i

    if ones_6b + ones_4b > 6 or ones_6b + ones_4b < 4 then
      return '0';
    end if;

    if ones_6b > 3 then
      correct_rd := '0';
    elsif ones_6b < 3 then
      correct_rd := '1';
    else
      if ones_4b > 2 then
        correct_rd := '0';
      elsif ones_4b < 2 then
        correct_rd := '1';
      else
        if cdata_6b = "000111" then
          correct_rd := '1';
        elsif cdata_6b = "111000" then
          correct_rd := '0';
        elsif cdata_4b = "0011" then
          correct_rd := '1';
        elsif cdata_4b = "1100" then
          correct_rd := '0';
        end if;
      end if;
    end if;

    if correct_rd = rd then
      return '1';
    else
      return '0';
    end if;
  end function IsDisparityCorrect;

begin  -- architecture a1
  -- purpose: Set next states
  -- type   : sequential
  -- inputs : ci_char_clk, ci_reset
  -- outputs: co_error, co_disparity_error, co_missing_error, reg_do_8b,
  -- reg_rd, co_kout
  set_next: process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      co_error <= '0';
      do_char.disparity_error <= '0';
      do_char.missing_error <= '0';
      do_char.kout <= '0';
      reg_do_8b <= (others => '0');
      reg_rd <= '0';
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      co_error <= next_error;
      do_char.disparity_error <= next_disparity_error;
      do_char.missing_error <= next_missing_error;
      do_char.kout <= next_kout;
      reg_do_8b <= next_do_8b;
      reg_rd <= next_rd;
    end if;
  end process set_next;
  data_4b <= di_10b(3 downto 0);
  data_6b <= di_10b(9 downto 4);
  data_4b_int <= to_integer(unsigned(data_4b));
  data_6b_int <= to_integer(unsigned(data_6b));
  data_4b_int_neg <= to_integer(unsigned(not data_4b));
  data_6b_int_neg <= to_integer(unsigned(not data_6b));

  -- running disparity
  -- change in case the number of 0s doesn't match nubmer of 1s (xor_reduce
  -- will output 1 ... it's basically an odd parity)
  -- synchronize in case of disparity error (can be either at the beginning of
  -- communication or the last character was loaded incorrectly)
  change_rd <= (not xor_reduce(di_10b) or next_disparity_error) and not (not xor_reduce(di_10b) and next_disparity_error);
  next_rd <= (not reg_rd and change_rd) or (reg_rd and not change_rd);

  -- control characters
  next_kout <= IsControlCharacter(di_10b);

  -- errors
  next_missing_error <= IsMissingCharacter(data_4b_int, data_6b_int) and not next_kout;
  next_disparity_error <= not IsDisparityCorrect(data_4b, data_6b, reg_rd);
  next_error <= next_missing_error or next_disparity_error;

  next_do_8b <= a3b4b_alphabet(data_4b_int) & a5b6b_alphabet(data_6b_int) when next_kout = '0' else
                ctrl_3b4b_alphabet(data_4b_int_neg) & ctrl_5b6b_alphabet(data_6b_int_neg) when (reg_rd = '1' and next_disparity_error = '0') else
                ctrl_3b4b_alphabet(data_4b_int) & ctrl_5b6b_alphabet(data_6b_int) when (reg_rd = '1' or next_disparity_error = '0') else
                ctrl_3b4b_alphabet(data_4b_int_neg) & ctrl_5b6b_alphabet(data_6b_int_neg);
  do_char.d8b <= reg_do_8b;
end architecture a1;
