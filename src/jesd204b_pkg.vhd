library ieee;
use ieee.std_logic_1164.all;
use work.transport_pkg.all;
use work.data_link_pkg.all;

-- Package for jesd204b types
package jesd204b_pkg is

  -- array input data from lanes
  type lane_input_array is array (natural range <>) of std_logic_vector(9 downto 0);

  -- array for link configs used in multipoint link
  type link_config_array is array (natural range <>) of link_config;

end package jesd204b_pkg;
