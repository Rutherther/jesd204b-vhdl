library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity ilas_parser is
  generic (
    R_character  : std_logic_vector(7 downto 0) := "00011100";
    A_character  : std_logic_vector(7 downto 0) := "01111100";
    frames_count : integer                      := 4);

  port (
    ci_char_clk        : in  std_logic;
    ci_reset           : in  std_logic;
    ci_F               : in  integer range 0 to 256;
    ci_state           : in  link_state;
    di_char            : in  character_vector;
    do_config          : out link_config;
    co_finished        : out std_logic;
    co_error           : out std_logic;
    co_wrong_chksum    : out std_logic;
    co_unexpected_char : out std_logic);

end entity ilas_parser;

architecture a1 of ilas_parser is

begin  -- architecture a1

  

end architecture a1;
