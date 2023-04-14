library ieee;
use ieee.std_logic_1164.all;

package data_link_pkg is

  type link_character is record
    kout            : std_logic;  -- Whether the character is a control character
    disparity_error : std_logic;  -- Whether there was a disparity error (if this is true, the character will still be correct)
    missing_error   : std_logic;  -- Whether the character was not found in the table
    d8b             : std_logic_vector(7 downto 0);  -- The decoded data
    user_data      : std_logic;         -- Whether the data is user data (in
                                        -- DATA state, false otherwise)
  end record link_character;

  type frame_character is record
    kout            : std_logic;  -- Whether the character is a control character
    disparity_error : std_logic;  -- Whether there was a disparity error (if this is true, the character will still be correct)
    missing_error   : std_logic;  -- Whether the character was not found in the table
    d8b             : std_logic_vector(7 downto 0);  -- The decoded data
    octet_index    : integer range 0 to 256;  -- The position of the octet in a
                                              -- frame
    frame_index    : integer range 0 to 32;  -- The position of the frame in multiframe
    user_data      : std_logic;         -- Whether the data is user data (in
                                        -- DATA state, false otherwise)
  end record frame_character;

  type link_state is (
    INIT,                               -- Initial state, waiting for /K/ characters
    CGS,                                -- Code group synchronization, after
                                        -- receiving /K/ character
    ILS,                                -- Initial lane synchronization
                                        -- (containing link configuration)
    DATA);                               -- States of the link

  type link_config is record
    ADJCNT    : integer range 0 to 15;  -- Number of adjustment resolution steps to adjust DAC LMFC
    ADJDIR    : std_logic;  -- Direction to adjust DAC LMFC (0 - advance, 1 - delay)
    BID       : integer range 0 to 15;  -- Bank Id
    CF        : integer range 0 to 32;  -- No. of control words per frame clock period per link
    CS        : integer range 0 to 3;   -- No. of control bits per sample
    DID       : integer range 0 to 255;        -- Device identification number
    F         : integer range 1 to 256;        -- No. of octets per frame
    HD        : std_logic;              -- High density format
    JESDV     : integer range 0 to 7;                -- JESD204 version
    K         : integer range 1 to 32;  -- No. of frames per multiframe
    L         : integer range 1 to 32;  -- No. of lanes per converter
    LID       : integer range 0 to 31;  -- Lane identification number
    M         : integer range 1 to 256;        -- No. of converters per device
    N         : integer range 1 to 32;  -- Converter resolution
    Nn        : integer range 1 to 32;  -- Total no. of bits per sample
    PHADJ     : std_logic;              -- Phase adjustment request to DAC
    S         : integer range 1 to 32;  -- No. of samples per converter per frame cycle
    SCR       : std_logic;              -- Scrambling enabled
    SUBCLASSV : integer range 0 to 7;   -- Device subclass version (0, 1, 2)
    RES1      : std_logic_vector(7 downto 0);  -- Reserved field 1
    RES2      : std_logic_vector(7 downto 0);  -- Reserved field 2
    X         : std_logic_vector(8 downto 0);  -- Reserved field 2
    CHKSUM    : integer range 0 to 255;
  end record link_config;

  type error_handling_config is record
    lane_alignment_realign_after            : integer range 0 to 256;  -- realign after correctly
                                        -- received X alignment
                                        -- characters (0 to disable)
    frame_alignment_realign_after           : integer range 0 to 256;  -- realign after correctly
                                        -- received X alignment
                                        -- characters (0 to disable)
    tolerate_missing_in_frame               : integer range 0 to 256;  -- How many missing errors to
                                        -- tolerate in a frame (0 to disable)
    tolerate_disparity_in_frame             : integer range 0 to 256;  -- How many disparity errors to
                                        -- tolerate in a frame (0 to disable)
    tolerate_unexpected_characters_in_frame : integer range 0 to 256;  -- How many unexpected
                                        -- characters to
                                        -- tolerate in a frame
  end record error_handling_config;

end package data_link_pkg;
