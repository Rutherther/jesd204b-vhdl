library ieee;
use ieee.std_logic_1164.all;

package data_link_pkg is

  type character_vector is record
    kout            : std_logic;  -- Whether the character is a control character
    disparity_error : std_logic;  -- Whether there was a disparity error (if this is true, the character will still be correct)
    missing_error   : std_logic;  -- Whether the character was not found in the table
    d8b             : std_logic_vector(7 downto 0);  -- The decoded data
  end record character_vector;

  type link_state is (
    INIT,
    CGS,
    ILAS,
    DATA,
    ERR);                               -- States of the link

end package data_link_pkg;
