library ieee;
use ieee.std_logic_1164.all;

entity lmfc_generation is
  generic (
    MULTIFRAME_RATE : integer;
    DATA_RATE_MULT  : integer);
  port (
    ci_device_clk     : in  std_logic;
    ci_reset          : in  std_logic;
    ci_sysref         : in  std_logic;
    ci_nsynced        : in  std_logic;
    co_multiframe_clk : out std_logic;
    co_lmfc_aligned   : out std_logic);
end entity lmfc_generation;

architecture a1 of lmfc_generation is
  signal prev_nsynced : std_logic;
  signal reg_lmfc_aligned : std_logic;

  signal multiframe_clk : std_logic;
  signal multiframe_aligned : std_logic;
  signal multiframe_enable_sync : std_logic;
begin  -- architecture a1
  co_lmfc_aligned <= reg_lmfc_aligned;
  co_multiframe_clk <= multiframe_clk;

  sysref_alignment: process (ci_device_clk, ci_reset) is
  begin  -- process sysref_alignment
    if ci_reset = '0' then            -- asynchronous reset (active low)
      reg_lmfc_aligned <= '0';
      multiframe_enable_sync <= '0';
      prev_nsynced <= '1';
    elsif ci_device_clk'event and ci_device_clk = '1' then  -- rising clock edge
        prev_nsynced <= ci_nsynced;
      if multiframe_enable_sync = '0' and reg_lmfc_aligned = '0' then
        multiframe_enable_sync <= '1';
      elsif reg_lmfc_aligned = '0' and multiframe_aligned = '1' then
        reg_lmfc_aligned <= '1';
        multiframe_enable_sync <= '0';
      elsif prev_nsynced = '0' and ci_nsynced = '1' then
        reg_lmfc_aligned <= '0';
        multiframe_enable_sync <= '1';
      end if;
    end if;
  end process sysref_alignment;

  multiframe_gen: entity work.lmfc_counter
  generic map (
    DATA_RATE_MULT  => DATA_RATE_MULT,
    PHASE_ADJUST    => 0,
    MULTIFRAME_RATE => MULTIFRAME_RATE)
  port map (
    ci_device_clk     => ci_device_clk,
    ci_reset          => ci_reset,
    ci_sysref         => ci_sysref,
    ci_enable_sync    => multiframe_enable_sync,
    co_aligned        => multiframe_aligned,
    co_multiframe_clk => multiframe_clk);

end architecture a1;
