library ieee;
use ieee.std_logic_1164.all;

package testing_functions is
  function vec2str(vec: std_logic_vector) return string;
end package testing_functions;

package body testing_functions is

  function vec2str(vec: std_logic_vector) return string is
    variable result: string(vec'left + 1 downto 1);
  begin
    for i in vec'reverse_range loop
      if (vec(i) = '1') then
        result(i + 1) := '1';
      elsif (vec(i) = '0') then
        result(i + 1) := '0';
      else
        result(i + 1) := 'X';
      end if;
    end loop;
    return result;
  end;

end package body testing_functions;
