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
  -- Señales para "BEST"
  SIGNAL best_text_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL best_text_visible : std_logic;
  SIGNAL best_text_addr    : std_logic_vector(11 DOWNTO 0);
  SIGNAL best_rom_data     : std_logic_vector(3 DOWNTO 0);
  
  -- Señales para "SCORE:" (superior)
  SIGNAL score_text1_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL score_text1_visible : std_logic;
  SIGNAL score_text1_addr    : std_logic_vector(12 DOWNTO 0);
  SIGNAL score_text1_data    : std_logic_vector(3 DOWNTO 0);
  
  -- Señales para "LAST"
  SIGNAL last_text_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL last_text_visible : std_logic;
  SIGNAL last_text_addr    : std_logic_vector(11 DOWNTO 0);
  SIGNAL last_rom_data     : std_logic_vector(3 DOWNTO 0);
  
  -- Señales para "SCORE:" (inferior)
  SIGNAL score_text2_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL score_text2_visible : std_logic;
  SIGNAL score_text2_addr    : std_logic_vector(12 DOWNTO 0);
  SIGNAL score_text2_data    : std_logic_vector(3 DOWNTO 0);
  
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
  SIGNAL start_state   : std_logic;
  SIGNAL gameover_state: std_logic;

  
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
  -- Posiciones de los textos BEST/LAST/SCORE
  CONSTANT BEST_X      : integer := 220;
  CONSTANT BEST_Y      : integer := 195;
  CONSTANT BEST_W      : integer := 100;
  
  CONSTANT SCORE1_X    : integer := 330;
  CONSTANT SCORE1_Y    : integer := 195;
  CONSTANT SCORE1_W    : integer := 130;
  
  CONSTANT BEST_NUM_X  : integer := 475;
  CONSTANT BEST_NUM_Y  : integer := 198;
  
  CONSTANT LAST_X      : integer := 220;
  CONSTANT LAST_Y      : integer := 265;
  CONSTANT LAST_W      : integer := 100;
  
  CONSTANT SCORE2_X    : integer := 330;
  CONSTANT SCORE2_Y    : integer := 265;
  
  CONSTANT LAST_NUM_X  : integer := 475;
  CONSTANT LAST_NUM_Y  : integer := 268;

  SIGNAL px_x   : std_logic_vector(10 DOWNTO 0);
  SIGNAL px_c   : std_logic_vector(9 DOWNTO 0);
  SIGNAL px_act : std_logic;
  SIGNAL pipe_rgb : std_logic_vector(11 DOWNTO 0);
  SIGNAL pipe_vis : std_logic;
  SIGNAL pipe_gen : std_logic;
  SIGNAL floor_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL floor_visible : std_logic;
  SIGNAL gameover_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL gameover_visible : std_logic;
  
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


  u_scores : ENTITY work.scores_sprite
    PORT MAP(
      clk         => PLLclk,
      row         => row,
      column      => column,
      score_cur   => score_value,   
      best_score  => best_score,   
      start_state => start_state,   
      pixel_data  => score_rgb,
      visible     => score_visible
    );
-- ROM para "BEST"
  u_rom_best : ENTITY work.rom_best
    PORT MAP(
      clk    => PLLclk,
      r_addr => best_text_addr,
      r_data => best_rom_data
    );
  
  -- Sprite "BEST"
  u_best_text : ENTITY work.first_text_sprite
    GENERIC MAP(
      X_POS => BEST_X,
      Y_POS => BEST_Y
    )
    PORT MAP(
      clk        => PLLclk,
      row        => row,
      column     => column,
      enable     => start_state,
      rom_data   => best_rom_data,
      rom_addr   => best_text_addr,
      pixel_data => best_text_rgb,
      visible    => best_text_visible
    );
  
  -- ROM para "SCORE:" (compartida)
  u_rom_score1 : ENTITY work.rom_score1
    PORT MAP(
      clk    => PLLclk,
      r_addr => score_text1_addr,
      r_data => score_text1_data
    );
  
  -- Sprite "SCORE:" (superior)
  u_score_text1 : ENTITY work.second_text_sprite
    GENERIC MAP(
      X_POS => SCORE1_X,
      Y_POS => SCORE1_Y
    )
    PORT MAP(
      clk        => PLLclk,
      row        => row,
      column     => column,
      enable     => start_state,
      rom_data   => score_text1_data,
      rom_addr   => score_text1_addr,
      pixel_data => score_text1_rgb,
      visible    => score_text1_visible
    );
  
  -- ROM para "LAST"
  u_rom_last : ENTITY work.rom_last
    PORT MAP(
      clk    => PLLclk,
      r_addr => last_text_addr,
      r_data => last_rom_data
    );
  
  -- Sprite "LAST"
  u_last_text : ENTITY work.first_text_sprite
    GENERIC MAP(
      X_POS => LAST_X,
      Y_POS => LAST_Y
    )
    PORT MAP(
      clk        => PLLclk,
      row        => row,
      column     => column,
      enable     => start_state,
      rom_data   => last_rom_data,
      rom_addr   => last_text_addr,
      pixel_data => last_text_rgb,
      visible    => last_text_visible
    );
  
  -- ROM para "SCORE:" (inferior)
  u_rom_score2 : ENTITY work.rom_score1
    PORT MAP(
      clk    => PLLclk,
      r_addr => score_text2_addr,
      r_data => score_text2_data
    );
  
  -- Sprite "SCORE:" (inferior)
  u_score_text2 : ENTITY work.second_text_sprite
    GENERIC MAP(
      X_POS => SCORE2_X,
      Y_POS => SCORE2_Y
    )
    PORT MAP(
      clk        => PLLclk,
      row        => row,
      column     => column,
      enable     => start_state,
      rom_data   => score_text2_data,
      rom_addr   => score_text2_addr,
      pixel_data => score_text2_rgb,
      visible    => score_text2_visible
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

	 u_floor : ENTITY work.floor_sprite
  PORT MAP(
    clk        => PLLclk,
    row        => row,
    column     => column,
    pixel_data => floor_rgb,
    visible    => floor_visible
  );
  
  u_gameover : ENTITY work.game_over_sprite
  
  PORT MAP(
    clk        => PLLclk,
    row        => row,
    column     => column,
    pixel_data => gameover_rgb,
    visible    => gameover_visible
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
    floor_rgb           => floor_rgb,
    floor_visible       => floor_visible,
    gameover_rgb        => gameover_rgb,
    gameover_visible    => gameover_visible,
    score_rgb           => score_rgb,
    score_visible       => score_visible,
    best_text_rgb       => best_text_rgb,
    best_text_visible   => best_text_visible,
    score_text1_rgb     => score_text1_rgb,
    score_text1_visible => score_text1_visible,
    last_text_rgb       => last_text_rgb,
    last_text_visible   => last_text_visible,
    score_text2_rgb     => score_text2_rgb,
    score_text2_visible => score_text2_visible,
    start               => start_state,
	 gameover            => gameover_state,
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
	 gameover_state <= '0';
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
			gameover_state <= '1';
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