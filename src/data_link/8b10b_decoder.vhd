library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity an8b10b_decoder is
  port (
    ci_char_clk : in  std_logic;        -- The character clock
    ci_reset    : in  std_logic;        -- The reset
    d_in        : in  std_logic_vector(9 downto 0);  -- The 8b10b encoded input data
    co_disparity_error    : out std_logic;        -- Whether there is an error
    co_missing_error    : out std_logic;        -- Whether there is an error
    co_error    : out std_logic;        -- Whether there is an error
                                        -- (disparity or invalid character)
    co_kout    : out std_logic;        -- Whether the output is a control character
    d_out       : out std_logic_vector(7 downto 0));  -- The decoded 8 bit output data

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
    others => (others => '0'));  -- Alphabet for decoding 5b6b code

  signal reg_d_out : std_logic_vector(7 downto 0) := (others => '0');
  signal reg_rd : std_logic := '0';         -- The current running disparity
                                            -- (0 for RD = -1)

  signal next_disparity_error : std_logic;
  signal next_missing_error : std_logic;
  signal next_error : std_logic;
  signal next_kout : std_logic := '0';
  signal next_rd : std_logic := '0';
  signal change_rd : std_logic := '0';
  signal next_d_out_positive : std_logic_vector(7 downto 0) := (others => '0');
  signal next_d_out_negative : std_logic_vector(7 downto 0) := (others => '0');
  signal next_d_out : std_logic_vector(7 downto 0) := (others => '0');

  signal data_4b : std_logic_vector(3 downto 0);
  signal data_6b : std_logic_vector(5 downto 0);
  signal data_4b_int : integer;
  signal data_6b_int : integer;
  signal data_4b_int_neg : integer;
  signal data_6b_int_neg : integer;

  signal character_missing_positive : std_logic;
  signal character_missing_negative : std_logic;
  -- Either next_d_out_positive for RD = 1 or next_d_out_negative for RD = -1;

  function IsMissingCharacter(data: std_logic_vector(9 downto 0)) return std_logic is
    variable data_int : integer := to_integer(unsigned(data));
    variable d : std_logic;
  begin
    if data_int < 5 then
      return '1';
    end if;
    if data_int > 58 then
      return '1';
    end if;

    if data_int = 8 or data_int = 16 or data_int = 47 or data_int = 55 then
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
begin  -- architecture a1
  -- purpose: Set next states
  -- type   : sequential
  -- inputs : ci_char_clk, ci_reset
  -- outputs: 
  set_next: process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      co_error <= '0';
      co_disparity_error <= '0';
      co_missing_error <= '0';
      reg_d_out <= (others => '0');
      reg_rd <= '0';
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      co_error <= next_error;
      co_disparity_error <= next_disparity_error;
      co_missing_error <= next_missing_error;
      reg_d_out <= next_d_out;
      reg_rd <= next_rd;
      co_kout <= next_kout;
    end if;
  end process set_next;
  character_missing_positive <= IsMissingCharacter(d_in) and not IsControlCharacter(d_in);
  character_missing_negative <= IsMissingCharacter(not d_in) and not IsControlCharacter(not d_in);
  data_4b <= d_in(3 downto 0);
  data_6b <= d_in(9 downto 4);
  data_4b_int <= to_integer(unsigned(data_4b));
  data_6b_int <= to_integer(unsigned(data_6b));
  data_4b_int_neg <= to_integer(unsigned(not data_4b));
  data_6b_int_neg <= to_integer(unsigned(not data_6b));

  -- running disparity
  -- change in case the number of 0s doesn't match nubmer of 1s (xor_reduce
  -- will output 1 ... it's basically an odd parity)
  -- synchronize in case of disparity error (can be either at the beginning of
  -- communication or the last character was loaded incorrectly)
  change_rd <= (xor_reduce(d_in) or next_disparity_error) and not (xor_reduce(d_in) and next_disparity_error);
  next_rd <= (not reg_rd and change_rd) or (reg_rd and not change_rd);

  -- control characters
  next_kout <= IsControlCharacter(d_in);

  -- errors
  next_missing_error <= character_missing_positive and character_missing_negative;
  next_disparity_error <= (reg_rd and character_missing_positive) or (not reg_rd and character_missing_negative);
  next_error <= next_missing_error or next_disparity_error;

  -- output decoded data
  next_d_out_positive <= a3b4b_alphabet(data_4b_int) & a5b6b_alphabet(data_6b_int);
  next_d_out_negative <= a3b4b_alphabet(data_4b_int_neg) & a5b6b_alphabet(data_6b_int_neg);

  -- positive in case of RD = 1, not disparity error, positive in case of RD =
  -- -1, disparity error. Negative in case RD = -1, not disparity error,
  -- negative in case RD = 1, disparity error.
  next_d_out <= next_d_out_positive when (reg_rd = '1' and next_disparity_error = '0') else
                next_d_out_negative when (reg_rd = '1' or next_disparity_error = '0') else
                next_d_out_positive;
  d_out <= reg_d_out;
end architecture a1;
