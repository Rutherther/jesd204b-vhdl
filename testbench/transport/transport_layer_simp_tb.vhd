library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;
use work.testing_functions.all;

entity transport_layer_simp_tb is
end entity transport_layer_simp_tb;

architecture a1 of transport_layer_simp_tb is
  constant CONTROL_SIZE : integer := 1;  -- Size in bits of the control bits
  constant M            : integer := 4;  -- Count of converters
  constant S            : integer := 1;  -- Count of samples
  constant L            : integer := 1;  -- Count of lanes
  constant F            : integer := 4;  -- Count of octets in a frame per lane
  constant CF            : integer := 0;  -- Count of control words
  constant N : integer := 4;            -- Sample size
  constant Nn : integer := 8;
  constant CLK_PERIOD : time := 1 ns;

  constant DUMMY_S : std_logic_vector(N - 1 downto 0)            := "0000";
  constant DUMMY_C : std_logic_vector(CONTROL_SIZE - 1 downto 0) := "0";
  type test_vector is record
    di_lanes_data   : lane_character_array (0 to L - 1) (F*8-1 downto 0);
    ci_frame_states : frame_state_array (0 to L - 1);
    expected_result : integer;
  end record test_vector;

  type result_vector is record
    do_samples_data   : samples_array (0 to M - 1, 0 to S - 1);
    do_ctrl_bits_data : ctrl_bits_array (0 to M - 1, 0 to S - 1);
    co_frame_state    : frame_state;
  end record result_vector;

  constant dummy_frame_state : frame_state := ('0', '0', '0', '0', '0', '0', '0', '0');

  type test_vector_array is array (natural range<>) of test_vector;
  constant test_vectors : test_vector_array :=
  (
    (("00000000000000000000000000000000", others => (others => '0')), (('0', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state), -1),
    (("10111000111000000001100001000000", others => (others => '0')), (('1', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state), -1),
    (("00011000000110000001100000011000", others => (others => '0')), (('1', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state), 0),
    (("11100000111000001110000011100000", others => (others => '0')), (('1', '0', '0', '0', '0', '0', '0', '0'), others => dummy_frame_state), 1),
    (("00000000000000000000000000000000", others => (others => '0')), (('1', '1', '0', '0', '0', '1', '0', '0'), others => dummy_frame_state), 2),
    (("11100000111000001110000011100000", others => (others => '0')), (('1', '1', '0', '0', '0', '1', '0', '0'), others => dummy_frame_state), 3),
    (("00000000000000000000000000000000", others => (others => '0')), (('1', '1', '0', '0', '0', '1', '0', '0'), others => dummy_frame_state), -1)
  );

  type result_vector_array is array (natural range<>) of result_vector;
  constant result_vectors : result_vector_array :=
  (
    (
      (
        ("1011", others => DUMMY_S),
        ("1110", others => DUMMY_S),
        ("0001", others => DUMMY_S),
        ("0100", others => DUMMY_S)
      ),
      (
        ("1", others => DUMMY_C),
        ("0", others => DUMMY_C),
        ("1", others => DUMMY_C),
        ("0", others => DUMMY_C)
      ),
      ('1', '0', '0', '0', '0', '0', '0', '0')
    ),
    (
      (
        ("0001", others => DUMMY_S),
        ("0001", others => DUMMY_S),
        ("0001", others => DUMMY_S),
        ("0001", others => DUMMY_S)
      ),
      (
        ("1", others => DUMMY_C),
        ("1", others => DUMMY_C),
        ("1", others => DUMMY_C),
        ("1", others => DUMMY_C)
      ),
      ('1', '0', '0', '0', '0', '0', '0', '0')
    ),
    (
      (
        ("1110", others => DUMMY_S),
        ("1110", others => DUMMY_S),
        ("1110", others => DUMMY_S),
        ("1110", others => DUMMY_S)
      ),
      (
        ("0", others => DUMMY_C),
        ("0", others => DUMMY_C),
        ("0", others => DUMMY_C),
        ("0", others => DUMMY_C)
      ),
      ('1', '0', '0', '0', '0', '0', '0', '0')
    ),
    (
      (
        ("1110", others => DUMMY_S),
        ("1110", others => DUMMY_S),
        ("1110", others => DUMMY_S),
        ("1110", others => DUMMY_S)
      ),
      (
        ("0", others => DUMMY_C),
        ("0", others => DUMMY_C),
        ("0", others => DUMMY_C),
        ("0", others => DUMMY_C)
      ),
      ('1', '1', '0', '0', '0', '1', '0', '1')
    )
  );

  signal ci_frame_clk : std_logic := '0';
  signal ci_reset : std_logic := '0';

  signal di_lanes_data : lane_character_array (0 to L - 1)(F*8-1 downto 0);
  signal ci_frame_states : frame_state_array (0 to L - 1);

  signal do_samples     : samples_array(0 to M - 1, 0 to S - 1)(N - 1 downto 0);
  signal do_ctrl_bits   : ctrl_bits_array(0 to M - 1, 0 to S - 1)(CONTROL_SIZE - 1 downto 0);
  signal co_frame_state : frame_state;

  signal test_data_index : integer := 0;
begin  -- architecture a1
  uut : entity work.transport_layer
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
      co_frame_state  => co_frame_state,
      do_ctrl_bits    => do_ctrl_bits,
      do_samples      => do_samples);

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
              assert do_samples(ci, si) = result_vectors(prev_test_vec.expected_result).do_samples_data(ci, si) report "The samples data do not match, expected: " & vec2str(result_vectors(prev_test_vec.expected_result).do_samples_data(ci, si)) & ", got: " & vec2str(dummy) & ", index: " & integer'image(i-1) & ", ci: " & integer'image(ci) & ", si: " & integer'image(si) severity error;
              assert do_ctrl_bits(ci, si) = result_vectors(prev_test_vec.expected_result).do_ctrl_bits_data(ci, si) report "The samples control bits do not match, index: " & integer'image(prev_test_vec.expected_result) & ", ci: " & integer'image(ci) & ", si: " & integer'image(si) severity error;
            end loop;  -- s
          end loop;  -- c
        end if;
      end if;

      wait for clk_period;
    end loop;  -- i
    wait for 100 ms;
  end process test;

end architecture a1;
