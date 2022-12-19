library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

-- Package for transport layer types
package transport_pkg is

  -- Output sample with control bits
  type sample is record
    data      : std_logic_vector;
    ctrl_bits : std_logic_vector;
  end record sample;

  -- Array of frame characters (characters in one frame)
  type frame_character_array is array (natural range <>) of frame_character;

  -- Array of samples in one frame by converter and by sample (used with oversampling)
  type samples_array is array (natural range <>, natural range <>) of sample;

end package transport_pkg;
