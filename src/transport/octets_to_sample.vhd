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
    F : integer := 16;                  -- Number of octets in a frame
    CF : integer := 1;                  -- Number of control words
    N : integer := 12;                  -- Size of a sample
    Nn : integer := 32);                 -- Size of a word (sample + ctrl if CF
                                        -- =0
  port (
    ci_char_clk : in std_logic;
    ci_frame_clk : in std_logic;
    ci_reset : in std_logic;
    di_lanes_data : in frame_character_array(0 to L-1);
                                        -- bits
    co_correct_data : out std_logic;
    do_samples_data : out samples_array(0 to M - 1, 0 to S - 1));
end entity octets_to_samples;

architecture a1 of octets_to_samples is
  constant CF_GROUP_COUNT : integer := CF;
  constant CF_GROUP_LANES_COUNT : integer := L/CF;
  constant CF_GROUP_CONVERTERS_COUNT : integer := M/CF;

  signal samples_data : samples_array
    (M - 1 downto 0, S - 1 downto 0)
    (data(N - 1 downto 0), ctrl_bits(CS - 1 downto 0));
  signal prev_samples_data : samples_array
    (M - 1 downto 0, S - 1 downto 0)
    (data(N - 1 downto 0), ctrl_bits(CS - 1 downto 0));

  signal reg_all_user_data : std_logic;  -- if '0', set correct_data to '0'.
  signal reg_error         : std_logic;  -- if err, repeat last samples.
  signal new_frame         : std_logic;  -- Whether current frame is new frame

  signal reg_buffered_data : std_logic_vector(L*F-1 downto 0) := (others => '0');

begin  -- architecture a
  set_data: process (ci_char_clk, ci_reset) is
  begin  -- process set_data
    if ci_reset = '0' then              -- asynchronous reset (active low)
      co_correct_data <= '0';
      reg_all_user_data <= '1';
      reg_error <= '0';
      reg_buffered_data <= (others => '0');
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      if new_frame = '1' then
        if reg_error = '1' then
          do_samples_data <= prev_samples_data;
        else
          do_samples_data <= samples_data;
          prev_samples_data <= samples_data;
        end if;

        reg_buffered_data <= (others => '0');
        co_correct_data <= reg_all_user_data;
        reg_all_user_data <= '1';
        reg_error <= '0';
      end if;

      for i in 0 to L-1 loop
        reg_buffered_data(L*F - 1 - i*F - 8*di_lanes_data(i).octet_index downto L*F - 1 - i*F - 8*di_lanes_data(i).octet_index - 7) <= di_lanes_data(i).d8b;

        if di_lanes_data(i).user_data = '0' or di_lanes_data(i).disparity_error = '1' or di_lanes_data(i).missing_error = '1' then
          reg_all_user_data <= '0';
        end if;
      end loop;  -- i
    end if;
  end process set_data;

  new_frame <= '1' when di_lanes_data(0).octet_index = 0 else '0';

  last_octet_data: for i in 0 to L-1 generate
    reg_buffered_data(L*F - 1 - i*F - (F - 1)*8 downto L*F - 1 - i*F - (F - 1)*8 - 7) <= di_lanes_data(L - 1).d8b;
  end generate last_octet_data;

  multi_lane_no_cf: if CF = 0 generate
    converters: for ci in 0 to M - 1 generate
      samples: for si in 0 to S - 1 generate
        samples_data(ci, si).data <= reg_buffered_data(L*F - 1 - ci*Nn*S - si*Nn downto L*F - 1 - ci*Nn*S - si*Nn - N + 1);

        control_bits: if CS > 0 generate
          samples_data(ci, si).ctrl_bits <= reg_buffered_data(L*F - 1 - ci*Nn*S - si*Nn - si*N downto L*F - 1 - ci*Nn*S - si*Nn - si*N - CS + 1);
        end generate control_bits;
      end generate samples;
    end generate converters;
  end generate multi_lane_no_cf;

  multi_lane_cf: if CF > 0 generate
    cf_groups: for cfi in 0 to CF_GROUP_COUNT-1 generate
      converters: for ci in 0 to CF_GROUP_CONVERTERS_COUNT-1 generate
        samples: for si in 0 to S - 1 generate
          samples_data(ci + cfi*CF_GROUP_CONVERTERS_COUNT, si).data <= reg_buffered_data(L*F - 1 - F*CF_GROUP_LANES_COUNT - ci*Nn*S - si*Nn downto L*F - 1 - F*CF_GROUP_LANES_COUNT - ci*Nn*S - si*Nn - N + 1);

          control_bits: if CS > 0 generate
            samples_data(ci + cfi*CF_GROUP_CONVERTERS_COUNT, si).ctrl_bits <= reg_buffered_data(L*F - 1 - F*CF_GROUP_LANES_COUNT - (M-1)*Nn*S - ci*S*CS - si*CS downto L*F - 1 - F*CF_GROUP_LANES_COUNT - (M-1)*Nn*S - ci*S*CS - si*CS - CS + 1);
          end generate control_bits;
        end generate samples;
      end generate converters;
    end generate cf_groups;
  end generate multi_lane_cf;
end architecture a1;
