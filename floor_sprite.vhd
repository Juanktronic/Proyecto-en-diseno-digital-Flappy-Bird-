LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY floor_sprite IS
  PORT(
    clk        : IN std_logic;
    row        : IN std_logic_vector(9 DOWNTO 0);
    column     : IN std_logic_vector(9 DOWNTO 0);
    pixel_data : OUT std_logic_vector(11 DOWNTO 0);
    visible    : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF floor_sprite IS
  CONSTANT IMG_W      : integer := 20;  -- Ancho de una baldosa del piso
  CONSTANT IMG_H      : integer := 60;  -- Alto de una baldosa del piso
  CONSTANT SCREEN_H   : integer := 480; -- Alto de pantalla
  CONSTANT Y_START    : integer := SCREEN_H - IMG_H;  -- Inicia en y=420 (480-60)
  CONSTANT TRANSP     : std_logic_vector(11 DOWNTO 0) := x"BBB";  -- Color transparente
  
  SIGNAL addr         : std_logic_vector(11 DOWNTO 0);
  SIGNAL color        : std_logic_vector(11 DOWNTO 0);
  SIGNAL x_i, y_i     : integer;
  SIGNAL within_y     : std_logic;
  SIGNAL dy_i         : integer;
  SIGNAL x_mod_i      : integer;  -- Posición X dentro de la baldosa repetida
  SIGNAL index_i      : integer;
  
BEGIN
  x_i  <= to_integer(unsigned(column));
  y_i  <= to_integer(unsigned(row));
  
  -- Verifica si estamos dentro del rango vertical del piso (últimos 60 píxeles)
  within_y <= '1' WHEN (y_i >= Y_START) AND (y_i < SCREEN_H) ELSE '0';
  
  -- Distancia vertical desde el inicio del piso
  dy_i <= y_i - Y_START;
  
  -- Calcula la posición X dentro de la baldosa usando módulo
  -- Esto hace que la imagen se repita horizontalmente
  x_mod_i <= x_i mod IMG_W;
  
  -- Calcula el índice en la ROM
  index_i <= dy_i * IMG_W + x_mod_i WHEN within_y = '1' ELSE 0;
  
  addr <= std_logic_vector(to_unsigned(index_i, addr'length));
  
  -- ROM que contiene la imagen del piso (devuelve 12 bits RGB)
  u_rom : ENTITY work.rom_piso
    PORT MAP (
      clk    => clk,
      r_addr => addr,
      r_data => color
    );
  
  pixel_data <= color;
  visible <= '1' WHEN (within_y = '1') AND (color /= TRANSP) ELSE '0';
  
END ARCHITECTURE;