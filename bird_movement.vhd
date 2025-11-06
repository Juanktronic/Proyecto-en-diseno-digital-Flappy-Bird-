LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY bird_movement IS
  GENERIC (
    CLOCK_HZ : integer := 50_000_000;
    HOLD_MS  : integer := 30
  );
  PORT(
    clk        : IN  std_logic;
    Frame_tick : IN  std_logic;
    btn_saltar : IN  std_logic;
    bird_y_pos : OUT std_logic_vector(9 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF bird_movement IS
  ----------------------------------------------------------------
  -- Constantes de física
  ----------------------------------------------------------------
  CONSTANT GRAVITY        : integer := 1;
  CONSTANT GRAVITY_DIV    : integer := 2;
  CONSTANT JUMP_VELOCITY  : integer := -8;
  CONSTANT MAX_VELOCITY   : integer := 10;
  CONSTANT SCREEN_HEIGHT  : integer := 480;
  CONSTANT BIRD_HEIGHT    : integer := 24;

  ----------------------------------------------------------------
  -- Señales internas - Pájaro
  ----------------------------------------------------------------
  SIGNAL bird_y     : signed(15 DOWNTO 0) := to_signed(240, 16);
  SIGNAL bird_vel   : signed(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL grav_count : integer range 0 to GRAVITY_DIV := 0;

  ----------------------------------------------------------------
  -- Debounce + pulse stretcher
  ----------------------------------------------------------------
  CONSTANT HOLD_CYCLES : integer := (CLOCK_HZ / 1000) * HOLD_MS;
  SIGNAL btn_rise_clk  : std_logic := '0';
  SIGNAL btn_hold      : std_logic := '0';
  SIGNAL hold_cnt      : integer range 0 to HOLD_CYCLES := 0;
  SIGNAL btn_prev_ft   : std_logic := '0';
  SIGNAL btn_edge_ft   : std_logic := '0';

BEGIN
  ----------------------------------------------------------------
  -- Debouncer + estirador
  ----------------------------------------------------------------
  deb_i : ENTITY work.btn_debouncer
    GENERIC MAP (
      CLOCK_HZ    => CLOCK_HZ,
      DEBOUNCE_MS => 3
    )
    PORT MAP (
      clk      => clk,
      btn_raw  => btn_saltar,
      btn_rise => btn_rise_clk
    );

  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF btn_rise_clk = '1' THEN
        btn_hold <= '1';
        hold_cnt <= HOLD_CYCLES;
      ELSIF hold_cnt > 0 THEN
        hold_cnt <= hold_cnt - 1;
        IF hold_cnt = 1 THEN
          btn_hold <= '0';
        END IF;
      END IF;
    END IF;
  END PROCESS;

  PROCESS(Frame_tick)
  BEGIN
    IF rising_edge(Frame_tick) THEN
      IF (btn_hold = '1' AND btn_prev_ft = '0') THEN
        btn_edge_ft <= '1';
      ELSE
        btn_edge_ft <= '0';
      END IF;
      btn_prev_ft <= btn_hold;
    END IF;
  END PROCESS;

  ----------------------------------------------------------------
  -- Física del pájaro con gravedad suave
  ----------------------------------------------------------------
  PROCESS(Frame_tick)
    VARIABLE next_vel : signed(15 DOWNTO 0);
    VARIABLE next_y   : signed(15 DOWNTO 0);
  BEGIN
    IF rising_edge(Frame_tick) THEN
      next_vel := bird_vel;
      next_y   := bird_y;

      -- Gravedad cada GRAVITY_DIV frames
      IF grav_count = 0 THEN
        next_vel := bird_vel + to_signed(GRAVITY, 16);
        grav_count <= GRAVITY_DIV - 1;
      ELSE
        grav_count <= grav_count - 1;
      END IF;

      -- Limitar velocidad
      IF next_vel > to_signed(MAX_VELOCITY, 16) THEN
        next_vel := to_signed(MAX_VELOCITY, 16);
      ELSIF next_vel < to_signed(-MAX_VELOCITY, 16) THEN
        next_vel := to_signed(-MAX_VELOCITY, 16);
      END IF;

      -- Posición
      next_y := bird_y + next_vel;

      -- Suelo
      IF next_y > to_signed(SCREEN_HEIGHT - BIRD_HEIGHT, 16) THEN
        next_y   := to_signed(SCREEN_HEIGHT - BIRD_HEIGHT, 16);
        next_vel := (OTHERS => '0');
      END IF;

      -- Techo
      IF next_y < to_signed(0, 16) THEN
        next_y   := to_signed(0, 16);
        next_vel := (OTHERS => '0');
      END IF;

      -- Aplicar
      bird_y   <= next_y;
      bird_vel <= next_vel;

      -- Salto
      IF btn_edge_ft = '1' THEN
        bird_vel   <= to_signed(JUMP_VELOCITY, 16);
        grav_count <= GRAVITY_DIV - 1;
      END IF;
    END IF;
  END PROCESS;

  ----------------------------------------------------------------
  -- Salida
  ----------------------------------------------------------------
  bird_y_pos <= std_logic_vector(bird_y(9 DOWNTO 0))
                WHEN bird_y >= to_signed(0, 16) AND bird_y < to_signed(1024, 16)
                ELSE (OTHERS => '0');

END ARCHITECTURE;