library ieee;
use ieee.std_logic_1164.all;
use work.jesd204b_pkg.all;
use work.data_link_pkg.all;
use work.transport_pkg.all;

entity jesd204b_multipoint_link_rx is

  generic (
    K_CHAR            : std_logic_vector(7 downto 0) := "10111100";  -- Sync character
    R_CHAR            : std_logic_vector(7 downto 0) := "00011100";  -- ILAS first
                                        -- frame character
    A_CHAR            : std_logic_vector(7 downto 0) := "01111100";  -- Multiframe
                                        -- alignment character
    Q_CHAR            : std_logic_vector(7 downto 0) := "10011100";  -- ILAS 2nd
    DATA_RATE         : integer;  -- DEVICE_CLK_FREQ*this is lane bit rate
                                     -- frame 2nd character
    MULTIFRAME_RATE   : integer;        -- F * K, should be the same for every
                                        -- device
    ALIGN_BUFFER_SIZE : integer                      := 255;  -- Size of a
                                                              -- buffer that is
                                                              -- used for
                                                              -- aligning lanes
    RX_BUFFER_DELAY   : integer range 1 to 32        := 1;
    LINKS             : integer;        -- Count of links
    LANES             : integer;        -- Total nubmer of lanes
    CONVERTERS        : integer;        -- Total number of converters
    CONFIG            : link_config_array(0 to LINKS - 1);
    ERROR_CONFIG      : error_handling_config        := (2, 0, 5, 5, 5));

  port (
    ci_device_clk   : in  std_logic;
    ci_char_clk     : in  std_logic;
    ci_frame_clk    : in  std_logic;
    ci_sysref       : in  std_logic;
    ci_reset        : in  std_logic;
    ci_request_sync : in  std_logic;
    co_nsynced      : out std_logic;
    co_error        : out std_logic;
    di_data         : in  lane_input_array(0 to LANES - 1);
    do_samples      : out samples_array(0 to CONVERTERS - 1);
    do_ctrl_bits    : out ctrl_bits_array(0 to CONVERTERS - 1);
    co_frame_state  : out frame_state_array(0 to LINKS - 1);
    co_correct_data : out std_logic);

end entity jesd204b_multipoint_link_rx;

architecture a1 of jesd204b_multipoint_link_rx is
  constant all_ones : std_logic_vector(LINKS - 1 downto 0) := (others => '1');
  constant all_zeros : std_logic_vector(LINKS - 1 downto 0) := (others => '0');

  signal links_correct_data : std_logic_vector(LINKS - 1 downto 0);
  signal links_error : std_logic_vector(LINKS - 1 downto 0);
  signal links_nsynced : std_logic_vector(LINKS - 1 downto 0);

  signal multiframe_clk : std_logic;
  signal lmfc_aligned : std_logic;
  signal nsynced : std_logic;

  -- purpose: Count lanes before link with index link_index
  function sumCummulativeLanes (
    link_index : integer range 0 to LINKS-1)
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
    link_index : integer range 0 to LINKS-1)
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
  co_error <= '0' when links_error = all_zeros else '1';
  co_correct_data <= '1' when links_correct_data = all_ones else '0';
  co_nsynced <= nsynced;

  sync_combination : entity work.synced_combination
    generic map (
      SUBCLASSV => CONFIG(0).SUBCLASSV,
      N         => LINKS,
      INVERT   => '1')
    port map (
      ci_frame_clk      => ci_frame_clk,
      ci_multiframe_clk => multiframe_clk,
      ci_reset          => ci_reset,
      ci_lmfc_aligned   => lmfc_aligned,
      ci_synced_array   => links_nsynced,
      co_nsynced        => nsynced);

  lmfc_generation: entity work.lmfc_generation
    generic map (
      MULTIFRAME_RATE => MULTIFRAME_RATE,
      DATA_RATE  => DATA_RATE)
    port map (
      ci_device_clk     => ci_device_clk,
      ci_reset          => ci_reset,
      ci_sysref         => ci_sysref,
      ci_nsynced        => nsynced,
      co_multiframe_clk => multiframe_clk,
      co_lmfc_aligned   => lmfc_aligned);

  links_rx : for i in 0 to LINKS - 1 generate
    link : entity work.jesd204b_link_rx
      generic map (
        K_CHAR            => K_CHAR,
        R_CHAR            => R_CHAR,
        A_CHAR            => A_CHAR,
        Q_CHAR            => Q_CHAR,
        ERROR_CONFIG      => ERROR_CONFIG,
        ALIGN_BUFFER_SIZE => ALIGN_BUFFER_SIZE,
        RX_BUFFER_DELAY   => RX_BUFFER_DELAY,
        ADJCNT            => CONFIG(i).ADJCNT,
        BID               => CONFIG(i).BID,
        DID               => CONFIG(i).DID,
        HD                => CONFIG(i).HD,
        JESDV             => CONFIG(i).JESDV,
        PHADJ             => CONFIG(i).PHADJ,
        SUBCLASSV         => CONFIG(i).SUBCLASSV,
        K                 => CONFIG(i).K,
        CS                => CONFIG(i).CS,
        M                 => CONFIG(i).M,
        S                 => CONFIG(i).S,
        L                 => CONFIG(i).L,
        F                 => CONFIG(i).F,
        CF                => CONFIG(i).CF,
        N                 => CONFIG(i).N,
        Nn                => CONFIG(i).Nn,
        ADJDIR            => CONFIG(i).ADJDIR)
    port map (
      ci_char_clk       => ci_char_clk,
      ci_frame_clk      => ci_frame_clk,
      ci_multiframe_clk => multiframe_clk,
      ci_reset          => ci_reset,
      ci_request_sync   => ci_request_sync,
      co_nsynced        => links_nsynced(i),
      co_error          => links_error(i),
      di_data           => di_data(sumCummulativeLanes(i) to sumCummulativeLanes(i) + CONFIG(i).L - 1),
      do_ctrl_bits      => do_ctrl_bits(sumCummulativeConverters(i) to sumCummulativeConverters(i) + CONFIG(i).M - 1),
      do_samples        => do_samples(sumCummulativeConverters(i) to sumCummulativeConverters(i) + CONFIG(i).M - 1),
      co_frame_state    => co_frame_state(i),
      co_correct_data   => links_correct_data(i));
  end generate links_rx;

end architecture a1;
