library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity transport_layer is
  generic (
    CS : integer := 1;                  -- Number of control bits per sample
    M : integer := 1;                   -- Number of converters
    S : integer := 1;                   -- Number of samples
    L : integer := 1;                   -- Number of lanes
    F : integer := 2;                  -- Number of octets in a frame
    CF : integer := 0;                  -- Number of control words
    N : integer := 12;                  -- Size of a sample
    Nn : integer := 16);                 -- Size of a word (sample + ctrl if CF
                                         -- =0
  port (
    ci_char_clk : in std_logic;
    ci_frame_clk : in std_logic;
    ci_reset : in std_logic;
    di_lanes_data : in frame_character_array(0 to L - 1);

    co_correct_data : out std_logic;
    do_samples_data : out samples_array(0 to M - 1, 0 to S - 1));
end entity transport_layer;

architecture a1 of transport_layer is
begin  -- architecture a1

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
      ci_char_clk     => ci_char_clk,
      ci_frame_clk    => ci_frame_clk,
      ci_reset        => ci_reset,
      di_lanes_data   => di_lanes_data,
      co_correct_data => co_correct_data,
      do_samples_data => do_samples_data);

end architecture a1;
