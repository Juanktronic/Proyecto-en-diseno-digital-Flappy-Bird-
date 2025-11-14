LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY game IS
  PORT(
    clock      : IN  std_logic;
    btn_saltar : IN  std_logic;
    R, G, B    : OUT std_logic_vector(3 DOWNTO 0);
    H, V       : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF game IS
  SIGNAL PLLclk        : std_logic;
  SIGNAL row           : std_logic_vector(9 DOWNTO 0);
  SIGNAL column        : std_logic_vector(9 DOWNTO 0);
  SIGNAL frame_tick    : std_logic;
  SIGNAL bird_rgb      : std_logic_vector(11 DOWNTO 0);
  SIGNAL bird_visible  : std_logic;
  SIGNAL bird_x_pos    : std_logic_vector(9 DOWNTO 0);
  SIGNAL bird_y_pos    : std_logic_vector(9 DOWNTO 0);
  SIGNAL debounced_btn : std_logic;
  SIGNAL collision     : std_logic := '0';
  
  -- Máquina de estados
  TYPE state IS (Start, Playing, GameOver);
  SIGNAL pr_state, nx_state : state := Start;
  
    -- Señales de score
  SIGNAL score_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL score_visible : std_logic;
  SIGNAL score_value   : unsigned(6 DOWNTO 0);  -- score actual (0-99)
  SIGNAL best_score    : unsigned(6 DOWNTO 0);  -- best score (0-99)

  -- Codificación de estados como std_logic_vector
  SIGNAL state_encoded : std_logic_vector(1 DOWNTO 0);
  CONSTANT ST_START    : std_logic_vector(1 DOWNTO 0) := "00";
  CONSTANT ST_PLAYING  : std_logic_vector(1 DOWNTO 0) := "01";
  CONSTANT ST_GAMEOVER : std_logic_vector(1 DOWNTO 0) := "10";
  SIGNAL start_state : std_logic;

  
   -- Constantes para posición del score
  CONSTANT SCORE_X : integer := 270;  -- Centrado aproximadamente (320 - 38)
  CONSTANT SCORE_Y : integer := 30;   -- Cerca del tope
  
  CONSTANT BEST_SCORE_X : integer := 469;  
  CONSTANT BEST_SCORE_Y : integer := 228;

  -- Último score: misma X del best_score, un poco más abajo
  CONSTANT LAST_SCORE_X : integer := BEST_SCORE_X;
  CONSTANT LAST_SCORE_Y : integer := 300;  -- por ejemplo BEST_SCORE_Y + 44


  
  SIGNAL R_s, G_s, B_s : std_logic_vector(3 DOWNTO 0) := (others=>'0');
  CONSTANT BIRD_X : integer := 100;

  SIGNAL px_x   : std_logic_vector(10 DOWNTO 0);
  SIGNAL px_c   : std_logic_vector(9 DOWNTO 0);
  SIGNAL px_act : std_logic;
  SIGNAL pipe_rgb : std_logic_vector(11 DOWNTO 0);
  SIGNAL pipe_vis : std_logic;
  SIGNAL pipe_gen : std_logic;
  
BEGIN
  u_pll : ENTITY work.PLL_25_175Mhz
    PORT MAP ( areset=>'0', inclk0=>clock, c0=>PLLclk );

  u_vga : ENTITY work.vga_driver
    PORT MAP (
      clock       => PLLclk,
      row         => row,
      column      => column,
      H           => H,
      V           => V,
      frame_flag  => frame_tick
    );

  btn_i : ENTITY work.btn_debouncer
    GENERIC MAP(
      N           => 20,
      CLOCK_HZ    => 25175000,
      DEBOUNCE_MS => 6
    )
    PORT MAP(
      clock   => PLLclk,
      in_btn  => NOT btn_saltar,
      out_btn => debounced_btn
    );

  -- Codificar el estado actual
  state_encoded <= ST_START    WHEN pr_state = Start ELSE
                   ST_PLAYING  WHEN pr_state = Playing ELSE
                   ST_GAMEOVER WHEN pr_state = GameOver ELSE
                   ST_START;

  u_bird_movement : ENTITY work.bird_movement
    PORT MAP (
      clk        => clock,
      Frame_tick => frame_tick,
      btn_saltar => debounced_btn,
      game_state => state_encoded,
      bird_y_pos => bird_y_pos
    );

  u_score_counter : ENTITY work.score_counter
  GENERIC MAP(
    BIRD_X     => BIRD_X,
    PIPE_WIDTH => 56
  )
  PORT MAP(
    clk        => PLLclk,
    frame_tick => frame_tick,
    game_state => state_encoded,
    pipe_x     => px_x,
	 best_score => best_score,
    score      => score_value
  );

	-- Score Display: Shows the score on screen
  u_scores : ENTITY work.scores_sprite
    PORT MAP(
      clk         => PLLclk,
      row         => row,
      column      => column,
      score_cur   => score_value,   -- el mismo de score_counter
      best_score  => best_score,    -- el que sale de score_counter
      start_state => start_state,   -- tu señal de máquina de estados
      pixel_data  => score_rgb,
      visible     => score_visible
    );


  bird_x_pos <= std_logic_vector(to_unsigned(BIRD_X, 10));

  u_bird : ENTITY work.bird_sprite
    PORT MAP (
      clk         => PLLclk,
      row         => row,
      column      => column,
      enable      => '1',
      x_pos       => bird_x_pos,
      y_pos       => bird_y_pos,
      pixel_data  => bird_rgb,
      visible     => bird_visible
    );

  u_pipes_move : ENTITY work.pipe_movement
    PORT MAP(
      clk          => PLLclk,
      Frame_tick   => frame_tick,
      game_state   => state_encoded, 
      column       => column,
      pipe_x_pos   => px_x,
      pipe_center  => px_c,
      pipe_active  => px_act,
      pipe_gen     => pipe_gen
    );

  u_pipe : ENTITY work.pipe_sprite
    PORT MAP(
      clk        => PLLclk,
      row        => row,
      column     => column,
      x_pos      => px_x,
      center     => px_c,
      pixel_data => pipe_rgb,
      visible    => pipe_vis
    );

  u_collision : ENTITY work.collision_mngr
    PORT MAP(
      clk           => PLLclk,
      frame_tick    => frame_tick,
      bird_visible  => bird_visible,
      pipe_visible  => pipe_vis,
      collision_px  => OPEN,
      collision_frm => collision
    );

  u_color_mngr : ENTITY work.color_mngr
  GENERIC MAP(
    SPR_LAT => 1,
    BIRD_W  => 34,
    BIRD_H  => 24
  )
  PORT MAP(
    clk                 => PLLclk,
    row                 => row,
    column              => column,
    bird_x_pos          => bird_x_pos,
    bird_y_pos          => bird_y_pos,
    bird_rgb            => bird_rgb,
    bird_visible        => bird_visible,
    pipe_rgb            => pipe_rgb,
    pipe_visible        => pipe_vis,
    pipe_active         => px_act,
    score_rgb           => score_rgb,      -- del scores_sprite
    score_visible       => score_visible,  -- del scores_sprite
    R                   => R_s,
    G                   => G_s,
    B                   => B_s
  );

  PROCESS(PLLclk)
  BEGIN
    IF rising_edge(PLLclk) THEN
      pr_state <= nx_state;
    END IF;
  END PROCESS;

  -- Lógica de transición de estados
  PROCESS(debounced_btn, collision, pr_state)
  BEGIN
    start_state <= '0';
    nx_state <= pr_state;
    CASE pr_state IS
      WHEN Start =>
			start_state <= '1';
			IF debounced_btn = '1' THEN
				 nx_state <= Playing;
				 
			ELSE
				 nx_state <= Start;
			END IF;
      WHEN Playing =>
			IF collision = '1' THEN
				nx_state <= GameOver;
			ELSE
				nx_state <= Playing;
			END IF;
      WHEN GameOver =>
			
			IF debounced_btn = '1' THEN
				nx_state <= Start;
			ELSE
				nx_state <= GameOver;
			END IF;
    END CASE;
  END PROCESS;
 
  R <= R_s;
  G <= G_s;
  B <= B_s;
  
END ARCHITECTURE;