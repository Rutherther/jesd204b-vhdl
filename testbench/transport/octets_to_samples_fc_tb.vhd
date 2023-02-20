library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;
use work.testing_functions.all;

entity octets_to_samples_fc_tb is
end entity octets_to_samples_fc_tb;

architecture a1 of octets_to_samples_fc_tb is
  constant CONTROL_SIZE : integer := 1;  -- Size in bits of the control bits
  constant M            : integer := 4;  -- Count of converters
  constant S            : integer := 1;  -- Count of samples
  constant L            : integer := 1;  -- Count of lanes
  constant F            : integer := 3;  -- Count of octets in a frame per lane
  constant CF           : integer := 1;  -- Count of control word bits
  constant N            : integer := 4;  -- Sample size
  constant Nn           : integer := 4;
  constant CLK_PERIOD   : time    := 5 ns;

  constant DUMMY_S : sample := ("0000", "0");
  type test_vector is record
    di_lanes_data : lane_character_array (0 to L - 1) (F*8-1 downto 0);
    ci_frame_states : frame_state_array (0 to L - 1);
    expected_result : integer;
  end record test_vector;

  type result_vector is record
    do_samples_data : samples_array (0 to M - 1, 0 to S - 1)(data(M - 1 downto 0), ctrl_bits(CONTROL_SIZE - 1 downto 0));
    co_frame_state : frame_state;
  end record result_vector;

  constant dummy_frame_state : frame_state := ('0', '0', '0', '0', '0', '0', '0', '0');

  type test_vector_array is array (natural range<>) of test_vector;
  constant test_vectors : test_vector_array :=
  (
    (("000000000000000000000000", others => (others => '0')), (('0', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state), -1),
    (("101111100001010010100000", others => (others => '0')), (('1', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state), -1),
    (("000100010001000111110000", others => (others => '0')), (('1', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state),  0),
    (("111011101110111000000000", others => (others => '0')), (('1', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state),  1),
    (("000000001110000011100000", others => (others => '0')), (('1', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state),  2)
  );

  type result_vector_array is array (natural range<>) of result_vector;
  constant result_vectors : result_vector_array :=
  (
    (
      (
        (("1011", "1"), others => DUMMY_S),
        (("1110", "0"), others => DUMMY_S),
        (("0001", "1"), others => DUMMY_S),
        (("0100", "0"), others => DUMMY_S)
      ),
      ('1', '0', '0', '0', '0', '0', '0', '0')
    ),
    (
      (
        (("0001", "1"), others => DUMMY_S),
        (("0001", "1"), others => DUMMY_S),
        (("0001", "1"), others => DUMMY_S),
        (("0001", "1"), others => DUMMY_S)
      ),
      ('1', '0', '0', '0', '0', '0', '0', '0')
    ),
    (
      (
        (("1110", "0"), others => DUMMY_S),
        (("1110", "0"), others => DUMMY_S),
        (("1110", "0"), others => DUMMY_S),
        (("1110", "0"), others => DUMMY_S)
      ),
      ('1', '0', '0', '0', '0', '0', '0', '0')
    )
  );

  signal ci_frame_clk : std_logic := '0';
  signal ci_reset : std_logic := '0';

  signal di_lanes_data : lane_character_array (0 to L - 1)(F*8-1 downto 0);
  signal ci_frame_states : frame_state_array (0 to L - 1);

  signal do_samples_data : samples_array
    (0 to M - 1, 0 to S - 1)
    (data(N - 1 downto 0), ctrl_bits(CONTROL_SIZE - 1 downto 0));
  signal co_frame_state : frame_state;

  signal test_data_index : integer := 0;
begin  -- architecture a1
  uut : entity work.octets_to_samples
    generic map (
      CS => CONTROL_SIZE,
      M  => M,
      S  => S,
      L  => L,
      F  => F,
      CF => CF,
      N  => N,
      Nn => Nn)
    port map (
      ci_reset        => ci_reset,
      ci_frame_clk    => ci_frame_clk,
      di_lanes_data   => di_lanes_data,
      ci_frame_states => ci_frame_states,
      co_frame_state => co_frame_state,
      do_samples_data => do_samples_data);

  ci_frame_clk <= not ci_frame_clk after CLK_PERIOD/2;
  ci_reset <= '1' after CLK_PERIOD*2;

  test: process is
    variable test_vec : test_vector;
    variable prev_test_vec : test_vector;
    variable dummy : std_logic_vector(M - 1 downto 0);
  begin  -- process test
    wait for clk_period*2;

    for i in test_vectors'range loop
      test_data_index <= i;
      test_vec := test_vectors(i);
      di_lanes_data <= test_vec.di_lanes_data;
      ci_frame_states <= test_vec.ci_frame_states;

      if i > 0 then
        prev_test_vec := test_vectors(i - 1);

        if prev_test_vec.expected_result /= -1 then
          assert co_frame_state = result_vectors(prev_test_vec.expected_result).co_frame_state report "The frame state does not match, index: " & integer'image(prev_test_vec.expected_result) severity error;
          for ci in 0 to M - 1 loop
            for si in 0 to S - 1 loop
              assert do_samples_data(ci, si).data = result_vectors(prev_test_vec.expected_result).do_samples_data(ci, si).data report "The samples data do not match, expected: " & vec2str(result_vectors(prev_test_vec.expected_result).do_samples_data(ci, si).data) & ", got: " & vec2str(dummy) & ", index: " & integer'image(i-1) & ", ci: " & integer'image(ci) & ", si: " & integer'image(si) severity error;
              assert do_samples_data(ci, si).ctrl_bits = result_vectors(prev_test_vec.expected_result).do_samples_data(ci, si).ctrl_bits report "The samples control bits do not match, index: " & integer'image(prev_test_vec.expected_result) & ", ci: " & integer'image(ci) & ", si: " & integer'image(si) severity error;
            end loop;  -- s
          end loop;  -- c
        end if;
      end if;

      wait for clk_period;
    end loop;  -- i
    wait for 100 ms;
  end process test;

end architecture a1;
