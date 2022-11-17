library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity descrambler is
  port (
    ci_char_clk : in  std_logic;
    ci_reset    : in  std_logic;
    di_char     : in  frame_character;
    do_char     : out frame_character);

end entity descrambler;

-- see 8-bit parallel implementation of self-synchronous descrambler based on
-- 1+x^14 + x^15
-- in JESD204 specification Annex D
architecture a1 of descrambler is
  signal S : std_logic_vector(23 downto 1);
  signal D : std_logic_vector(23 downto 16);
  signal reg_char : frame_character;

  signal next_S : std_logic_vector(15 downto 1);

  function reverseOrder (
    data : std_logic_vector(7 downto 0))
    return std_logic_vector
  is
    variable result : std_logic_vector(7 downto 0);
  begin
    for i in 0 to 7 loop
      result(7 - i) := data(i);
    end loop;  -- i
    return result;
  end function reverseOrder;
begin  -- architecture a1
  set_next: process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_char <= ('0', '0', '0', "00000000", 0, 0, '0');
      S(15 downto 1) <= (others => '0');
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      S(15 downto 1) <= next_S(15 downto 1);
    end if;
  end process set_next;

  do_char.d8b(7 downto 0) <= reverseOrder(D(23 downto 16)) when reg_char.user_data = '1' else reg_char.d8b(7 downto 0);
  do_char.kout <= reg_char.kout;
  do_char.user_data <= reg_char.user_data;
  do_char.disparity_error <= reg_char.disparity_error;
  do_char.missing_error <= reg_char.missing_error;
  do_char.octet_index <= reg_char.octet_index;
  do_char.frame_index <= reg_char.frame_index;

  S(23 downto 16) <= reverseOrder(di_char.d8b(7 downto 0));
  next_S(15 downto 8) <= S(23 downto 16);
  next_S(7 downto 1) <= S(15 downto 9);

  descrambled_generator: for i in 16 to 23 generate
    D(i) <= (S(i-15) xor S(i-14)) xor S(i);
  end generate descrambled_generator;

end architecture a1;
