library ieee;
use ieee.std_logic_1164.all;

entity synced_combination is

  generic (
    SUBCLASSV : integer := 0;
    N : integer := 1;
    INVERSE : std_logic := '0');
  port (
    ci_frame_clk : in std_logic;
    ci_multiframe_clk : in std_logic;
    ci_reset : in std_logic;
    ci_lmfc_aligned : in std_logic;
    ci_synced_array : std_logic_vector(N-1 downto 0);
    co_nsynced : out std_logic);

end entity synced_combination;

architecture a1 of synced_combination is
  constant all_ones : std_logic_vector(N - 1 downto 0) := (others => '1');
  constant all_zeros : std_logic_vector(N - 1 downto 0) := (others => '0');

  signal nsynced : std_logic;
begin  -- architecture a1
  gen_nsynced: if INVERSE = '0' generate
    nsynced <= '0' when ci_synced_array = all_ones else '1';
  end generate gen_nsynced;
  gen_nsynced_inverse: if INVERSE = '1' generate
    nsynced <= '0' when ci_synced_array = all_zeros else '1';
  end generate gen_nsynced_inverse;

  nsynced_subclass_0: if SUBCLASSV = 0 generate
    set_nsynced: process (ci_frame_clk, ci_reset) is
    begin  -- process set_nsynced
      if ci_reset = '0' then              -- asynchronous reset (active low)
        co_nsynced <= '1';
      elsif ci_frame_clk'event and ci_frame_clk = '1' then  -- rising clock edge
        co_nsynced <= nsynced;
      end if;
    end process set_nsynced;
  end generate nsynced_subclass_0;

  nsynced_subclass_1: if SUBCLASSV = 1 generate
    set_nsynced: process (ci_multiframe_clk, ci_reset) is
    begin  -- process set_nsynced
      if ci_reset = '0' then              -- asynchronous reset (active low)
        co_nsynced <= '1';
      elsif ci_multiframe_clk'event and ci_multiframe_clk = '1' then  -- rising clock edge
        co_nsynced <= '1';
        if nsynced = '0' and ci_lmfc_aligned = '1' then
          co_nsynced <= '0';
        end if;
      end if;
    end process set_nsynced;
  end generate nsynced_subclass_1;

end architecture a1;
