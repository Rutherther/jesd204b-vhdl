library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity descrambler is
  generic (
    F : integer range 1 to 256);
  port (
    ci_frame_clk : in  std_logic;
    ci_reset    : in  std_logic;
    di_data     : in  std_logic_vector(8*F - 1 downto 0);
    do_data     : out std_logic_vector(8*F - 1 downto 0));

end entity descrambler;

-- 1+x^14 + x^15
-- in JESD204 specification Annex D
architecture a1 of descrambler is
begin  -- architecture a1
  set_next: process (ci_frame_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      do_data <= (others => '0');
    elsif ci_frame_clk'event and ci_frame_clk = '1' then  -- rising clock edge
      do_data <= di_data; -- TODO: implement the descrambler...
    end if;
  end process set_next;

end architecture a1;
