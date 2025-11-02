LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- ===========================================================
-- Sprite del pájaro (32x32)
-- Lee los datos de bird_rom (inicializada con bird.mif)
-- y genera la imagen en la posición (x_pos, y_pos)
-- ===========================================================

ENTITY bird_sprite IS
  PORT(
    clk         : IN  std_logic;
    row         : IN  std_logic_vector(9 DOWNTO 0);
    column      : IN  std_logic_vector(9 DOWNTO 0);
    x_pos       : IN  std_logic_vector(9 DOWNTO 0);  -- posición X (esquina izquierda)
    y_pos       : IN  std_logic_vector(9 DOWNTO 0);  -- posición Y (esquina superior)
    pixel_data  : OUT std_logic_vector(11 DOWNTO 0); -- salida de color RGB (12 bits)
    visible     : OUT std_logic                      -- indica si el píxel pertenece al sprite
  );
END ENTITY;
--------------------------------------------------------------

ARCHITECTURE rtl OF bird_sprite IS

  -- Parámetros de la imagen
  CONSTANT IMG_W : integer := 34;
  CONSTANT IMG_H : integer := 24;

  -- Señales internas
  SIGNAL addr  : std_logic_vector(9 DOWNTO 0);
  SIGNAL color : std_logic_vector(11 DOWNTO 0);

BEGIN

  -- Proceso para calcular la dirección del píxel dentro de la ROM
  process(row, column, x_pos, y_pos)
    variable x, y, x0, y0 : integer;
    variable index : integer;
  begin
    x  := to_integer(unsigned(column));
    y  := to_integer(unsigned(row));
    x0 := to_integer(unsigned(x_pos));
    y0 := to_integer(unsigned(y_pos));

    if (x >= x0) and (x < x0 + IMG_W) and
       (y >= y0) and (y < y0 + IMG_H) then
      -- Dentro del área del sprite
      index := (y - y0) * IMG_W + (x - x0);
      addr   <= std_logic_vector(to_unsigned(index, 10));
    else
      -- Fuera del sprite
      addr   <= (others => '0');
    end if;
  end process;

  -- ROM con los datos del sprite
  u_rom : ENTITY work.bird_rom
    PORT MAP (
      clk     => clk,
      r_addr  => addr,
      r_data  => color
    );

  -- Asignación del color y visibilidad
  process(color, row, column, x_pos, y_pos)
    variable x, y, x0, y0 : integer;
  begin
    x  := to_integer(unsigned(column));
    y  := to_integer(unsigned(row));
    x0 := to_integer(unsigned(x_pos));
    y0 := to_integer(unsigned(y_pos));

    if (x >= x0) and (x < x0 + IMG_W) and
       (y >= y0) and (y < y0 + IMG_H) then
      if (color = x"BBB") then
        visible <= '0';  -- color transparente
      else
        visible <= '1';
      end if;
    else
      visible <= '0';
    end if;

    pixel_data <= color;
  end process;

END ARCHITECTURE;
--------------------------------------------------------------
