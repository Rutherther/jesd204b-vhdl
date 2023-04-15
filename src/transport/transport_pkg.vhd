library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

-- Package for transport layer types
package transport_pkg is

  type frame_state is record           -- An errors passed from data_link to transport
    user_data            : std_logic;   -- All characters are user_data
    invalid_characters   : std_logic;   -- Any of the charachers should not be
                                        -- there (ie. there is a control)
    not_enough_data      : std_logic;   -- There is not enough data in the
                                        -- buffer, data will be sent on next
                                        -- frame clock
    ring_buffer_overflow : std_logic;   -- Buffer storing characters has overflowed,
                                        -- meaning frame clock is too slow
    disparity_error      : std_logic;   -- Any character had disparity error
    not_in_table_error   : std_logic;   -- Any character not in table
    wrong_alignment      : std_logic;   -- Alignment character was detected to
                                        -- be on wrong position, possible misalignment
    last_frame_repeated  : std_logic;   -- Whether last frame was repeated
                                        -- instead of new frame
  end record frame_state;

  type ctrl_bits_array is array (natural range <>, natural range <>) of std_logic_vector;
  type samples_array is array (natural range <>, natural range <>) of std_logic_vector;

  type frame_state_array is array (natural range <>) of frame_state;

  -- Array of frame characters (characters in one frame)
  type lane_character_array is array (natural range <>) of std_logic_vector;

end package transport_pkg;
