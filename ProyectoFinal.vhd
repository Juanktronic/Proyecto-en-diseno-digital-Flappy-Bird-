LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;



ENTITY movement IS
  PORT(
	 Frame_tick : IN std_logic;
    x_pos      : IN  std_logic_vector(9 DOWNTO 0);  -- posición Y (esquina superior)
  );
END ENTITY;
--------------------------------------------------------------

ARCHITECTURE rtl OF movement IS

SIGNAL frames_tick : STD_LOGIC;
SIGNAL frames_tick : STD_LOGIC;

x


BEGIN

  frame_counter : ENTITY work.contador
    GENERIC MAP ( N => 6 )
    PORT MAP (
      clk      => Frame_tick,
      max      => std_logic_vector(to_unsigned(30, 6)),
      max_tick => frames_tick,
      counter  => OPEN
    );
	 
  pipe_gen_counter : ENTITY work.contador 
	 GENERIC MAP ( N => 8 )
    PORT MAP (
      clk      => frames_tick,
      max      => std_logic_vector(to_unsigned(176, 8)),
      max_tick => pipe_gen,
      counter  => OPEN
    );
	 
	WHEN frames_tick = '1' THEN
	
	


END ARCHITECTURE;
--------------------------------------------------------------
