LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pipe_movement IS
  PORT(
    clk          : IN  std_logic;
    Frame_tick   : IN  std_logic;
    game_state   : IN  std_logic_vector(1 DOWNTO 0); 
    column       : IN  std_logic_vector(9 DOWNTO 0);

    pipe_x_pos   : OUT std_logic_vector(10 DOWNTO 0);
    pipe_center  : OUT std_logic_vector(9 DOWNTO 0);
    pipe_active  : OUT std_logic;

    pipe_gen     : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF pipe_movement IS
  CONSTANT PIPE_WIDTH     : integer := 56;
  CONSTANT GAP_PIXELS     : integer := 200;
  CONSTANT PITCH_PIXELS   : integer := PIPE_WIDTH + GAP_PIXELS;

  CONSTANT PIPE_SPEED     : integer := 2;
  CONSTANT PIPE_START_X   : integer := 640;
  CONSTANT PIPE_RESET_X   : integer := -PIPE_WIDTH;
  CONSTANT MAX_PIPES      : integer := 4;

  CONSTANT CENTER_MIN     : integer := 110;
  CONSTANT CENTER_MAX     : integer := 330;

  -- Estados del juego
  CONSTANT ST_START    : std_logic_vector(1 DOWNTO 0) := "00";
  CONSTANT ST_PLAYING  : std_logic_vector(1 DOWNTO 0) := "01";
  CONSTANT ST_GAMEOVER : std_logic_vector(1 DOWNTO 0) := "10";

  TYPE pipe_array IS ARRAY (0 TO MAX_PIPES-1) OF signed(15 DOWNTO 0);
  SIGNAL pipe_x_reg      : pipe_array := (OTHERS => to_signed(PIPE_RESET_X, 16));
  SIGNAL pipe_center_reg : pipe_array := (OTHERS => to_signed(240, 16));
  SIGNAL pipe_act_reg    : std_logic_vector(MAX_PIPES-1 DOWNTO 0) := (OTHERS => '0');

  CONSTANT SPAWN_FRAMES : integer := PITCH_PIXELS / PIPE_SPEED;
  SIGNAL   spawn_cnt_reg : integer range 0 to SPAWN_FRAMES := 0;
  SIGNAL   first_spawn_reg : std_logic := '1';
  SIGNAL   spawn_pulse_reg : std_logic := '0';

  SIGNAL lfsr_reg  : std_logic_vector(15 DOWNTO 0) := x"ACE1";
  
  -- Detectar transición a Playing (para reset)
  SIGNAL state_prev : std_logic_vector(1 DOWNTO 0) := ST_START;
  SIGNAL entering_playing : std_logic;

  -- Señales de control derivadas del estado
  SIGNAL enable_movement : std_logic;
  SIGNAL enable_spawn    : std_logic;
  SIGNAL do_reset        : std_logic;

  -- next
  SIGNAL feedback      : std_logic;
  SIGNAL lfsr_next     : std_logic_vector(15 DOWNTO 0);
  SIGNAL rand10        : unsigned(9 DOWNTO 0);
  SIGNAL new_center_i  : integer range 0 to 511;

  SIGNAL free0, free1, free2, free3 : std_logic;
  SIGNAL can_spawn, sel0, sel1, sel2, sel3, spawned : std_logic;

  SIGNAL x0_move, x1_move, x2_move, x3_move : signed(15 DOWNTO 0);
  SIGNAL x0_clip, x1_clip, x2_clip, x3_clip : signed(15 DOWNTO 0);
  SIGNAL act0_mv, act1_mv, act2_mv, act3_mv : std_logic;

  SIGNAL pipe_x_n0, pipe_x_n1, pipe_x_n2, pipe_x_n3 : signed(15 DOWNTO 0);
  SIGNAL pipe_c_n0, pipe_c_n1, pipe_c_n2, pipe_c_n3 : signed(15 DOWNTO 0);
  SIGNAL pipe_a_n     : std_logic_vector(3 DOWNTO 0);
  SIGNAL spawn_cnt_dec : integer range 0 to SPAWN_FRAMES;
  SIGNAL spawn_cnt_n   : integer range 0 to SPAWN_FRAMES;
  SIGNAL first_spawn_n : std_logic;
  SIGNAL spawn_pulse_n : std_logic;

  -- selección por columna (combinacional)
  SIGNAL col_i     : integer;
  SIGNAL x0_i, x1_i, x2_i, x3_i : integer;
  SIGNAL in0, in1, in2, in3 : std_logic;
  SIGNAL use0, use1, use2, use3 : std_logic;
  SIGNAL sel_x   : signed(15 DOWNTO 0);
  SIGNAL sel_c   : signed(15 DOWNTO 0);
  SIGNAL sel_act : std_logic;
BEGIN
  -- Detectar entrada a Playing (para resetear tuberías)
  entering_playing <= '1' WHEN (game_state = ST_PLAYING AND state_prev /= ST_PLAYING) ELSE '0';

  -- Control según estado del juego
  enable_movement <= '1' WHEN game_state = ST_PLAYING ELSE '0';
  enable_spawn    <= '1' WHEN game_state = ST_PLAYING ELSE '0';
  do_reset        <= entering_playing;

  -- LFSR / spawn
  feedback  <= lfsr_reg(15) XOR lfsr_reg(13) XOR lfsr_reg(12) XOR lfsr_reg(10);
  lfsr_next <= lfsr_reg(14 DOWNTO 0) & feedback;
  rand10    <= unsigned(lfsr_next(9 DOWNTO 0));
  new_center_i <= CENTER_MIN + (to_integer(rand10) MOD (CENTER_MAX - CENTER_MIN + 1));

  free0 <= NOT pipe_act_reg(0);
  free1 <= NOT pipe_act_reg(1);
  free2 <= NOT pipe_act_reg(2);
  free3 <= NOT pipe_act_reg(3);

  can_spawn <= '1' WHEN (enable_spawn = '1') AND
                         ((spawn_cnt_reg = 0) OR (first_spawn_reg = '1')) AND
                         (free0 = '1' OR free1 = '1' OR free2 = '1' OR free3 = '1')
               ELSE '0';

  sel0 <= '1' WHEN (can_spawn = '1' AND free0 = '1') ELSE '0';
  sel1 <= '1' WHEN (can_spawn = '1' AND free0 = '0' AND free1 = '1') ELSE '0';
  sel2 <= '1' WHEN (can_spawn = '1' AND free0 = '0' AND free1 = '0' AND free2 = '1') ELSE '0';
  sel3 <= '1' WHEN (can_spawn = '1' AND free0 = '0' AND free1 = '0' AND free2 = '0' AND free3 = '1') ELSE '0';
  spawned <= sel0 OR sel1 OR sel2 OR sel3;

  x0_move <= pipe_x_reg(0) - to_signed(PIPE_SPEED, 16) WHEN (pipe_act_reg(0) = '1' AND enable_movement = '1') 
             ELSE pipe_x_reg(0);
  x1_move <= pipe_x_reg(1) - to_signed(PIPE_SPEED, 16) WHEN (pipe_act_reg(1) = '1' AND enable_movement = '1') 
             ELSE pipe_x_reg(1);
  x2_move <= pipe_x_reg(2) - to_signed(PIPE_SPEED, 16) WHEN (pipe_act_reg(2) = '1' AND enable_movement = '1') 
             ELSE pipe_x_reg(2);
  x3_move <= pipe_x_reg(3) - to_signed(PIPE_SPEED, 16) WHEN (pipe_act_reg(3) = '1' AND enable_movement = '1') 
             ELSE pipe_x_reg(3);

  x0_clip <= to_signed(PIPE_RESET_X,16) WHEN x0_move < to_signed(PIPE_RESET_X,16) ELSE x0_move;
  x1_clip <= to_signed(PIPE_RESET_X,16) WHEN x1_move < to_signed(PIPE_RESET_X,16) ELSE x1_move;
  x2_clip <= to_signed(PIPE_RESET_X,16) WHEN x2_move < to_signed(PIPE_RESET_X,16) ELSE x2_move;
  x3_clip <= to_signed(PIPE_RESET_X,16) WHEN x3_move < to_signed(PIPE_RESET_X,16) ELSE x3_move;

  act0_mv <= '0' WHEN x0_move < to_signed(PIPE_RESET_X,16) ELSE pipe_act_reg(0);
  act1_mv <= '0' WHEN x1_move < to_signed(PIPE_RESET_X,16) ELSE pipe_act_reg(1);
  act2_mv <= '0' WHEN x2_move < to_signed(PIPE_RESET_X,16) ELSE pipe_act_reg(2);
  act3_mv <= '0' WHEN x3_move < to_signed(PIPE_RESET_X,16) ELSE pipe_act_reg(3);

  pipe_x_n0 <= to_signed(PIPE_START_X,16) WHEN sel0 = '1' ELSE x0_clip;
  pipe_x_n1 <= to_signed(PIPE_START_X,16) WHEN sel1 = '1' ELSE x1_clip;
  pipe_x_n2 <= to_signed(PIPE_START_X,16) WHEN sel2 = '1' ELSE x2_clip;
  pipe_x_n3 <= to_signed(PIPE_START_X,16) WHEN sel3 = '1' ELSE x3_clip;

  pipe_c_n0 <= to_signed(new_center_i,16) WHEN sel0 = '1' ELSE pipe_center_reg(0);
  pipe_c_n1 <= to_signed(new_center_i,16) WHEN sel1 = '1' ELSE pipe_center_reg(1);
  pipe_c_n2 <= to_signed(new_center_i,16) WHEN sel2 = '1' ELSE pipe_center_reg(2);
  pipe_c_n3 <= to_signed(new_center_i,16) WHEN sel3 = '1' ELSE pipe_center_reg(3);

  pipe_a_n(0) <= '1' WHEN sel0 = '1' ELSE act0_mv;
  pipe_a_n(1) <= '1' WHEN sel1 = '1' ELSE act1_mv;
  pipe_a_n(2) <= '1' WHEN sel2 = '1' ELSE act2_mv;
  pipe_a_n(3) <= '1' WHEN sel3 = '1' ELSE act3_mv;

  spawn_cnt_dec <= spawn_cnt_reg - 1 WHEN (spawn_cnt_reg > 0 AND enable_movement = '1') ELSE spawn_cnt_reg;
  spawn_cnt_n   <= SPAWN_FRAMES WHEN spawned = '1' ELSE spawn_cnt_dec;
  first_spawn_n <= '0' WHEN spawned = '1' ELSE first_spawn_reg;
  spawn_pulse_n <= '1' WHEN spawned = '1' ELSE '0';

  PROCESS(Frame_tick)
  BEGIN
    IF rising_edge(Frame_tick) THEN
      -- Actualizar detector de estado
      state_prev <= game_state;
      
      -- El LFSR siempre avanza para mantener aleatoriedad
      lfsr_reg <= lfsr_next;

      -- Si estamos en Start, mantener todo desactivado
      IF game_state = ST_START THEN
        pipe_x_reg(0) <= to_signed(PIPE_RESET_X, 16);
        pipe_x_reg(1) <= to_signed(PIPE_RESET_X, 16);
        pipe_x_reg(2) <= to_signed(PIPE_RESET_X, 16);
        pipe_x_reg(3) <= to_signed(PIPE_RESET_X, 16);
        
        pipe_center_reg(0) <= to_signed(240, 16);
        pipe_center_reg(1) <= to_signed(240, 16);
        pipe_center_reg(2) <= to_signed(240, 16);
        pipe_center_reg(3) <= to_signed(240, 16);
        
        pipe_act_reg <= (OTHERS => '0');
        
        spawn_cnt_reg   <= 0;
        first_spawn_reg <= '1';
        spawn_pulse_reg <= '0';
        
      -- Si entramos a Playing, resetear todas las tuberías
      ELSIF do_reset = '1' THEN
        pipe_x_reg(0) <= to_signed(PIPE_RESET_X, 16);
        pipe_x_reg(1) <= to_signed(PIPE_RESET_X, 16);
        pipe_x_reg(2) <= to_signed(PIPE_RESET_X, 16);
        pipe_x_reg(3) <= to_signed(PIPE_RESET_X, 16);
        
        pipe_center_reg(0) <= to_signed(240, 16);
        pipe_center_reg(1) <= to_signed(240, 16);
        pipe_center_reg(2) <= to_signed(240, 16);
        pipe_center_reg(3) <= to_signed(240, 16);
        
        pipe_act_reg <= (OTHERS => '0');
        
        spawn_cnt_reg   <= 0;
        first_spawn_reg <= '1';
        spawn_pulse_reg <= '0';
      ELSE
        -- Actualización normal (Playing) o congelada (GameOver)
        pipe_x_reg(0)   <= pipe_x_n0;
        pipe_x_reg(1)   <= pipe_x_n1;
        pipe_x_reg(2)   <= pipe_x_n2;
        pipe_x_reg(3)   <= pipe_x_n3;

        pipe_center_reg(0) <= pipe_c_n0;
        pipe_center_reg(1) <= pipe_c_n1;
        pipe_center_reg(2) <= pipe_c_n2;
        pipe_center_reg(3) <= pipe_c_n3;

        pipe_act_reg    <= pipe_a_n;

        spawn_cnt_reg   <= spawn_cnt_n;
        first_spawn_reg <= first_spawn_n;
        spawn_pulse_reg <= spawn_pulse_n;
      END IF;
    END IF;
  END PROCESS;

  -- selección por columna (no se solapan en X)
  col_i <= to_integer(unsigned(column));
  x0_i  <= to_integer(pipe_x_reg(0));
  x1_i  <= to_integer(pipe_x_reg(1));
  x2_i  <= to_integer(pipe_x_reg(2));
  x3_i  <= to_integer(pipe_x_reg(3));

  in0 <= '1' WHEN (pipe_act_reg(0)='1' AND col_i >= x0_i AND col_i < x0_i + PIPE_WIDTH) ELSE '0';
  in1 <= '1' WHEN (pipe_act_reg(1)='1' AND col_i >= x1_i AND col_i < x1_i + PIPE_WIDTH) ELSE '0';
  in2 <= '1' WHEN (pipe_act_reg(2)='1' AND col_i >= x2_i AND col_i < x2_i + PIPE_WIDTH) ELSE '0';
  in3 <= '1' WHEN (pipe_act_reg(3)='1' AND col_i >= x3_i AND col_i < x3_i + PIPE_WIDTH) ELSE '0';

  use0 <= in0;
  use1 <= '1' WHEN (in0='0' AND in1='1') ELSE '0';
  use2 <= '1' WHEN (in0='0' AND in1='0' AND in2='1') ELSE '0';
  use3 <= '1' WHEN (in0='0' AND in1='0' AND in2='0' AND in3='1') ELSE '0';

  sel_x   <= pipe_x_reg(0)    WHEN use0='1' ELSE
             pipe_x_reg(1)    WHEN use1='1' ELSE
             pipe_x_reg(2)    WHEN use2='1' ELSE
             pipe_x_reg(3)    WHEN use3='1' ELSE
             to_signed(-512,16);

  sel_c   <= pipe_center_reg(0) WHEN use0='1' ELSE
             pipe_center_reg(1) WHEN use1='1' ELSE
             pipe_center_reg(2) WHEN use2='1' ELSE
             pipe_center_reg(3) WHEN use3='1' ELSE
             to_signed(240,16);

  sel_act <= '1' WHEN (use0='1' OR use1='1' OR use2='1' OR use3='1') ELSE '0';

  pipe_x_pos  <= std_logic_vector(sel_x(10 DOWNTO 0));
  pipe_center <= std_logic_vector(sel_c(9 DOWNTO 0));
  pipe_active <= sel_act;
  pipe_gen    <= spawn_pulse_reg;
END ARCHITECTURE;