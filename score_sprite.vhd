LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

--------------------------------------------------------------------------------
-- SCORE SPRITE: Displays two digits (00-99) from ROM images
-- Each digit sprite is 24 pixels wide x 34 pixels tall
-- Screen resolution: 640x480
--------------------------------------------------------------------------------
-- Dibuja:
--  - Score actual arriba centrado DURANTE PLAYING (start_state='0')
--  - Best score en la derecha
--  - Último score debajo del best score en START (start_state='1')
--------------------------------------------------------------------------------
ENTITY scores_sprite IS
  PORT(
    clk         : IN  std_logic;
    row         : IN  std_logic_vector(9 DOWNTO 0);  -- VGA row
    column      : IN  std_logic_vector(9 DOWNTO 0);  -- VGA column
    score_cur   : IN  unsigned(6 DOWNTO 0);          -- score actual (0-99)
    best_score  : IN  unsigned(6 DOWNTO 0);          -- best score (0-99)
    start_state : IN  std_logic;                     -- '1' = pantalla Start
    pixel_data  : OUT std_logic_vector(11 DOWNTO 0); -- RGB
    visible     : OUT std_logic                      -- 1 = dibujar pixel
  );
END ENTITY;

ARCHITECTURE rtl OF scores_sprite IS
  -- Dimensiones de cada dígito (igual que antes)
  CONSTANT DIGIT_WIDTH  : integer := 24;
  CONSTANT DIGIT_HEIGHT : integer := 34;
  CONSTANT DIGIT_SPACE  : integer := 4;  -- espacio entre decenas y unidades

  -- Posiciones fijas (puedes ajustar valores)
  CONSTANT SCORE_X      : integer := 270;  -- score arriba centrado
  CONSTANT SCORE_Y      : integer := 30;

  CONSTANT BEST_SCORE_X : integer := 475;  -- best score lado derecho
  CONSTANT BEST_SCORE_Y : integer := 228;

  CONSTANT LAST_SCORE_X : integer := 475;  -- último score debajo de best
  CONSTANT LAST_SCORE_Y : integer := 300;  -- BEST_SCORE_Y + algo

  -- Posición de pixel actual
  SIGNAL x_curr, y_curr : integer;

  -- Flags de “estoy dentro” de cada bloque
  SIGNAL in_score_top : std_logic;
  SIGNAL in_best      : std_logic;
  SIGNAL in_last      : std_logic;
  SIGNAL in_any       : std_logic;

  -- Coordenadas del bloque activo
  SIGNAL x_left, y_top : integer;

  -- Offset dentro del dígito
  SIGNAL offset_x, offset_y : integer;

  -- Dirección ROM
  SIGNAL rom_addr : std_logic_vector(11 DOWNTO 0);

  -- Dígitos
  SIGNAL digit_tens, digit_ones : integer range 0 TO 9;
  SIGNAL digit_select           : integer range 0 TO 9;

  -- Score seleccionado (según bloque)
  SIGNAL active_score : unsigned(6 DOWNTO 0);

  -- ROM outputs (2 bits por pixel: 00=negro, 01=blanco, 10=transparente)
  SIGNAL d0, d1, d2, d3, d4, d5, d6, d7, d8, d9 : std_logic_vector(1 DOWNTO 0);

  SIGNAL color_code : std_logic_vector(1 DOWNTO 0);

BEGIN
  ---------------------------------------------------------------------------
  -- 1) Pixel actual
  ---------------------------------------------------------------------------
  x_curr <= to_integer(unsigned(column));
  y_curr <= to_integer(unsigned(row));

  ---------------------------------------------------------------------------
  -- 2) ¿Estamos dentro de cada bloque?
  --    - score_top solo en PLAYING (start_state='0')
  --    - best y last solo en START (start_state='1')
  ---------------------------------------------------------------------------
  in_score_top <= '1' WHEN (start_state = '0') AND
                          (x_curr >= SCORE_X) AND
                          (x_curr <  SCORE_X + DIGIT_WIDTH*2 + DIGIT_SPACE) AND
                          (y_curr >= SCORE_Y) AND
                          (y_curr <  SCORE_Y + DIGIT_HEIGHT)
                  ELSE '0';

  in_best <= '1' WHEN (start_state = '1') AND
                      (x_curr >= BEST_SCORE_X) AND
                      (x_curr <  BEST_SCORE_X + DIGIT_WIDTH*2 + DIGIT_SPACE) AND
                      (y_curr >= BEST_SCORE_Y) AND
                      (y_curr <  BEST_SCORE_Y + DIGIT_HEIGHT)
             ELSE '0';

  in_last <= '1' WHEN (start_state = '1') AND
                      (x_curr >= LAST_SCORE_X) AND
                      (x_curr <  LAST_SCORE_X + DIGIT_WIDTH*2 + DIGIT_SPACE) AND
                      (y_curr >= LAST_SCORE_Y) AND
                      (y_curr <  LAST_SCORE_Y + DIGIT_HEIGHT)
             ELSE '0';

  in_any <= in_score_top OR in_best OR in_last;

  ---------------------------------------------------------------------------
  -- 3) Seleccionar qué score y qué bloque usar
  --    - PLAYING: solo in_score_top puede ser '1'
  --    - START: solo in_best o in_last pueden ser '1'
  --      último score usa el mismo valor que score_cur (porque no se resetea
  --      hasta que empieza un nuevo Playing)
  ---------------------------------------------------------------------------
  active_score <= score_cur   WHEN (in_score_top = '1') ELSE
                  best_score  WHEN (in_best      = '1') ELSE
                  score_cur   WHEN (in_last      = '1') ELSE
                  (OTHERS => '0');

  -- Coordenadas del bloque activo
  x_left <= SCORE_X      WHEN (in_score_top = '1') ELSE
            BEST_SCORE_X WHEN (in_best      = '1') ELSE
            LAST_SCORE_X WHEN (in_last      = '1') ELSE
            0;

  y_top  <= SCORE_Y      WHEN (in_score_top = '1') ELSE
            BEST_SCORE_Y WHEN (in_best      = '1') ELSE
            LAST_SCORE_Y WHEN (in_last      = '1') ELSE
            0;

  ---------------------------------------------------------------------------
  -- 4) Separar decenas y unidades del score activo
  ---------------------------------------------------------------------------
  digit_tens <= to_integer(active_score) / 10;
  digit_ones <= to_integer(active_score) - (digit_tens * 10);

  -- ¿qué dígito toca en este pixel?
  digit_select <= digit_tens WHEN (x_curr >= x_left AND x_curr < x_left + DIGIT_WIDTH) ELSE
                  digit_ones WHEN (x_curr >= x_left + DIGIT_WIDTH + DIGIT_SPACE AND
                                   x_curr <  x_left + DIGIT_WIDTH + DIGIT_SPACE + DIGIT_WIDTH) ELSE
                  0;

  ---------------------------------------------------------------------------
  -- 5) Offset dentro del dígito
  ---------------------------------------------------------------------------
  offset_x <= x_curr - x_left
              WHEN (x_curr >= x_left AND x_curr < x_left + DIGIT_WIDTH) ELSE
              x_curr - (x_left + DIGIT_WIDTH + DIGIT_SPACE)
              WHEN (x_curr >= x_left + DIGIT_WIDTH + DIGIT_SPACE AND
                    x_curr <  x_left + DIGIT_WIDTH + DIGIT_SPACE + DIGIT_WIDTH) ELSE
              0;

  offset_y <= y_curr - y_top WHEN in_any = '1' ELSE 0;

  ---------------------------------------------------------------------------
  -- 6) Dirección ROM (24x34 = 816 píxeles)
  ---------------------------------------------------------------------------
  rom_addr <= std_logic_vector(to_unsigned(
                (offset_y * DIGIT_WIDTH) + offset_x, 12
              ));

  ---------------------------------------------------------------------------
  -- 7) Instancia ÚNICA de todas las ROM de dígitos
  ---------------------------------------------------------------------------
  u0 : ENTITY work.rom_Cero  PORT MAP(clk => clk, r_addr => rom_addr, r_data => d0);
  u1 : ENTITY work.rom_One   PORT MAP(clk => clk, r_addr => rom_addr, r_data => d1);
  u2 : ENTITY work.rom_Two   PORT MAP(clk => clk, r_addr => rom_addr, r_data => d2);
  u3 : ENTITY work.rom_Three PORT MAP(clk => clk, r_addr => rom_addr, r_data => d3);
  u4 : ENTITY work.rom_Four  PORT MAP(clk => clk, r_addr => rom_addr, r_data => d4);
  u5 : ENTITY work.rom_Five  PORT MAP(clk => clk, r_addr => rom_addr, r_data => d5);
  u6 : ENTITY work.rom_Six   PORT MAP(clk => clk, r_addr => rom_addr, r_data => d6);
  u7 : ENTITY work.rom_Seven PORT MAP(clk => clk, r_addr => rom_addr, r_data => d7);
  u8 : ENTITY work.rom_Eight PORT MAP(clk => clk, r_addr => rom_addr, r_data => d8);
  u9 : ENTITY work.rom_Nine  PORT MAP(clk => clk, r_addr => rom_addr, r_data => d9);

  ---------------------------------------------------------------------------
  -- 8) Seleccionar dígito activo
  ---------------------------------------------------------------------------
  WITH digit_select SELECT
    color_code <= d0 WHEN 0,
                  d1 WHEN 1,
                  d2 WHEN 2,
                  d3 WHEN 3,
                  d4 WHEN 4,
                  d5 WHEN 5,
                  d6 WHEN 6,
                  d7 WHEN 7,
                  d8 WHEN 8,
                  d9 WHEN 9,
                  "00" WHEN OTHERS;

  ---------------------------------------------------------------------------
  -- 9) Decodificar color (00=negro, 01=blanco, 10=transparente)
  ---------------------------------------------------------------------------
  WITH color_code SELECT
    pixel_data <= x"000" WHEN "00",  -- Negro
                  x"FFF" WHEN "01",  -- Blanco
                  x"888" WHEN "10",  -- Gris/“transparente”
                  x"000" WHEN OTHERS;

  ---------------------------------------------------------------------------
  -- 10) Visible solo si estamos en algún bloque y no es transparente
  ---------------------------------------------------------------------------
  visible <= '1' WHEN (in_any = '1') AND (color_code /= "10") ELSE '0';

END ARCHITECTURE;
