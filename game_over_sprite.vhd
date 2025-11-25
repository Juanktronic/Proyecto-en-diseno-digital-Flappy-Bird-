-- ============================================
-- SPRITE PARA "GAME OVER" CON ROM INTEGRADA (2-bit encoding)
-- ============================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY game_over_sprite IS
  PORT(
    clk        : IN  std_logic;
    row        : IN  std_logic_vector(9 DOWNTO 0);
    column     : IN  std_logic_vector(9 DOWNTO 0);
    enable     : IN  std_logic;
    pixel_data : OUT std_logic_vector(11 DOWNTO 0);
    visible    : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF game_over_sprite IS
  CONSTANT IMG_W    : integer := 313;
  CONSTANT IMG_H    : integer := 58;
  CONSTANT SCREEN_W : integer := 640;
  CONSTANT SCREEN_H : integer := 480;
  CONSTANT X_POS    : integer := (SCREEN_W - IMG_W) / 2;  -- Centrado horizontal
  CONSTANT Y_POS    : integer := (SCREEN_H - IMG_H) / 2 - 60;  -- Centrado vertical
  
  SIGNAL addr       : std_logic_vector(14 DOWNTO 0);  -- 15 bits para 324*80 = 25920
  SIGNAL color_code : std_logic_vector(1 DOWNTO 0);
  
  -- Señales intermedias (como bird_sprite)
  SIGNAL x, y, x0, y0 : unsigned(9 DOWNTO 0);
  SIGNAL dx, dy       : unsigned(9 DOWNTO 0);
  SIGNAL inside       : std_logic;
  SIGNAL index        : integer;
  
BEGIN
  -- Asignaciones concurrentes
  x  <= unsigned(column);
  y  <= unsigned(row);
  x0 <= to_unsigned(X_POS, 10);
  y0 <= to_unsigned(Y_POS, 10);
  
  -- Verificar si estamos dentro del área del sprite
  inside <= '1' WHEN (x >= x0) AND (x < x0 + IMG_W) AND
                     (y >= y0) AND (y < y0 + IMG_H)
            ELSE '0';
  
  -- Calcular offset local
  dx <= x - x0;
  dy <= y - y0;
  
  -- Calcular índice lineal
  index <= to_integer(dy) * IMG_W + to_integer(dx) WHEN inside = '1' 
           ELSE 0;
  
  addr <= std_logic_vector(to_unsigned(index, 15));
  
  -- ROM integrada
  u_rom : ENTITY work.rom_GameOver
    PORT MAP(
      clk    => clk,
      r_addr => addr,
      r_data => color_code
    );
  
  -- Decodificación de color (2 bits a 12 bits RGB)
  WITH color_code SELECT
    pixel_data <= x"000" WHEN "00",      -- Negro
                  x"FFF" WHEN "01",      -- Blanco
                  x"888" WHEN "10",      -- Gris/transparente
                  x"000" WHEN OTHERS;
  
  -- Visible solo si está dentro, habilitado y no es transparente
  visible <= '1' WHEN (enable = '1') AND 
                      (inside = '1') AND 
                      (color_code /= "10")
             ELSE '0';
  
END ARCHITECTURE;