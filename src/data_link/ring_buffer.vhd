library ieee;
use work.data_link_pkg.all;
use ieee.std_logic_1164.all;

entity ring_buffer is

  generic (
    CHARACTER_SIZE : integer := 8;
    BUFFER_SIZE : integer;
    READ_SIZE : integer);      -- The size of the buffer

  port (
    ci_clk             : in  std_logic;   -- The clock
    ci_reset           : in  std_logic;   -- The reset (active low)
    ci_adjust_position : in  integer range -READ_SIZE/2-1 to READ_SIZE/2+1;
    ci_read            : in  std_logic;   -- One to read in current cycle, Zero
                                        -- to stay on current reading position
    di_character       : in  std_logic_vector(CHARACTER_SIZE-1 downto 0);  -- The character to save on next clock
    co_read            : out std_logic_vector(CHARACTER_SIZE*READ_SIZE - 1 downto 0);  -- The output characters read from the buffer
    co_size            : out integer;   -- The current count of filled data
    co_read_position   : out integer;   -- The current read position inside of
                                        -- the buffer
    co_write_position  : out integer;   -- The current write position
                                        -- next character will be written to
    co_filled          : out std_logic);  -- Whether the buffer is full

end entity ring_buffer;

architecture a1 of ring_buffer is
	 constant BIT_BUFFER_SIZE : integer := CHARACTER_SIZE*BUFFER_SIZE-1;
    signal buff : std_logic_vector(CHARACTER_SIZE*BUFFER_SIZE-1 downto 0);
    signal buff_triple : std_logic_vector(3*CHARACTER_SIZE*BUFFER_SIZE-1 downto 0);
    signal next_read : std_logic_vector(CHARACTER_SIZE*BUFFER_SIZE-1 downto 0);
    signal read_position : integer := 0;
    signal adjusted_read_position : integer := 0;
    signal write_position : integer := 0;
    signal reg_size : integer := 0;
    signal size : integer := 0;
begin  -- architecture a1
    -- purpose: Adjust read position and read next character
    -- type   : sequential
    -- inputs : ci_clk, ci_reset
    -- outputs: read_position, write_position, buff
    read: process (ci_clk, ci_reset) is
        variable read_from_position : integer range 0 to BIT_BUFFER_SIZE-1;
        variable read_to_position : integer range 0 to BIT_BUFFER_SIZE-1;
    begin  -- process read
        if ci_reset = '0' then          -- asynchronous reset (active low)
            buff <= (others => '0');
            read_position <= 0;
            write_position <= 0;
            reg_size <= 0;
            co_read_position <= 0;
        elsif ci_clk'event and ci_clk = '1' then  -- rising clock edge
            if ci_read = '1' and size >= READ_SIZE + ci_adjust_position then
                read_position <= (read_position + ci_adjust_position + READ_SIZE) mod BUFFER_SIZE;
                co_read_position <= (read_position + ci_adjust_position) mod BUFFER_SIZE;
                reg_size <= size - READ_SIZE - ci_adjust_position + 1;

                read_from_position := (CHARACTER_SIZE*BUFFER_SIZE - 1 - (read_position + ci_adjust_position)*CHARACTER_SIZE) mod (CHARACTER_SIZE*BUFFER_SIZE);
                read_to_position := (CHARACTER_SIZE*BUFFER_SIZE - (read_position + ci_adjust_position + READ_SIZE)*CHARACTER_SIZE) mod (CHARACTER_SIZE*BUFFER_SIZE);
					 if read_from_position >= read_to_position then
					     co_read(CHARACTER_SIZE*READ_SIZE - 1 downto 0) <= buff(read_from_position downto read_from_position + 1 - READ_SIZE*CHARACTER_SIZE);
                else
						  co_read(CHARACTER_SIZE*READ_SIZE - 1 downto CHARACTER_SIZE*READ_SIZE - 1 - read_from_position) <= buff(read_from_position downto 0);
						  co_read(CHARACTER_SIZE*BUFFER_SIZE - 1 - read_to_position downto 0) <= buff(CHARACTER_SIZE*BUFFER_SIZE - 1 downto read_to_position);
                end if;
            else
                reg_size <= reg_size + 1;
            end if;

            adjusted_read_position <= read_position + ci_adjust_position;
            buff(CHARACTER_SIZE*BUFFER_SIZE-1 - CHARACTER_SIZE*write_position downto CHARACTER_SIZE*BUFFER_SIZE - CHARACTER_SIZE*(write_position + 1)) <= di_character;
            write_position <= (write_position + 1) mod BUFFER_SIZE;
        end if;
    end process read;

    co_write_position <= write_position;
    co_size <= size;
    size <= BUFFER_SIZE when reg_size > BUFFER_SIZE else
               reg_size;

    co_filled <=  '1' when reg_size > BUFFER_SIZE else
                  '0';

end architecture a1;
