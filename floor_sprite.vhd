LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY floor_sprite IS
  PORT(
    clk          : IN std_logic;
    Frame_tick   : IN std_logic;
    game_state   : IN std_logic_vector(1 DOWNTO 0); -- Agregado para sincronizar movimiento
    row          : IN std_logic_vector(9 DOWNTO 0);
    column       : IN std_logic_vector(9 DOWNTO 0);
    pixel_data   : OUT std_logic_vector(11 DOWNTO 0);
    visible      : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF floor_sprite IS
  -- CONSTANTES DEL PISO
  CONSTANT IMG_W       : integer := 20;   -- Ancho de una baldosa del piso
  CONSTANT IMG_H       : integer := 60;   -- Alto de una baldosa del piso
  CONSTANT SCREEN_H    : integer := 480;  -- Alto de pantalla
  CONSTANT Y_START     : integer := SCREEN_H - IMG_H; -- Inicia en y=420 (480-60)
  CONSTANT TRANSP      : std_logic_vector(11 DOWNTO 0) := x"BBB"; -- Color transparente
  
  -- CONSTANTES DE MOVIMIENTO (Sincronizadas con pipe_movement)
  CONSTANT PIPE_SPEED  : integer := 2; -- Debe ser igual a la velocidad de la tubería
  
  -- Estados del juego (Sincronizadas con pipe_movement)
  CONSTANT ST_START    : std_logic_vector(1 DOWNTO 0) := "00";
  CONSTANT ST_PLAYING  : std_logic_vector(1 DOWNTO 0) := "01";
  
  -- REGISTROS DE SCROLL
  -- Mantiene el desplazamiento horizontal dentro de la baldosa (0 a 19)
  SIGNAL scroll_offset_reg : integer range 0 to IMG_W-1 := 0;
  SIGNAL scroll_offset_next : integer range 0 to IMG_W-1; 
  
  -- SEÑALES DE CÁLCULO
  SIGNAL x_i, y_i      : integer;
  SIGNAL within_y      : std_logic;
  SIGNAL dy_i          : integer;
  SIGNAL x_mod_i       : integer;  -- Posición X dentro de la baldosa repetida
  SIGNAL index_i       : integer;
  
  SIGNAL addr          : std_logic_vector(11 DOWNTO 0);
  SIGNAL color         : std_logic_vector(11 DOWNTO 0);
BEGIN
  
  -- LÓGICA DE MOVIMIENTO DEL SCROLL
  PROCESS(Frame_tick)
    -- Rango suficiente para IMG_W + PIPE_SPEED - 1
    VARIABLE temp_offset : integer range 0 to (IMG_W + PIPE_SPEED - 1);
  BEGIN
    IF rising_edge(Frame_tick) THEN
      IF game_state = ST_PLAYING THEN
        -- SUMAMOS el offset para lograr el movimiento a la izquierda
        -- (Si restar causó movimiento a la derecha, sumar causará movimiento a la izquierda)
        temp_offset := scroll_offset_reg + PIPE_SPEED;
        
        -- Manejar el wrap-around (si se vuelve mayor o igual a IMG_W)
        IF temp_offset >= IMG_W THEN
          scroll_offset_reg <= temp_offset - IMG_W;
        ELSE
          scroll_offset_reg <= temp_offset;
        END IF;
      ELSIF game_state = ST_START THEN
        -- Resetear el scroll al inicio del juego
        scroll_offset_reg <= 0;
      END IF;
    END IF;
  END PROCESS;

  -- LÓGICA COMBINACIONAL PARA VISUALIZACIÓN
  x_i  <= to_integer(unsigned(column));
  y_i  <= to_integer(unsigned(row));
  
  -- Verifica si estamos dentro del rango vertical del piso
  within_y <= '1' WHEN (y_i >= Y_START) AND (y_i < SCREEN_H) ELSE '0';
  
  -- Distancia vertical desde el inicio del piso
  dy_i <= y_i - Y_START;
  
  -- Calcula la posición X dentro de la baldosa usando el scroll offset.
  -- El (x_i + scroll_offset_reg) permite que el patrón se desplace.
  -- El MOD hace que la imagen se repita horizontalmente (scroll infinito).
  x_mod_i <= (x_i + scroll_offset_reg) mod IMG_W;
  
  -- Calcula el índice en la ROM
  index_i <= dy_i * IMG_W + x_mod_i WHEN within_y = '1' ELSE 0;
  
  addr <= std_logic_vector(to_unsigned(index_i, addr'length));
  
  -- ROM que contiene la imagen del piso (asume que existe rom_piso)
  u_rom : ENTITY work.rom_piso
    PORT MAP (
      clk    => clk,
      r_addr => addr,
      r_data => color
    );
  
  pixel_data <= color;
  -- El piso solo es visible dentro de su rango Y y si el color no es transparente
  visible <= '1' WHEN (within_y = '1') AND (color /= TRANSP) ELSE '0';
  
END ARCHITECTURE;