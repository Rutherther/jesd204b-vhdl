library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

package transport_pkg is

  type sample is record
    data      : std_logic_vector;
    ctrl_bits : std_logic_vector;
  end record sample;

  type frame_character_array is array (natural range <>) of frame_character;
  type samples_array is array (natural range <>, natural range <>) of sample;

end package transport_pkg;
