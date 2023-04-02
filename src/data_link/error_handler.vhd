-------------------------------------------------------------------------------
-- Title      : error handler
-------------------------------------------------------------------------------
-- File       : error_handler.vhd
-------------------------------------------------------------------------------
-- Description: Processes errors given the allowed number of errors
-- configuration. Outputs request_sync if more than allowed number
-- of errors was reached.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.data_link_pkg.all;

entity error_handler is
  generic (
    CONFIG : error_handling_config; -- Configuration of error handling
    F : integer range 1 to 256; -- Number of octets in a frame
    K : integer range 1 to 32); -- Number of frames in a multiframe
  port (
    ci_char_clk                      : in  std_logic;  -- Character clock
    ci_reset                         : in  std_logic;  -- Reset (asynchronous,
                                                       -- active low)
    ci_state                         : in link_state;  -- State of the lane.

    di_char                          : in  character_vector;  -- Character from
                                                              -- 8b10b decoder

    ci_lane_alignment_error          : in  std_logic;  -- Signals an error with
                                                       -- lane alignment
    ci_lane_alignment_correct_count  : in  integer;  -- Signals number of
                                                     -- alignment characters on
                                                     -- the same position
    ci_frame_alignment_error         : in  std_logic;  -- Signals an error with
                                                       -- frame alignment
    ci_frame_alignment_correct_count : in  integer;  -- Signals number of
                                                     -- alignemnt characters on
                                                     -- the same position

    co_frame_alignment_realign       : out std_logic;  -- Output to realign
                                                       -- frame
    co_lane_alignment_realign        : out std_logic;  -- Output to realign lane
    co_request_sync                  : out std_logic);  -- Request a synchronization
end entity error_handler;

architecture a1 of error_handler is
  signal active : std_logic;

  signal reg_index : integer range 0 to 256 := 0;
  signal reg_request_sync : std_logic;
  signal reg_missing_count : integer range 0 to 256 := 0;
  signal reg_disparity_count : integer range 0 to 256 := 0;
  signal reg_unexpected_count : integer range 0 to 256 := 0;

  signal next_index : integer range 0 to 256 := 0;
  signal next_request_sync : std_logic;
  signal next_missing_count : integer range 0 to 256 := 0;
  signal next_disparity_count : integer range 0 to 256 := 0;
  signal next_unexpected_count : integer range 0 to 256 := 0;
begin  -- architecture a1
  set_next: process (ci_char_clk, ci_reset) is
  begin  -- process set_next
    if ci_reset = '0' then              -- asynchronous reset (active low)
      reg_index <= 0;
      reg_request_sync <= '0';
      reg_missing_count <= 0;
      reg_disparity_count <= 0;
      reg_unexpected_count <= 0;
    elsif ci_char_clk'event and ci_char_clk = '1' then  -- rising clock edge
      reg_index <= next_index;
      reg_request_sync <= next_request_sync;
      reg_missing_count <= next_missing_count;
      reg_disparity_count <= next_disparity_count;
      reg_unexpected_count <= next_unexpected_count;
    end if;
  end process set_next;

  co_request_sync <= reg_request_sync;
  active <= '1' when di_char.user_data = '1' and ci_state /= INIT else '0';
  next_index <= 0 when active = '0' else
                (reg_index + 1) mod K*F;

  next_request_sync <= '0' when active = '0' else
                       '1' when reg_request_sync = '1' else
                       '1' when ci_lane_alignment_correct_count >= CONFIG.lane_alignment_realign_after else
                       '1' when ci_frame_alignment_correct_count >= CONFIG.frame_alignment_realign_after else
                       '1' when reg_missing_count > CONFIG.tolerate_missing_in_frame else
                       '1' when reg_disparity_count > CONFIG.tolerate_disparity_in_frame else
                       '1' when reg_unexpected_count > CONFIG.tolerate_unexpected_characters_in_frame else
                       '0';

  next_missing_count <= 0 when next_index = 0 else
                        next_missing_count when di_char.missing_error = '0' else
                        next_missing_count + 1;
  next_disparity_count <= 0 when next_index = 0 else
                        next_disparity_count when di_char.disparity_error = '0' else
                        next_disparity_count + 1;
  next_unexpected_count <= 0 when next_index = 0 else
                          next_unexpected_count when ci_state = DATA and di_char.kout = '1' and not (di_char.d8b = "11111100" or di_char.d8b = "01111100") else
                          next_unexpected_count + 1;

end architecture a1;
