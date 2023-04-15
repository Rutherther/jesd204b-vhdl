-------------------------------------------------------------------------------
-- Title      : transport layer
-------------------------------------------------------------------------------
-- File       : transport_layer.vhd
-------------------------------------------------------------------------------
-- Description: Takes aligned frame characters from multiple lanes
-- Outputs samples from one frame by converter.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity transport_layer is
  generic (
    CS : integer := 1;                  -- Number of control bits per sample
    M  : integer := 1;                  -- Number of converters
    S  : integer := 1;                  -- Number of samples
    L  : integer := 1;                  -- Number of lanes
    F  : integer := 2;                  -- Number of octets in a frame
    CF : integer := 0;                  -- Number of control words
    N  : integer := 12;                 -- Size of a sample
    Nn : integer := 16);                -- Size of a word (sample + ctrl if CF
                                        -- =0
  port (
    ci_frame_clk    : in  std_logic;    -- Frame clock
    ci_reset        : in  std_logic;    -- Reset (asynchronous, active low)
    di_lanes_data   : in  lane_character_array(0 to L-1)(F*8-1 downto 0);  -- Data from the lanes
    ci_frame_states : in  frame_state_array(0 to L-1);
    co_frame_state  : out frame_state;
    do_samples      : out samples_array(0 to M - 1, 0 to S - 1)(N - 1 downto 0);
    do_ctrl_bits    : out ctrl_bits_array(0 to M - 1, 0 to S - 1)(CS - 1 downto 0));
end entity transport_layer;

architecture a1 of transport_layer is
  signal samples             : samples_array(0 to M - 1, 0 to S - 1)(N - 1 downto 0);
  signal prev_samples        : samples_array(0 to M - 1, 0 to S - 1)(N - 1 downto 0);
  signal next_samples        : samples_array(0 to M - 1, 0 to S - 1)(N - 1 downto 0);
  signal ctrl_bits           : ctrl_bits_array(0 to M - 1, 0 to S - 1)(CS - 1 downto 0);
  signal prev_ctrl_bits      : ctrl_bits_array(0 to M - 1, 0 to S - 1)(CS - 1 downto 0);
  signal next_ctrl_bits      : ctrl_bits_array(0 to M - 1, 0 to S - 1)(CS - 1 downto 0);
  signal reg_error           : std_logic;  -- if err, repeat last samples.
  signal current_frame_state : frame_state;

  signal reg_buffered_data : std_logic_vector(L*F*8-1 downto 0) := (others => '0');
  signal reg_state_user_data : std_logic_vector(L-1 downto 0);
  signal reg_state_invalid_character : std_logic_vector(L-1 downto 0);
  signal reg_state_not_enough_data : std_logic_vector(L-1 downto 0);
  signal reg_state_ring_buffer_overflow : std_logic_vector(L-1 downto 0);
  signal reg_state_disparity_error : std_logic_vector(L-1 downto 0);
  signal reg_state_not_in_table_error : std_logic_vector(L-1 downto 0);
  signal reg_state_wrong_alignment : std_logic_vector(L-1 downto 0);
  signal reg_state_last_frame_repeated : std_logic_vector(L-1 downto 0);

  signal any_error : std_logic := '0';

  constant all_ones : std_logic_vector(L-1 downto 0) := (others => '1');
  constant all_zeros : std_logic_vector(L-1 downto 0) := (others => '0');
begin  -- architecture a1
  set_data: process (ci_frame_clk, ci_reset) is
  begin  -- process set_data
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_error <= '0';
      reg_buffered_data <= (others => '0');
    elsif ci_frame_clk'event and ci_frame_clk = '1' then  -- rising clock edge
      do_samples <= next_samples;
      do_ctrl_bits <= next_ctrl_bits;
      co_frame_state <= current_frame_state;

      if any_error = '0' then
        prev_samples <= samples;
        prev_ctrl_bits <= ctrl_bits;
      end if;

      for i in 0 to L-1 loop
        reg_buffered_data(L*F*8 - 1 - i*F*8 downto L*F*8 - (i + 1)*F*8) <= di_lanes_data(i);
        reg_state_user_data(i) <= ci_frame_states(i).user_data;
        reg_state_invalid_character(i) <= ci_frame_states(i).invalid_characters;
        reg_state_not_enough_data(i) <= ci_frame_states(i).not_enough_data;
        reg_state_ring_buffer_overflow(i) <= ci_frame_states(i).ring_buffer_overflow;
        reg_state_disparity_error(i) <= ci_frame_states(i).disparity_error;
        reg_state_not_in_table_error(i) <= ci_frame_states(i).not_in_table_error;
        reg_state_wrong_alignment(i) <= ci_frame_states(i).wrong_alignment;
        reg_state_last_frame_repeated(i) <= ci_frame_states(i).last_frame_repeated;
      end loop;  -- i
    end if;
  end process set_data;

  -- set output error in case any lane has an error
  current_frame_state.user_data <= '1' when reg_state_user_data = all_ones else '0';
  current_frame_state.invalid_characters <= '0' when reg_state_invalid_character = all_zeros else '1';
  current_frame_state.not_enough_data <= '0' when reg_state_not_enough_data = all_zeros else '1';
  current_frame_state.ring_buffer_overflow <= '0' when reg_state_ring_buffer_overflow = all_zeros else '1';
  current_frame_state.disparity_error <= '0' when reg_state_disparity_error = all_zeros else '1';
  current_frame_state.not_in_table_error <= '0' when reg_state_not_in_table_error = all_zeros else '1';
  current_frame_state.wrong_alignment <= '0' when reg_state_wrong_alignment = all_zeros else '1';
  current_frame_state.last_frame_repeated <= '1' when any_error = '1' else '0';

  any_error <= '1' when current_frame_state.invalid_characters = '1' or
               current_frame_state.not_enough_data = '1' or
               current_frame_state.ring_buffer_overflow = '1' or
               current_frame_state.disparity_error = '1' or
               current_frame_state.not_in_table_error = '1' or
               current_frame_state.wrong_alignment = '1' else '0';
  next_samples <= samples when any_error = '0' else prev_samples;
  next_ctrl_bits <= ctrl_bits when any_error = '0' else prev_ctrl_bits;

  -- for one or multiple lanes if CF = 0
  -- (no control words)
  -- (control chars are right after sample)
  multi_lane_no_cf: if CF = 0 generate
    converters: for ci in 0 to M - 1 generate
      assign_samples: for si in 0 to S - 1 generate
        samples(ci, si) <= reg_buffered_data(L*F*8 - 1 - ci*Nn*S - si*Nn downto L*F*8 - 1 - ci*Nn*S - si*Nn - N + 1);

        control_bits: if CS > 0 generate
          ctrl_bits(ci, si) <= reg_buffered_data(L*F*8 - 1 - ci*Nn*S - si*Nn - N downto L*F*8 - 1 - ci*Nn*S - si*Nn - N - CS + 1);
        end generate control_bits;
      end generate assign_samples;
    end generate converters;
  end generate multi_lane_no_cf;

  -- for one or mutliple lanes if CF != 0
  -- (control words are present)
  multi_lane_cf: if CF > 0 generate
    cf_groups: for cfi in 0 to CF-1 generate
      converters: for ci in 0 to M/CF-1 generate
        assign_samples: for si in 0 to S - 1 generate
          samples(ci + cfi*M/CF, si) <= reg_buffered_data(L*F*8 - 1 - cfi*F*8*L/CF - ci*Nn*S - si*Nn downto L*F*8 - 1 - cfi*F*8*L/CF - ci*Nn*S - si*Nn - N + 1);

          control_bits: if CS > 0 generate
            ctrl_bits(ci + cfi*M/CF, si) <= reg_buffered_data(L*F*8 - 1 - cfi*F*8*L/CF - (M/CF)*S*Nn - ci*S*CS - si*CS downto L*F*8 - 1 - cfi*F*8*L/CF - (M/CF)*Nn*S - ci*S*CS - si*CS - CS + 1);
          end generate control_bits;
        end generate assign_samples;
      end generate converters;
    end generate cf_groups;
  end generate multi_lane_cf;

end architecture a1;
