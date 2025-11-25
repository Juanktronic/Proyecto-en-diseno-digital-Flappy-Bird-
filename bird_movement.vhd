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
    game_state : IN  std_logic_vector(1 DOWNTO 0); -- "00"=Start, "01"=Playing, "10"=GameOver
    bird_y_pos : OUT std_logic_vector(9 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF bird_movement IS
  -- Constantes de física
  CONSTANT GRAVITY        : integer := 1;
  CONSTANT GRAVITY_DIV    : integer := 2;
  CONSTANT JUMP_VELOCITY  : integer := -8;
  CONSTANT MAX_VELOCITY   : integer := 10;
  CONSTANT SCREEN_HEIGHT  : integer := 420;
  CONSTANT BIRD_HEIGHT    : integer := 24;
  CONSTANT CENTER_Y       : integer := 210;
  CONSTANT ZERO16         : signed(15 DOWNTO 0) := (OTHERS => '0');

  -- Estados del juego
  CONSTANT ST_START    : std_logic_vector(1 DOWNTO 0) := "00";
  CONSTANT ST_PLAYING  : std_logic_vector(1 DOWNTO 0) := "01";
  CONSTANT ST_GAMEOVER : std_logic_vector(1 DOWNTO 0) := "10";

  -- Registros de estado (Playing mode)
  SIGNAL bird_y_reg     : signed(15 DOWNTO 0) := to_signed(CENTER_Y, 16);
  SIGNAL bird_vel_reg   : signed(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL grav_cnt_reg   : integer range 0 to GRAVITY_DIV := 0;

  -- Registros de estado (Start mode - senoidal)
  SIGNAL sine_counter_reg : unsigned(7 DOWNTO 0) := (OTHERS => '0');

  -- Sincronización de entradas
  SIGNAL b_s1_reg, b_s2_reg, b_prev_reg     : std_logic := '0';
  SIGNAL ft_s1_reg, ft_s2_reg, ft_prev_reg  : std_logic := '0';
  SIGNAL pending_jump_reg                   : std_logic := '0';

  -- Señales combinacionales (next values)
  SIGNAL bird_y_n       : signed(15 DOWNTO 0);
  SIGNAL bird_vel_n     : signed(15 DOWNTO 0);
  SIGNAL grav_cnt_n     : integer range 0 to GRAVITY_DIV;
  SIGNAL sine_counter_n : unsigned(7 DOWNTO 0);
  SIGNAL sine_y_n       : signed(15 DOWNTO 0);

  -- Detección de eventos
  SIGNAL do_btn_edge : std_logic;
  SIGNAL do_ft_rise  : std_logic;

  -- Señales intermedias para física (Playing)
  SIGNAL grav_cnt_grav       : integer range 0 to GRAVITY_DIV;
  SIGNAL grav_cnt_after_jump : integer range 0 to GRAVITY_DIV;
  SIGNAL vel_grav            : signed(15 DOWNTO 0);
  SIGNAL vel_limited         : signed(15 DOWNTO 0);
  SIGNAL vel_after_jump      : signed(15 DOWNTO 0);
  SIGNAL vel_after_clip      : signed(15 DOWNTO 0);
  SIGNAL y_sum               : signed(15 DOWNTO 0);
  SIGNAL y_clamped           : signed(15 DOWNTO 0);

BEGIN

  -- Detección de flancos
  do_btn_edge <= '1' WHEN (b_s2_reg = '1' AND b_prev_reg = '0') ELSE '0';
  do_ft_rise  <= '1' WHEN (ft_s2_reg = '1' AND ft_prev_reg = '0') ELSE '0';

  
  grav_cnt_grav <= GRAVITY_DIV - 1 WHEN (do_ft_rise = '1' AND grav_cnt_reg = 0)
                   ELSE grav_cnt_reg - 1 WHEN (do_ft_rise = '1')
                   ELSE grav_cnt_reg;

  vel_grav <= bird_vel_reg + to_signed(GRAVITY, 16) 
              WHEN (do_ft_rise = '1' AND grav_cnt_reg = 0)
              ELSE bird_vel_reg;

  vel_limited <= to_signed(MAX_VELOCITY, 16)  
                 WHEN (vel_grav > to_signed(MAX_VELOCITY, 16)) 
                 ELSE to_signed(-MAX_VELOCITY, 16) 
                 WHEN (vel_grav < to_signed(-MAX_VELOCITY, 16)) 
                 ELSE vel_grav;

  vel_after_jump <= to_signed(JUMP_VELOCITY, 16) 
                    WHEN (do_ft_rise = '1' AND pending_jump_reg = '1')
                    ELSE vel_limited;
                    
  grav_cnt_after_jump <= GRAVITY_DIV - 1 
                         WHEN (do_ft_rise = '1' AND pending_jump_reg = '1')
                         ELSE grav_cnt_grav;

  y_sum <= bird_y_reg + vel_after_jump WHEN (do_ft_rise = '1') ELSE bird_y_reg;

  y_clamped <= to_signed(SCREEN_HEIGHT - BIRD_HEIGHT, 16) 
               WHEN (y_sum > to_signed(SCREEN_HEIGHT - BIRD_HEIGHT, 16)) 
               ELSE to_signed(0, 16) 
               WHEN (y_sum < to_signed(0, 16)) 
               ELSE y_sum;

  vel_after_clip <= ZERO16 
                    WHEN ((y_sum > to_signed(SCREEN_HEIGHT - BIRD_HEIGHT, 16)) OR 
                          (y_sum < to_signed(0, 16)))
                    ELSE vel_after_jump;

  sine_counter_n <= sine_counter_reg + 2 
                    WHEN (do_ft_rise = '1' AND game_state = ST_START) 
                    ELSE sine_counter_reg;

  PROCESS(sine_counter_reg)
    VARIABLE angle    : integer;
    VARIABLE sine_val : integer;
  BEGIN
    angle := to_integer(sine_counter_reg);
    
    IF angle < 64 THEN
      sine_val := (angle * 40) / 64;              -- Cuadrante 1: 0 → +40
    ELSIF angle < 128 THEN
      sine_val := 40 - ((angle - 64) * 40) / 64;  -- Cuadrante 2: +40 → 0
    ELSIF angle < 192 THEN
      sine_val := -((angle - 128) * 40) / 64;     -- Cuadrante 3: 0 → -40
    ELSE
      sine_val := -40 + ((angle - 192) * 40) / 64; -- Cuadrante 4: -40 → 0
    END IF;
    
    sine_y_n <= to_signed(CENTER_Y + sine_val, 16);
  END PROCESS;

  -- ========== FSM - LÓGICA DE PRÓXIMO ESTADO ==========
  
  PROCESS(game_state, y_clamped, vel_after_clip, grav_cnt_after_jump, 
          bird_y_reg, bird_vel_reg, grav_cnt_reg)
  BEGIN
    -- Valores por defecto
    bird_y_n   <= bird_y_reg;
    bird_vel_n <= bird_vel_reg;
    grav_cnt_n <= grav_cnt_reg;
    
    CASE game_state IS
      WHEN ST_START =>
        -- Modo Start: Reset a condiciones iniciales
        bird_y_n   <= to_signed(CENTER_Y, 16);
        bird_vel_n <= ZERO16;
        grav_cnt_n <= 0;

      WHEN ST_PLAYING =>
        -- Modo Playing: Actualizar con física
        bird_y_n   <= y_clamped;
        bird_vel_n <= vel_after_clip;
        grav_cnt_n <= grav_cnt_after_jump;

      WHEN ST_GAMEOVER =>
        -- Modo GameOver: Mantener valores actuales (congelado)
        bird_y_n   <= bird_y_reg;
        bird_vel_n <= bird_vel_reg;
        grav_cnt_n <= grav_cnt_reg;

      WHEN OTHERS =>
        bird_y_n   <= bird_y_reg;
        bird_vel_n <= bird_vel_reg;
        grav_cnt_n <= grav_cnt_reg;
    END CASE;
  END PROCESS;

  -- ========== SALIDA - POSICIÓN DEL PÁJARO ==========
  
  PROCESS(game_state, bird_y_n, sine_y_n)
    VARIABLE final_y : signed(15 DOWNTO 0);
  BEGIN
    -- Seleccionar fuente de posición según estado
    IF game_state = ST_START THEN
      final_y := sine_y_n;      -- Usar posición senoidal
    ELSE
      final_y := bird_y_n;      -- Usar posición de física
    END IF;

    -- Clampear y convertir a salida
    IF (final_y >= to_signed(0, 16) AND final_y < to_signed(1024, 16)) THEN
      bird_y_pos <= std_logic_vector(final_y(9 DOWNTO 0));
    ELSE
      bird_y_pos <= (OTHERS => '0');
    END IF;
  END PROCESS;

  -- ========== PROCESOS SECUENCIALES ==========
  
  -- Proceso 1: Actualizar registros de estado
  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      -- Actualizar estado de física
      bird_y_reg       <= bird_y_n;
      bird_vel_reg     <= bird_vel_n;
      grav_cnt_reg     <= grav_cnt_n;

      -- Actualizar contador senoidal
      sine_counter_reg <= sine_counter_n;

      -- Sincronización de botón (3 etapas para detección de flanco)
      b_s1_reg   <= btn_saltar;
      b_s2_reg   <= b_s1_reg;
      b_prev_reg <= b_s2_reg;

      -- Sincronización de frame tick (3 etapas para detección de flanco)
      ft_s1_reg   <= Frame_tick;
      ft_s2_reg   <= ft_s1_reg;
      ft_prev_reg <= ft_s2_reg;

      pending_jump_reg <= (pending_jump_reg OR do_btn_edge) AND (NOT do_ft_rise);
    END IF;
  END PROCESS;

END ARCHITECTURE;