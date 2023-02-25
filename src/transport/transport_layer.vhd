-------------------------------------------------------------------------------
-- Title      : transport layer
-------------------------------------------------------------------------------
-- File       : transport_layer.vhd
-------------------------------------------------------------------------------
-- Description: Takes aligned frame characters from multiple lanes
-- Outputs samples from one frame by converter.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity transport_layer is
  generic (
    CS : integer := 1;                  -- Number of control bits per sample
    M  : integer := 1;                  -- Number of converters
    S  : integer := 1;                  -- Number of samples
    L  : integer := 1;                  -- Number of lanes
    F  : integer := 2;                  -- Number of octets in a frame
    CF : integer := 0;                  -- Number of control words
    N  : integer := 12;                 -- Size of a sample
    Nn : integer := 16);                -- Size of a word (sample + ctrl if CF
                                        -- =0
  port (
    ci_frame_clk    : in  std_logic;    -- Frame clock
    ci_reset        : in  std_logic;    -- Reset (asynchronous, active low)
    di_lanes_data   : in  lane_character_array(0 to L-1)(F*8-1 downto 0);  -- Data from the lanes
    ci_frame_states : in  frame_state_array(0 to L-1);
    co_frame_state  : out frame_state;
    do_samples_data : out samples_array(0 to M - 1, 0 to S - 1));  -- The
                                        -- output samples
end entity transport_layer;

architecture a1 of transport_layer is
begin  -- architecture a1

  -- maps data from lanes to samples
  octets_to_samples: entity work.octets_to_samples
    generic map (
      CS => CS,
      M => M,
      S => S,
      L => L,
      F => F,
      CF => CF,
      N => N,
      Nn => Nn)
    port map (
      ci_frame_clk    => ci_frame_clk,
      ci_reset        => ci_reset,
      ci_frame_states => ci_frame_states,
      di_lanes_data   => di_lanes_data,
      co_frame_state  => co_frame_state,
      do_samples_data => do_samples_data);

end architecture a1;
