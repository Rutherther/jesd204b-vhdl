library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

package transport_pkg is

  type sample is record
    data      : std_logic_vector;--(SAMPLE_SIZE - 1 downto 0);
    ctrl_bits : std_logic_vector;--(CONTROL_SIZE - 1 downto 0);
  end record sample;

  type frame_character_array is array (natural range <>) of frame_character;
  type samples_array is array (natural range <>, natural range <>) of sample;

end package transport_pkg;
