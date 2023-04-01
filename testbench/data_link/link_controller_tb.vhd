library ieee;
use ieee.std_logic_1164.all;
use work.testing_functions.all;
use work.data_link_pkg.all;

entity link_controller_tb is
end entity link_controller_tb;

architecture a1 of link_controller_tb is
  type test_vector is record
    di_char                   : character_vector;
    ci_resync                 : std_logic;
    ci_lane_alignment_error   : std_logic;
    ci_lane_alignment_aligned : std_logic;
    ci_lane_alignment_ready   : std_logic;

    ci_frame_alignment_error   : std_logic;
    ci_frame_alignment_aligned : std_logic;

    expected_synced              : std_logic;
    expected_state               : link_state;
    expected_uncorrectable_error : std_logic;
    expected_error               : std_logic;
    expected_config_index        : integer;
  end record test_vector;

  type config_array is array (natural range<>) of link_config;
  constant config_vectors : config_array :=
  (
    (
      DID => 170,
      ADJCNT =>  7,
      BID => 14,
      ADJDIR => '1',
      PHADJ => '1',
      LID => 10,
      SCR => '1',
      L => 31,
      F => 205,
      K => 32,
      M => 52,
      CS => 2,
      N => 4,
      SUBCLASSV => 1,
      Nn => 30,
      JESDV => 0,
      S => 1,
      HD => '0',
      CF =>  0,
      RES1 => "11111111",
      RES2 => "00000000",
      X => "010010000",
      CHKSUM => 48
    ),
    (
      DID => 170,
      ADJCNT =>  7,
      BID => 14,
      ADJDIR => '1',
      PHADJ => '1',
      LID => 10,
      SCR => '1',
      L => 31,
      F => 205,
      K => 32,
      M => 52,
      CS => 2,
      N => 4,
      SUBCLASSV => 1,
      Nn => 30,
      JESDV => 0,
      S => 1,
      HD => '0',
      CF =>  0,
      RES1 => "11111111",
      RES2 => "11111111",
      X => "010010000",
      CHKSUM => 48
    )
  );

  type test_vector_array is array (natural range<>) of test_vector;
  constant test_vectors : test_vector_array :=
  (
   --kout der  noter char      userd      resync ler lal   lre  fer  fal expsyn expstexpuner exper expconf
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '1', CGS,  '0', '0', -1),
    (('1', '0', '0', "00011100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1), --R
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('1', '0', '0', "01111100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1), --A
    (('1', '0', '0', "00011100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1), --R
    (('1', '0', '0', "10011100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "10101010", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "01111110", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "01101010", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "11011110", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "11001100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "01011111", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00110011", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "10000011", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00111101", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "11111111", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('0', '0', '0', "00110000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1),
    (('1', '0', '0', "01111100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', -1), --A
    (('1', '0', '0', "00011100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0), --R
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('1', '0', '0', "01111100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0), --A
    (('1', '0', '0', "00011100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0), --R
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0),
    (('1', '0', '0', "01111100", '0'), '0', '0', '0', '0', '0', '0', '1', ILS,  '0', '0', 0), --A
    (('0', '0', '0', "01010101", '0'), '0', '0', '0', '0', '0', '0', '1', DATA, '0', '0', 0),
    (('0', '0', '0', "01010101", '0'), '0', '0', '0', '0', '0', '0', '1', DATA, '0', '0', 0),
    (('0', '0', '0', "01010101", '0'), '0', '0', '0', '0', '0', '0', '1', DATA, '0', '0', 0),
    (('0', '0', '0', "01010101", '0'), '0', '0', '0', '0', '0', '0', '1', DATA, '0', '0', 0),
    (('0', '0', '0', "01010101", '0'), '0', '0', '0', '0', '0', '0', '1', DATA, '0', '0', 0),
    (('0', '0', '1', "01010101", '0'), '0', '0', '0', '0', '0', '0', '1', DATA, '0', '1', 0),
    (('0', '0', '0', "01010101", '0'), '0', '1', '0', '0', '0', '0', '1', DATA, '0', '1', 0),
    (('0', '0', '0', "01010101", '0'), '0', '1', '0', '0', '1', '0', '1', DATA, '0', '1', 0),
    (('0', '0', '0', "01010101", '0'), '0', '0', '0', '0', '1', '0', '1', DATA, '0', '1', 0),
    (('0', '0', '0', "01010101", '0'), '1', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "01010101", '0'), '1', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "01010101", '0'), '1', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '0', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '1', CGS,  '0', '0', -1),
    (('1', '0', '0', "10111100", '0'), '0', '0', '0', '0', '0', '0', '1', CGS,  '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '1', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1),
    (('0', '0', '0', "00000000", '0'), '0', '0', '0', '0', '0', '0', '0', INIT, '0', '0', -1)
  );

  constant char_clk_period : time := 1 ns;
  constant frame_clk_period : time := char_clk_period * F;

  constant F : integer range 0 to 256 := 17;
  constant K : integer range 0 to 32 := 1;

  signal char_clk : std_logic := '0';
  signal frame_clk : std_logic := '0';
  signal reset : std_logic := '0';

  signal di_char : character_vector;
  signal do_config : link_config;

  signal ci_resync : std_logic := '0';
  signal ci_lane_alignment_error : std_logic := '0';
  signal ci_lane_alignment_aligned : std_logic := '0';
  signal ci_lane_alignment_ready : std_logic := '0';
  signal ci_frame_alignment_error : std_logic := '0';
  signal ci_frame_alignment_aligned : std_logic := '0';


  signal co_finished : std_logic;
  signal co_state : link_state;
  signal co_synced : std_logic;
  signal co_error : std_logic;
  signal co_uncorrectable_error : std_logic;

  signal test_data_index : integer := 0;

begin  -- architecture a1
  uut : entity work.link_controller
    generic map (
      F => F,
      K => K)
    port map (
      ci_frame_clk               => frame_clk,
      ci_char_clk                => char_clk,
      ci_reset                   => reset,
      ci_resync                  => ci_resync,
      ci_lane_alignment_aligned  => ci_lane_alignment_aligned,
      ci_lane_alignment_error    => ci_lane_alignment_error,
      ci_lane_alignment_ready    => ci_lane_alignment_ready,
      ci_frame_alignment_aligned => ci_frame_alignment_aligned,
      ci_frame_alignment_error   => ci_frame_alignment_error,
      di_char => di_char,
      do_config                  => do_config,
      co_synced                  => co_synced,
      co_state                   => co_state,
      co_uncorrectable_error     => co_uncorrectable_error,
      co_error                   => co_error
      );

  char_clk_gen: process is
  begin -- process clk_gen
    wait for char_clk_period/2;
	  char_clk <= not char_clk;
  end process char_clk_gen;
  frame_clk_gen: process is
  begin -- process clk_gen
    wait for frame_clk_period/2;
	  frame_clk <= not clk;
  end process frame_clk_gen;
  
  reset_gen: process is
  begin -- process reset_gen
    wait for char_clk_period*2;
    reset <= '1';
  end process reset_gen;

  test: process is
    variable test_vec : test_vector;
    variable prev_test_vec : test_vector;
  begin  -- process test
    wait for char_clk_period*2;

    for i in test_vectors'range loop
      test_data_index <= i;
      test_vec := test_vectors(i);
      di_char <= test_vec.di_char;
      ci_resync <= test_vec.ci_resync;
      ci_lane_alignment_aligned <= test_vec.ci_lane_alignment_aligned;
      ci_lane_alignment_error <= test_vec.ci_lane_alignment_error;
      ci_lane_alignment_ready <= test_vec.ci_lane_alignment_ready;
      ci_frame_alignment_aligned <= test_vec.ci_frame_alignment_aligned;
      ci_frame_alignment_error <= test_vec.ci_frame_alignment_error;

      if i > 0 then
        prev_test_vec := test_vectors(i - 1);

        if prev_test_vec.expected_config_index > -1 then
        assert do_config = config_vectors(prev_test_vec.expected_config_index) report "The config does not match. Index: " & integer'image(i-1) severity error;
        end if;

        assert co_state = prev_test_vec.expected_state report "The state does not match. Index: " & integer'image(i-1) severity error;
        assert co_synced = prev_test_vec.expected_synced report "The synced does not match. Index: " & integer'image(i-1) severity error;
        assert co_error = prev_test_vec.expected_error report "The error does not match. Index: " & integer'image(i-1) severity error;
        assert co_uncorrectable_error = prev_test_vec.expected_uncorrectable_error report "The uncorrectable error does not match. Index: " & integer'image(i-1) severity error;
      end if;

      wait for char_clk_period;
    end loop;  -- i
    wait for 100 ms;
  end process test;
end architecture a1;
