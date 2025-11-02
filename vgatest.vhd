

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- =============================================================
-- RGB VGA test pattern con imagen desde ROM (12-bit RGB)
-- Muestra el pájaro y las tuberías en pantalla 640x480
-- =============================================================

ENTITY vgatest IS
  PORT(
    clock   : IN  std_logic;                    -- reloj base (25 MHz para VGA 640x480)
    R, G, B : OUT std_logic_vector(3 DOWNTO 0); -- 4 bits por canal RGB
    H, V    : OUT std_logic                     -- sincronización horizontal y vertical
  );
END ENTITY;

------------------------------------------------------------
ARCHITECTURE test OF vgatest IS

  ----------------------------------------------------------------
  -- VGA driver
  ----------------------------------------------------------------
  COMPONENT vga_driver IS
    PORT(
      clock       : IN  std_logic;
      row         : OUT std_logic_vector(9 DOWNTO 0);
      column      : OUT std_logic_vector(9 DOWNTO 0);
      H, V        : OUT std_logic;
      frame_flag  : OUT std_logic
    );
  END COMPONENT;

  ----------------------------------------------------------------
  -- Señales internas
  ----------------------------------------------------------------
  SIGNAL row, column  : std_logic_vector(9 DOWNTO 0);

  -- Pájaro
  SIGNAL bird_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL bird_visible : std_logic;

  -- Tubería
  SIGNAL pipe_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL pipe_visible : std_logic;
  
  SIGNAL clock25_signal : std_logic;

  -- Resolución VGA
  CONSTANT VGA_W : integer := 640;
  CONSTANT VGA_H : integer := 400;

  -- Tamaño del pájaro
  CONSTANT BIRD_W : integer := 34;
  CONSTANT BIRD_H : integer := 24;

  -- Coordenadas del pájaro (centrado)
  CONSTANT BIRD_X : integer := (VGA_W - BIRD_W) / 2;  -- 304
  CONSTANT BIRD_Y : integer := (VGA_H - BIRD_H) / 2;  -- 228

  -- Coordenadas de la tubería
  CONSTANT PIPE_X : integer := 500; -- posición horizontal
  CONSTANT PIPE_CENTER : integer := 240; -- centro del hueco (vertical)

BEGIN
  ----------------------------------------------------------------
  -- Instancia del controlador VGA
  ----------------------------------------------------------------
  u_vga : vga_driver
    PORT MAP (
      clock       => clock,
      row         => row,
      column      => column,
      H           => H,
      V           => V,
      frame_flag  => OPEN
    );

  ----------------------------------------------------------------
  -- Instancia del sprite del pájaro
  ----------------------------------------------------------------
  u_bird : ENTITY work.bird_sprite
    PORT MAP (
      clk         => clock,
      row         => row,
      column      => column,
      x_pos       => std_logic_vector(to_unsigned(BIRD_X, 10)),
      y_pos       => std_logic_vector(to_unsigned(BIRD_Y, 10)),
      pixel_data  => bird_rgb,
      visible     => bird_visible
    );

  ----------------------------------------------------------------
  -- Instancia del sprite de la tubería
  ----------------------------------------------------------------
  u_pipe : ENTITY work.pipe_sprite
    PORT MAP (
      clk         => clock,
      row         => row,
      column      => column,
      x_pos       => std_logic_vector(to_unsigned(PIPE_X, 10)),
      center      => std_logic_vector(to_unsigned(PIPE_CENTER, 10)),
      pixel_data  => pipe_rgb,
      visible     => pipe_visible
    );

  ----------------------------------------------------------------
  -- Combinación de sprites (prioridad: pájaro > tubería > fondo)
  ----------------------------------------------------------------
  
  
  process(clock)
  begin
    if rising_edge(clock) then
      if bird_visible = '1' then
        R <= bird_rgb(11 downto 8);
        G <= bird_rgb(7 downto 4);
        B <= bird_rgb(3 downto 0);
      elsif pipe_visible = '1' then
        R <= pipe_rgb(11 downto 8);
        G <= pipe_rgb(7 downto 4);
        B <= pipe_rgb(3 downto 0);
      else
        R <= (others => '0');  -- fondo negro
        G <= (others => '0');
        B <= (others => '0');
      end if;
    end if;
  end process;

END ARCHITECTURE;
------------------------------------------------------------


