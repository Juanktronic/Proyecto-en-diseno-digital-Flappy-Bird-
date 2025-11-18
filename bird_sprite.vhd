LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY bird_sprite IS
  PORT(
    clk         : IN  std_logic;
    enable      : IN  std_logic; 
    row         : IN  std_logic_vector(9 DOWNTO 0);
    column      : IN  std_logic_vector(9 DOWNTO 0);
    x_pos       : IN  std_logic_vector(9 DOWNTO 0);
    y_pos       : IN  std_logic_vector(9 DOWNTO 0);
    pixel_data  : OUT std_logic_vector(11 DOWNTO 0);
    visible     : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF bird_sprite IS
  CONSTANT IMG_W  : integer := 34;
  CONSTANT IMG_H  : integer := 24;
  CONSTANT TRANSP : std_logic_vector(11 DOWNTO 0) := x"BBB";
  
  SIGNAL addr      : std_logic_vector(9 DOWNTO 0);
  SIGNAL color_rom : std_logic_vector(11 DOWNTO 0);
  
  -- Señales intermedias
  SIGNAL x, y, x0, y0 : unsigned(9 DOWNTO 0);
  SIGNAL dx, dy : unsigned(9 DOWNTO 0);
  SIGNAL inside : std_logic;
  SIGNAL index : integer;
  
BEGIN

  --------------------------------------------------------------------
  -- ASIGNACIONES CONCURRENTES (igual que antes)
  --------------------------------------------------------------------
  x  <= unsigned(column);
  y  <= unsigned(row);
  x0 <= unsigned(x_pos);
  y0 <= unsigned(y_pos);
  
  inside <= '1' WHEN (x >= x0) AND (x < x0 + IMG_W) AND
                     (y >= y0) AND (y < y0 + IMG_H)
            ELSE '0';
  
  dx <= x - x0;
  dy <= y - y0;
  
  index <= to_integer(dy) * IMG_W + to_integer(dx) WHEN inside = '1' 
           ELSE 0;
  
  addr <= std_logic_vector(to_unsigned(index, 10));
  
  --------------------------------------------------------------------
  -- ROM (sin cambios)
  --------------------------------------------------------------------
  u_rom : ENTITY work.bird_rom
    PORT MAP (
      clk     => clk,
      r_addr  => addr,
      r_data  => color_rom
    );
  

  pixel_data <= color_rom;
  
  visible <= '1' WHEN (enable = '1') AND           -- ← MODIFICADO
                      (inside = '1') AND 
                      (color_rom /= TRANSP)
             ELSE '0';

END ARCHITECTURE;