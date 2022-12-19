-------------------------------------------------------------------------------
-- Title      : octets to samples mapping
-------------------------------------------------------------------------------
-- File       : octets_to_sample.vhd
-------------------------------------------------------------------------------
-- Description: Maps octets from lanes from data link to samples.
-- In case of any error in the data, last frame will be streamed again.
-- The data from wrong frame will be dropped.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity octets_to_samples is
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
    ci_char_clk : in std_logic;         -- Character clock
    ci_frame_clk : in std_logic;        -- Frame clock
    ci_reset : in std_logic;            -- Reset (asynchronous, active low)
    di_lanes_data : in frame_character_array(0 to L-1);  -- Data from the lanes
                                        -- bits
    co_correct_data : out std_logic;    -- Whether output is correct
    do_samples_data : out samples_array(0 to M - 1, 0 to S - 1));  -- The
                                                                   -- output samples
end entity octets_to_samples;

architecture a1 of octets_to_samples is
  signal samples_data : samples_array
    (0 to M - 1, 0 to S - 1)
    (data(N - 1 downto 0), ctrl_bits(CS - 1 downto 0));
  signal prev_samples_data : samples_array
    (0 to M - 1, 0 to S - 1)
    (data(N - 1 downto 0), ctrl_bits(CS - 1 downto 0));
  signal next_samples_data : samples_array
  (0 to M - 1, 0 to S - 1)
    (data(N - 1 downto 0), ctrl_bits(CS - 1 downto 0));

  signal reg_all_user_data : std_logic;  -- if '0', set correct_data to '0'.
  signal next_correct_data : std_logic;  -- if '0', set correct_data to '0'.
  signal reg_error         : std_logic;  -- if err, repeat last samples.
  signal new_frame         : std_logic;  -- Whether current frame is new frame

  signal reg_buffered_data : std_logic_vector(L*F*8-1 downto 0) := (others => '0');
  signal current_buffered_data : std_logic_vector(L*F*8-1 downto 0) := (others => '0');
  signal buffered_data : std_logic_vector(L*F*8-1 downto 0) := (others => '0');

begin  -- architecture a
  set_data: process (ci_char_clk, ci_reset) is
  begin  -- process set_data
    if ci_reset = '0' then              -- asynchronous reset (active low)
      co_correct_data <= '0';
      reg_all_user_data <= '1';
      reg_error <= '0';
      reg_buffered_data <= (others => '0');
      next_correct_data <= '0';
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      if di_lanes_data(0).octet_index = 0 then
        reg_all_user_data <= '1';
      end if;
      do_samples_data <= next_samples_data;
      co_correct_data <= next_correct_data;
      if new_frame = '1' then
        if reg_error = '1' then
          next_samples_data <= prev_samples_data;
        else
          next_samples_data <= samples_data;
          prev_samples_data <= samples_data;
        end if;

        reg_buffered_data <= (others => '0');
        next_correct_data <= reg_all_user_data;
        reg_all_user_data <= '1';
        reg_error <= '0';
      else
        for i in 0 to L-1 loop
          reg_buffered_data(L*F*8 - 1 - i*F*8 - 8*di_lanes_data(i).octet_index downto L*F*8 - 1 - i*F*8 - 8*di_lanes_data(i).octet_index - 7) <= di_lanes_data(i).d8b;

          if di_lanes_data(i).user_data = '0' or di_lanes_data(i).disparity_error = '1' or di_lanes_data(i).missing_error = '1' then
            reg_all_user_data <= '0';
          end if;
        end loop;  -- i
      end if;
    end if;
  end process set_data;

  new_frame <= '1' when di_lanes_data(0).octet_index = F - 1 else '0';

  last_octet_data: for i in 0 to L-1 generate
    current_buffered_data(L*F*8 - 1 - i*F*8 - (F - 1)*8 downto L*F*8 - 1 - i*F*8 - (F - 1)*8 - 7) <= di_lanes_data(i).d8b;
  end generate last_octet_data;

  buffered_data <= current_buffered_data or reg_buffered_data;

  -- for one or multiple lanes if CF = 0
  -- (no control words)
  -- (control chars are right after sample)
  multi_lane_no_cf: if CF = 0 generate
    converters: for ci in 0 to M - 1 generate
      samples: for si in 0 to S - 1 generate
        samples_data(ci, si).data <= buffered_data(L*F*8 - 1 - ci*Nn*S - si*Nn downto L*F*8 - 1 - ci*Nn*S - si*Nn - N + 1);

        control_bits: if CS > 0 generate
          samples_data(ci, si).ctrl_bits <= buffered_data(L*F*8 - 1 - ci*Nn*S - si*Nn - N downto L*F*8 - 1 - ci*Nn*S - si*Nn - N - CS + 1);
        end generate control_bits;
      end generate samples;
    end generate converters;
  end generate multi_lane_no_cf;

  -- for one or mutliple lanes if CF != 0
  -- (control words are present)
  multi_lane_cf: if CF > 0 generate
    cf_groups: for cfi in 0 to CF-1 generate
      converters: for ci in 0 to M/CF-1 generate
        samples: for si in 0 to S - 1 generate
          samples_data(ci + cfi*M/CF, si).data <= buffered_data(L*F*8 - 1 - cfi*F*8*L/CF - ci*Nn*S - si*Nn downto L*F*8 - 1 - cfi*F*8*L/CF - ci*Nn*S - si*Nn - N + 1);

          control_bits: if CS > 0 generate
            samples_data(ci + cfi*M/CF, si).ctrl_bits <= buffered_data(L*F*8 - 1 - cfi*F*8*L/CF - (M/CF)*S*Nn - ci*S*CS - si*CS downto L*F*8 - 1 - cfi*F*8*L/CF - (M/CF)*Nn*S - ci*S*CS - si*CS - CS + 1);
          end generate control_bits;
        end generate samples;
      end generate converters;
    end generate cf_groups;
  end generate multi_lane_cf;
end architecture a1;
