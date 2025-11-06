LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY movement IS
  GENERIC (
    CLOCK_HZ : integer := 50_000_000;
    HOLD_MS  : integer := 30
  );
  PORT(
    clk        : IN  std_logic;
    Frame_tick : IN  std_logic;
    btn_saltar : IN  std_logic;

    bird_y_pos : OUT std_logic_vector(9 DOWNTO 0);

    -- Posiciones de 4 tuberías
    pipe1_x_pos : OUT std_logic_vector(9 DOWNTO 0);
    pipe2_x_pos : OUT std_logic_vector(9 DOWNTO 0);
    pipe3_x_pos : OUT std_logic_vector(9 DOWNTO 0);
    pipe4_x_pos : OUT std_logic_vector(9 DOWNTO 0);

    -- Activas?
    pipe1_active : OUT std_logic;
    pipe2_active : OUT std_logic;
    pipe3_active : OUT std_logic;
    pipe4_active : OUT std_logic;

    pipe_gen   : OUT std_logic  -- pulso cuando nace una tubería
  );
END ENTITY;

ARCHITECTURE rtl OF movement IS
  ----------------------------------------------------------------
  -- Constantes de física
  ----------------------------------------------------------------
  CONSTANT GRAVITY        : integer := 1;
  CONSTANT GRAVITY_DIV    : integer := 2;
  CONSTANT JUMP_VELOCITY  : integer := -6;
  CONSTANT MAX_VELOCITY   : integer := 8;
  CONSTANT SCREEN_HEIGHT  : integer := 480;
  CONSTANT BIRD_HEIGHT    : integer := 24;

  ----------------------------------------------------------------
  -- Geometría de tubería y espaciado
  ----------------------------------------------------------------
  CONSTANT PIPE_WIDTH     : integer := 56;           -- ancho del sprite de tubería
  CONSTANT GAP_PIXELS     : integer := 104;          -- separación desde el final del ancho
  CONSTANT PITCH_PIXELS   : integer := PIPE_WIDTH + GAP_PIXELS; -- 160 px

  ----------------------------------------------------------------
  -- Movimiento de tuberías
  ----------------------------------------------------------------
  CONSTANT PIPE_SPEED     : integer := 2;            -- px/frame
  CONSTANT PIPE_START_X   : integer := 640;          -- entra justo fuera de pantalla
  CONSTANT PIPE_RESET_X   : integer := -PIPE_WIDTH;  -- sale cuando su cola cruza el borde
  CONSTANT MAX_PIPES      : integer := 4;

  ----------------------------------------------------------------
  -- Señales internas - Pájaro
  ----------------------------------------------------------------
  SIGNAL bird_y     : signed(15 DOWNTO 0) := to_signed(240, 16);
  SIGNAL bird_vel   : signed(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL grav_count : integer range 0 to GRAVITY_DIV := 0;

  ----------------------------------------------------------------
  -- Señales internas - Tuberías (4)
  ----------------------------------------------------------------
  TYPE pipe_array IS ARRAY (0 TO MAX_PIPES-1) OF signed(15 DOWNTO 0);
  SIGNAL pipe_x   : pipe_array := (OTHERS => to_signed(PIPE_RESET_X, 16));
  SIGNAL pipe_act : std_logic_vector(MAX_PIPES-1 DOWNTO 0) := (OTHERS => '0');

  ----------------------------------------------------------------
  -- Spawner por tiempo: una cada PITCH_PIXELS
  ----------------------------------------------------------------
  CONSTANT SPAWN_FRAMES : integer := PITCH_PIXELS / PIPE_SPEED; -- 160/2 = 80 frames
  SIGNAL   spawn_cnt    : integer range 0 to SPAWN_FRAMES := 0;  -- 0 => genera al inicio
  SIGNAL   spawn_pulse  : std_logic := '0';
  SIGNAL   can_spawn    : std_logic := '1';

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
  -- Física del pájaro
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
  -- Movimiento y spawner de 4 tuberías espaciadas 104 px (pitch 160)
  ----------------------------------------------------------------
  PROCESS(Frame_tick)
    VARIABLE next_x    : signed(15 DOWNTO 0);
    VARIABLE spawned   : std_logic;
  BEGIN
    IF rising_edge(Frame_tick) THEN
      -- Mover activas
      FOR i IN 0 TO MAX_PIPES-1 LOOP
        IF pipe_act(i) = '1' THEN
          next_x := pipe_x(i) - to_signed(PIPE_SPEED, 16);
          IF next_x < to_signed(PIPE_RESET_X, 16) THEN
            pipe_act(i) <= '0';
            pipe_x(i)   <= to_signed(PIPE_RESET_X, 16);
          ELSE
            pipe_x(i)   <= next_x;
          END IF;
        END IF;
      END LOOP;

      -- Temporizador de spawn (una cada PITCH_PIXELS)
      IF spawn_cnt > 0 THEN
        spawn_cnt <= spawn_cnt - 1;
      END IF;

      -- ¿Hay espacio suficiente respecto a la más reciente?
      can_spawn <= '1';
      FOR i IN 0 TO MAX_PIPES-1 LOOP
        IF pipe_act(i) = '1' THEN
          -- Exigir al menos un pitch de separación
          IF pipe_x(i) > to_signed(PIPE_START_X - PITCH_PIXELS, 16) THEN
            can_spawn <= '0';
          END IF;
        END IF;
      END LOOP;

      -- Nacimiento (hasta 4 activas)
      spawned := '0';
      IF (spawn_cnt = 0) AND (can_spawn = '1') THEN
        FOR i IN 0 TO MAX_PIPES-1 LOOP
          IF (pipe_act(i) = '0') AND (spawned = '0') THEN
            pipe_x(i)   <= to_signed(PIPE_START_X, 16);
            pipe_act(i) <= '1';
            spawned     := '1';
          END IF;
        END LOOP;
        spawn_cnt <= SPAWN_FRAMES; -- recarga para mantener pitch 160
      END IF;

      -- Pulso de generación
      IF spawned = '1' THEN
        spawn_pulse <= '1';
      ELSE
        spawn_pulse <= '0';
      END IF;
    END IF;
  END PROCESS;

  pipe_gen <= spawn_pulse;

  ----------------------------------------------------------------
  -- Salidas (sin recorte para salida gradual)
  ----------------------------------------------------------------
  bird_y_pos  <= std_logic_vector(resize(bird_y, 10));

  pipe1_x_pos <= std_logic_vector(resize(pipe_x(0), 10));
  pipe2_x_pos <= std_logic_vector(resize(pipe_x(1), 10));
  pipe3_x_pos <= std_logic_vector(resize(pipe_x(2), 10));
  pipe4_x_pos <= std_logic_vector(resize(pipe_x(3), 10));

  pipe1_active <= pipe_act(0);
  pipe2_active <= pipe_act(1);
  pipe3_active <= pipe_act(2);
  pipe4_active <= pipe_act(3);

END ARCHITECTURE;

