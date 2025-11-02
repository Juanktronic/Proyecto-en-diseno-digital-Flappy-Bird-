LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;30



   TYPE mum_pipes IS ARRAY (0 TO 3);
	   TYPE pipes IS ARRAY (0 TO 2**ADDR_WIDTH - 1)
        OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);