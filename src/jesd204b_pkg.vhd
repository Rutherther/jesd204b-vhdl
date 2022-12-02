library ieee;
use ieee.std_logic_1164.all;

package jesd204b_pkg is

  -- array input data from lanes
  type lane_input_array is array (natural range <>) of std_logic_vector(9 downto 0);

end package jesd204b_pkg;
