library ieee;
use ieee.std_logic_1164.all;

entity char_alignment_tb is
end entity char_alignment_tb;

architecture a1 of char_alignment_tb is
  constant clk_period : time := 1 ns;    -- The clock period
  constant buffer_positions : integer := 2;

  signal clk : std_logic := '0';        -- The clock
  signal reset : std_logic := '0';      -- The reset

  signal synced : std_logic := '0';     -- Whether synced
  signal data_10b : std_logic_vector(9 downto 0) := (others => '0');  -- The 10b data input

  signal buffer_position : integer := 0;
  signal data_10b_buffer : std_logic_vector(10*2-1 downto 0) := "00111100110011110011";  -- The 10b data input
begin  -- architecture a1
  uut: entity work.char_alignment
    port map (
      ci_char_clk => clk,
      ci_reset    => reset,
      di_10b      => data_10b,
      ci_synced   => synced);

  data_10b <= data_10b_buffer(buffer_position*10+9 downto buffer_position*10);
  buffer_position <= (buffer_position + 1) mod buffer_positions after clk_period;
  clk <= not clk after clk_period/2;
  reset <= '1' after clk_period*2;
end architecture a1;
