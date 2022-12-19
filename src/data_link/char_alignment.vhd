-------------------------------------------------------------------------------
-- Title      : Synchronize with character start
-- Project    : JESD204B Receiver
-------------------------------------------------------------------------------
-- File       : char_alignment.vhd
-- Description: Tries to align the beginning of the character from 8b/10b encoding.
-- Accepting 10 bits, outputting 10 bits. Will try to sync to /K/ character when
-- ci_synced is false.
-------------------------------------------------------------------------------

-- input d_in[9:0], ci_synced
-- output co_aligned, d_out[9:0]

library ieee;
use ieee.std_logic_1164.all;

entity char_alignment is

  generic (
    sync_char : std_logic_vector(9 downto 0) := "0011111010"  -- The character used for synchronization (positive RD)
    );
  port (
    ci_char_clk: in std_logic;          -- The character clock
    ci_reset   : in std_logic;          -- The reset, active high.
    di_10b     : in  std_logic_vector(9 downto 0);  -- The 8b/10b encoded input data from physical layer
    ci_synced  : in  std_logic;  -- Whether the receiver is currently synchronized
    do_10b     : out std_logic_vector(9 downto 0);  -- The 8b/10b encoded data aligned with a character (if co_aligned is true, otherwise unknown)
    co_aligned : out std_logic);  -- Whether the output is currently aligned

end entity char_alignment;

architecture a1 of char_alignment is
  signal next_cache_10b : std_logic_vector(19 downto 0) := (others => '0');  -- The next value of cache_10b
  signal next_do_10b : std_logic_vector(9 downto 0) := (others => '0');  -- The next value of do_10b
  signal next_co_aligned : std_logic := '0';

  signal reg_found_sync_char : std_logic := '0';  -- Whether sync char was found
  signal reg_cache_10b : std_logic_vector(19 downto 0) := (others => '0');  -- The cache of 10b characters.
  signal reg_do_10b : std_logic_vector(9 downto 0) := (others => '0');
  signal reg_alignment_index : integer range 0 to 16 := 0;  -- Where the character starts in the cache, if aligned.
  signal reg_last_synced : std_logic := '0';  -- The last value of ci_synced
  signal reg_co_aligned : std_logic := '0';  -- Whether aligned
begin  -- architecture a1

  -- purpose: Set next signals
  -- type   : combinational
  -- inputs : clk, reset
  -- outputs: alignment_index, cache_10b, do_10b, co_aligned
  set_next: process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then
      reg_last_synced <= '0';
      reg_co_aligned <= '0';
      reg_cache_10b <= (others => '0');
      reg_do_10b <= (others => '0');
    elsif rising_edge(ci_char_clk) then
      reg_last_synced <= ci_synced;
      reg_co_aligned <= next_co_aligned;
      reg_cache_10b <= next_cache_10b;
      reg_do_10b <= next_do_10b;
    end if;
  end process set_next;

  -- purpose: Tries to find the sync character if synced is false
  -- type   : sequential
  -- inputs : ci_char_clk, ci_reset, di_10b, ci_synced
  -- outputs: reg_found_sync_char, reg_alignment_index
  find_sync_char: process (ci_char_clk, ci_reset) is
  begin  -- process find_sync_char
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_alignment_index <= 0;
      reg_found_sync_char <= '0';
    elsif rising_edge(ci_char_clk) then  -- rising clock edge
      if reg_found_sync_char = '1' then
        reg_found_sync_char <= '0';
      end if;
      -- Try to find /K/ character again and again until ci_synced is one (that
      -- will be set by 8b10b_decoder)
      if ci_synced = '0' then
        -- Try to find /K/ (sync_char) in either RD (either sync_char or not sync_char).
        for i in 0 to 9 loop
          if reg_cache_10b(i+9 downto i) = sync_char or reg_cache_10b(i+9 downto i) = not sync_char then
            reg_found_sync_char <= '1';
            reg_alignment_index <= i;
          end if;
        end loop;  -- i
      end if;
    end if;
  end process find_sync_char;

  co_aligned <= reg_co_aligned;
  do_10b <= reg_do_10b;

  next_co_aligned <= (reg_found_sync_char or reg_co_aligned) and not (reg_last_synced and not ci_synced);
  next_do_10b(9 downto 0) <= reg_cache_10b(reg_alignment_index+9 downto reg_alignment_index);
  next_cache_10b(19 downto 0) <= di_10b(9 downto 0) & reg_cache_10b(19 downto 10);
end architecture a1;
