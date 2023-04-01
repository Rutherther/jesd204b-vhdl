library ieee;
use ieee.std_logic_1164.all;
use work.jesd204b_pkg.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity jesd204b_multipoint_link_rx is

  generic (
    K_character  : std_logic_vector(7 downto 0) := "10111100";  -- Sync character
    R_character  : std_logic_vector(7 downto 0) := "00011100";  -- ILAS first
                                        -- frame character
    A_character  : std_logic_vector(7 downto 0) := "01111100";  -- Multiframe
                                        -- alignment character
    Q_character  : std_logic_vector(7 downto 0) := "10011100";  -- ILAS 2nd
                                        -- frame 2nd character
    LINKS        : integer;             -- Count of links
    LANES        : integer;             -- Total nubmer of lanes
    CONVERTERS   : integer;             -- Total number of converters
    CONFIG       : link_config_array(0 to LINKS - 1);
    ERROR_CONFIG : error_handling_config        := (2, 0, 5, 5, 5));

  port (
    ci_char_clk          : in  std_logic;
    ci_frame_clk          : in  std_logic;
    ci_reset            : in  std_logic;
    ci_request_sync     : in  std_logic;
    co_nsynced          : out std_logic;
    co_error            : out std_logic;
    di_transceiver_data : in  lane_input_array(0 to LANES - 1);
    do_samples          : out simple_samples_array(0 to LINKS - 1)(0 to CONFIG(0).M - 1, 0 to CONFIG(0).CS - 1);
    co_frame_state      : out frame_state_array(0 to LINKS - 1);
    co_correct_data     : out std_logic);

end entity jesd204b_multipoint_link_rx;

architecture a1 of jesd204b_multipoint_link_rx is
  constant all_ones : std_logic_vector(LINKS - 1 downto 0) := (others => '1');
  constant all_zeros : std_logic_vector(LINKS - 1 downto 0) := (others => '0');

  signal links_correct_data : std_logic_vector(LINKS - 1 downto 0);
  signal links_error : std_logic_vector(LINKS - 1 downto 0);
  signal links_nsynced : std_logic_vector(LINKS - 1 downto 0);

  -- purpose: Count lanes before link with index link_index
  function sumCummulativeLanes (
    link_index : integer)
    return integer is
    variable lanes_count : integer := 0;
  begin  -- function sumCummulativeLanes
    if link_index /= 0 then
        for i in 0 to link_index -1 loop
          lanes_count := lanes_count + CONFIG(i).L;
        end loop;  -- i
    end if;

    return lanes_count;
  end function sumCummulativeLanes;

  -- purpose: Count converters before link with index link_index
  function sumCummulativeConverters (
    link_index : integer)
    return integer is
    variable converters_count : integer := 0;
  begin  -- function sumCummulativeConverters
    if link_index /= 0 then
        for i in 0 to link_index -1 loop
          converters_count := converters_count + CONFIG(i).M;
        end loop;  -- i
    end if;

    return converters_count;
  end function sumCummulativeConverters;
begin  -- architecture a1
  co_nsynced <= '0' when links_nsynced = all_zeros else '1';
  co_error <= '0' when links_error = all_zeros else '1';
  co_correct_data <= '1' when links_correct_data = all_ones else '0';

  links_rx: for i in 0 to LINKS - 1 generate
    link: entity work.jesd204b_link_rx
      generic map (
        K_character  => K_character,
        R_character  => R_character,
        A_character  => A_character,
        Q_character  => Q_character,
        ERROR_CONFIG => ERROR_CONFIG,
        ADJCNT       => CONFIG(i).ADJCNT,
        BID          => CONFIG(i).BID,
        DID          => CONFIG(i).DID,
        HD           => CONFIG(i).HD,
        JESDV        => CONFIG(i).JESDV,
        PHADJ        => CONFIG(i).PHADJ,
        SUBCLASSV    => CONFIG(i).SUBCLASSV,
        K            => CONFIG(i).K,
        CS           => CONFIG(i).CS,
        M            => CONFIG(i).M,
        S            => CONFIG(i).S,
        L            => CONFIG(i).L,
        F            => CONFIG(i).F,
        CF           => CONFIG(i).CF,
        N            => CONFIG(i).N,
        Nn           => CONFIG(i).Nn,
        ADJDIR       => CONFIG(i).ADJDIR)
    port map (
      ci_char_clk         => ci_char_clk,
      ci_frame_clk        => ci_frame_clk,
      ci_reset            => ci_reset,
      ci_request_sync     => ci_request_sync,
      co_nsynced          => links_nsynced(i),
      co_error            => links_error(i),
      di_transceiver_data => di_transceiver_data(sumCummulativeLanes(i) to sumCummulativeLanes(i) + CONFIG(i).L - 1),
      do_samples          => do_samples(i), -- do_samples(sumCummulativeConverters(i) to sumCummulativeConverters(i) + CONFIG(i).M - 1),
      co_frame_state      => co_frame_state(i),
      co_correct_data     => links_correct_data(i));
  end generate links_rx;

end architecture a1;
