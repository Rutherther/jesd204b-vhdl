library ieee;
use ieee.std_logic_1164.all;

entity lmfc_counter is

  generic (
    DATA_RATE_MULT         : integer;   -- DEV_CLK_FREQ*this is the frequency
                                        -- of data rate (bit rate)
    PHASE_ADJUST           : integer;   -- How many more clock cycles to wait
                                        -- after sysref until lmfc ticks
    MULTIFRAME_RATE        : integer);

  port (
    ci_device_clk     : in  std_logic;
    ci_reset          : in  std_logic;
    ci_sysref         : in  std_logic;
    ci_enable_sync    : in  std_logic;  -- Whether to adjust to SYSREF
    co_multiframe_clk : out std_logic);

end entity lmfc_counter;

architecture a1 of lmfc_counter is
  constant COUNT_TO : integer := MULTIFRAME_RATE/(DATA_RATE_MULT/10);

  signal count : integer range 0 to COUNT_TO;
  signal prev_sysref : std_logic;
begin  -- architecture a1
  count_phase_adjust: process (ci_device_clk, ci_reset) is
  begin  -- process increase
    if ci_reset = '0' then              -- asynchronous reset (active low)
      count <= 0;
      prev_sysref <=  '0';
    elsif ci_device_clk'event and ci_device_clk = '1' then  -- rising clock edge
      count <= (count + 1) mod COUNT_TO;
      if prev_sysref = '0' and ci_sysref = '1' and ci_enable_sync = '1' then
        count <= (-PHASE_ADJUST) mod COUNT_TO;
      end if;
      prev_sysref <= ci_sysref;
    end if;
  end process count_phase_adjust;

  co_multiframe_clk <= '1' when count < COUNT_TO / 2 else '0';

end architecture a1;
