LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY collision IS
  GENERIC (
    CLOCK_HZ : integer := 50_000_000;
    HOLD_MS  : integer := 30
  );
  PORT(
    clk        : IN  std_logic;

    bird_y_pos : IN std_logic_vector(9 DOWNTO 0);

    pipe1_x_pos : IN  std_logic_vector(9 DOWNTO 0);
    pipe2_x_pos : IN  std_logic_vector(9 DOWNTO 0);
    pipe3_x_pos : IN  std_logic_vector(9 DOWNTO 0);

    pipe1_active : IN std_logic;
    pipe2_active : IN std_logic;
    pipe3_active : IN std_logic;
	 
	 collision    : OUT std_logic;
  );
END ENTITY;

ARCHITECTURE rtl OF collision IS

 CONSTANT BIRD_X      : integer := 100;

 WHEN 
 
 WHEN BIRD_X >= pipe1_x_pos OR BIRD_X >= pipe1_x_pos OR
 
 WHEN BIRD_Y = pipe1OR bird_y_pos + 24 = pipe1_x_pos + 

END ARCHITECTURE;
