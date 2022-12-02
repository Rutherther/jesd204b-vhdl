library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity transport_layer is
  generic (
    M : integer := 1;                   -- Count of converters
    S : integer := 1;                   -- Count of samples
    L : integer := 1);                  -- Count of lanes
  port (
    ci_char_clk : in std_logic;
    ci_frame_clk : in std_logic;
    ci_reset : in std_logic;
    di_lanes_data : in frame_character_array(L - 1 downto 0);

    ci_N : in integer range 0 to 256;   -- Number of bits per sample
    ci_Nn : in integer range 0 to 256;  -- Number of bits per sample + control
                                        -- bits
    co_correct_data : out std_logic;
    do_samples_data : out samples_array(M - 1 downto 0, S - 1 downto 0));
end entity transport_layer;

architecture a1 of transport_layer is

begin  -- architecture a1

  octets_to_samples: entity work.octets_to_samples
    generic map (
      M => M,
      S => S,
      L => L)
    port map (
      ci_char_clk     => ci_char_clk,
      ci_frame_clk    => ci_frame_clk,
      di_lanes_data   => di_lanes_data,
      ci_N            => ci_N,
      ci_Nn           => ci_Nn,
      co_correct_data => co_correct_data,
      do_samples_data => do_samples_data);

end architecture a1;
