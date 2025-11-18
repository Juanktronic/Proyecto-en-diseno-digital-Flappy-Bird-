LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY color_mngr IS
  GENERIC(
    SPR_LAT : integer := 1;
    BIRD_W  : integer := 34;
    BIRD_H  : integer := 24
  );
  PORT(
    clk               : IN  std_logic;
    row               : IN  std_logic_vector(9 DOWNTO 0);
    column            : IN  std_logic_vector(9 DOWNTO 0);
    bird_x_pos        : IN  std_logic_vector(9 DOWNTO 0);
    bird_y_pos        : IN  std_logic_vector(9 DOWNTO 0);
    bird_rgb          : IN  std_logic_vector(11 DOWNTO 0);
    bird_visible      : IN  std_logic;
    pipe_rgb          : IN  std_logic_vector(11 DOWNTO 0);
    pipe_visible      : IN  std_logic;
    pipe_active       : IN  std_logic;
    floor_rgb         : IN  std_logic_vector(11 DOWNTO 0);
    floor_visible     : IN  std_logic;
    gameover_rgb      : IN  std_logic_vector(11 DOWNTO 0);  
    gameover_visible  : IN  std_logic;                      
    score_rgb         : IN  std_logic_vector(11 DOWNTO 0);
    score_visible     : IN  std_logic;
	 best_text_rgb     : IN  std_logic_vector(11 DOWNTO 0);
    best_text_visible : IN  std_logic;
    score_text1_rgb   : IN  std_logic_vector(11 DOWNTO 0);
    score_text1_visible : IN  std_logic;
    last_text_rgb       : IN  std_logic_vector(11 DOWNTO 0);
    last_text_visible   : IN  std_logic;
    score_text2_rgb     : IN  std_logic_vector(11 DOWNTO 0);
    score_text2_visible : IN  std_logic;
    start             : IN  std_logic;
	 gameover          : IN std_logic;
    R, G, B           : OUT std_logic_vector(3 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF color_mngr IS
  SIGNAL x, y          : unsigned(9 DOWNTO 0);
  SIGNAL h_active      : std_logic;
  SIGNAL v_active      : std_logic;
  SIGNAL de_now        : std_logic;
  SIGNAL de_shift      : std_logic_vector(SPR_LAT DOWNTO 0);

  TYPE rgb_arr IS ARRAY (NATURAL RANGE <>) OF std_logic_vector(11 DOWNTO 0);
  TYPE bit_arr IS ARRAY (NATURAL RANGE <>) OF std_logic;

  SIGNAL score_rgb_sr  : rgb_arr(0 TO SPR_LAT);
  SIGNAL bird_rgb_sr   : rgb_arr(0 TO SPR_LAT);
  SIGNAL pipe_rgb_sr   : rgb_arr(0 TO SPR_LAT);
  SIGNAL floor_rgb_sr  : rgb_arr(0 TO SPR_LAT); 
  SIGNAL gameover_rgb_sr : rgb_arr(0 TO SPR_LAT);
  SIGNAL score_vis_sr  : bit_arr(0 TO SPR_LAT);
  SIGNAL bird_vis_sr   : bit_arr(0 TO SPR_LAT);
  SIGNAL pipe_vis_sr   : bit_arr(0 TO SPR_LAT);
  SIGNAL floor_vis_sr  : bit_arr(0 TO SPR_LAT);  
  SIGNAL pipe_act_sr   : bit_arr(0 TO SPR_LAT);
  SIGNAL gameover_vis_sr : bit_arr(0 TO SPR_LAT);
  SIGNAL best_text_rgb_sr    : rgb_arr(0 TO SPR_LAT);
  SIGNAL best_text_vis_sr    : bit_arr(0 TO SPR_LAT);
  SIGNAL score_text1_rgb_sr  : rgb_arr(0 TO SPR_LAT);
  SIGNAL score_text1_vis_sr  : bit_arr(0 TO SPR_LAT);
  SIGNAL last_text_rgb_sr    : rgb_arr(0 TO SPR_LAT);
  SIGNAL last_text_vis_sr    : bit_arr(0 TO SPR_LAT);
  SIGNAL score_text2_rgb_sr  : rgb_arr(0 TO SPR_LAT);
  SIGNAL score_text2_vis_sr  : bit_arr(0 TO SPR_LAT);
  
  -- Rectángulo de start
  SIGNAL score_bg_sr   : bit_arr(0 TO SPR_LAT);
  SIGNAL score_bg_now  : std_logic;
  SIGNAL gameover_rgb_now: rgb_arr(0 TO SPR_LAT);

  -- Kaki
  CONSTANT SCORE_BG    : std_logic_vector(11 DOWNTO 0) := x"874";
  
  CONSTANT SCORE_BG_X0 : integer := 180;
  CONSTANT SCORE_BG_X1 : integer := 580;
  CONSTANT SCORE_BG_Y0 : integer := 60;
  CONSTANT SCORE_BG_Y1 : integer := 360;
  
  SIGNAL start_state   : std_logic;
  SIGNAL gameover_state   : std_logic;
  SIGNAL rgb_mux       : std_logic_vector(11 DOWNTO 0);
  SIGNAL vis_any       : std_logic;

  -- Fondo azul claro
  CONSTANT BG_R : std_logic_vector(3 DOWNTO 0) := "0010";
  CONSTANT BG_G : std_logic_vector(3 DOWNTO 0) := "1010";
  CONSTANT BG_B : std_logic_vector(3 DOWNTO 0) := "1111";

BEGIN
  x <= unsigned(column);
  y <= unsigned(row);
  start_state <= start;
  h_active <= '1' WHEN x < 640 ELSE '0';
  v_active <= '1' WHEN y < 480 ELSE '0';
  de_now   <= h_active AND v_active;
  
  score_bg_now <= '1' WHEN (start_state = '1') AND
                           (x >= to_unsigned(SCORE_BG_X0, x'length)) AND
                           (x <  to_unsigned(SCORE_BG_X1, x'length)) AND
                           (y >= to_unsigned(SCORE_BG_Y0, y'length)) AND
                           (y <  to_unsigned(SCORE_BG_Y1, y'length))
                  ELSE '0';

  gameover_state <= gameover;
  
  
  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      de_shift(0)      <= de_now;

      score_rgb_sr(0)    <= score_rgb;
      bird_rgb_sr(0)     <= bird_rgb;
      pipe_rgb_sr(0)     <= pipe_rgb;
      floor_rgb_sr(0)    <= floor_rgb;
      gameover_rgb_sr(0) <= gameover_rgb;   
      best_text_rgb_sr(0)  <= best_text_rgb;
      score_text1_rgb_sr(0)<= score_text1_rgb;
      last_text_rgb_sr(0)  <= last_text_rgb;
      score_text2_rgb_sr(0)<= score_text2_rgb;
      score_vis_sr(0)    <= score_visible;
      bird_vis_sr(0)     <= bird_visible;
      pipe_vis_sr(0)     <= pipe_visible;
      floor_vis_sr(0)    <= floor_visible;
      gameover_vis_sr(0) <= gameover_visible; 
		best_text_vis_sr(0)  <= best_text_visible;
      score_text1_vis_sr(0)<= score_text1_visible;
      last_text_vis_sr(0)  <= last_text_visible;
      score_text2_vis_sr(0)<= score_text2_visible;
      pipe_act_sr(0)     <= pipe_active;
      score_bg_sr(0)     <= score_bg_now;
		

      FOR i IN 0 TO SPR_LAT-1 LOOP
        de_shift(i+1)      <= de_shift(i);

        score_rgb_sr(i+1)    <= score_rgb_sr(i);
        bird_rgb_sr(i+1)     <= bird_rgb_sr(i);
        pipe_rgb_sr(i+1)     <= pipe_rgb_sr(i);
        floor_rgb_sr(i+1)    <= floor_rgb_sr(i);
        gameover_rgb_sr(i+1) <= gameover_rgb_sr(i); 
		  best_text_rgb_sr(i+1)  <= best_text_rgb_sr(i);
        score_text1_rgb_sr(i+1)<= score_text1_rgb_sr(i);
        last_text_rgb_sr(i+1)  <= last_text_rgb_sr(i);
        score_text2_rgb_sr(i+1)<= score_text2_rgb_sr(i); 
        score_vis_sr(i+1)    <= score_vis_sr(i);
        bird_vis_sr(i+1)     <= bird_vis_sr(i);
        pipe_vis_sr(i+1)     <= pipe_vis_sr(i);
        floor_vis_sr(i+1)    <= floor_vis_sr(i);
        gameover_vis_sr(i+1) <= gameover_vis_sr(i); 
		  best_text_vis_sr(i+1)  <= best_text_vis_sr(i);
        score_text1_vis_sr(i+1)<= score_text1_vis_sr(i);
        last_text_vis_sr(i+1)  <= last_text_vis_sr(i);
        score_text2_vis_sr(i+1)<= score_text2_vis_sr(i);
        pipe_act_sr(i+1)     <= pipe_act_sr(i);
        score_bg_sr(i+1)     <= score_bg_sr(i); 
		  
      END LOOP;
    END IF;
  END PROCESS;
  
  -- Prioridad: gameover > score > fondo_score > bird > pipe > floor > fondo
  rgb_mux <= gameover_rgb_sr(SPR_LAT)    WHEN (gameover_vis_sr(SPR_LAT)    = '1' AND gameover_state = '1') ELSE
             best_text_rgb_sr(SPR_LAT)   WHEN best_text_vis_sr(SPR_LAT)   = '1' ELSE
             score_text1_rgb_sr(SPR_LAT) WHEN score_text1_vis_sr(SPR_LAT) = '1' ELSE
             last_text_rgb_sr(SPR_LAT)   WHEN last_text_vis_sr(SPR_LAT)   = '1' ELSE
             score_text2_rgb_sr(SPR_LAT) WHEN score_text2_vis_sr(SPR_LAT) = '1' ELSE
             score_rgb_sr(SPR_LAT)       WHEN score_vis_sr(SPR_LAT)       = '1' ELSE
             SCORE_BG                    WHEN score_bg_sr(SPR_LAT)        = '1' ELSE
             bird_rgb_sr(SPR_LAT)        WHEN bird_vis_sr(SPR_LAT)        = '1' ELSE
             pipe_rgb_sr(SPR_LAT)        WHEN (pipe_act_sr(SPR_LAT) = '1' AND pipe_vis_sr(SPR_LAT) = '1') ELSE
             floor_rgb_sr(SPR_LAT)       WHEN floor_vis_sr(SPR_LAT)       = '1' ELSE
             (OTHERS => '0');

  vis_any <= '1' WHEN (gameover_vis_sr(SPR_LAT)    = '1') OR
                      (best_text_vis_sr(SPR_LAT)   = '1') OR
                      (score_text1_vis_sr(SPR_LAT) = '1') OR
                      (last_text_vis_sr(SPR_LAT)   = '1') OR
                      (score_text2_vis_sr(SPR_LAT) = '1') OR
                      (score_vis_sr(SPR_LAT) = '1') OR
                      (score_bg_sr(SPR_LAT)  = '1') OR
                      (bird_vis_sr(SPR_LAT)  = '1') OR
                      ((pipe_act_sr(SPR_LAT) = '1') AND (pipe_vis_sr(SPR_LAT) = '1')) OR
                      (floor_vis_sr(SPR_LAT) = '1')
             ELSE '0';

  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF de_shift(SPR_LAT) = '1' THEN
        IF vis_any = '1' THEN
          R <= rgb_mux(11 DOWNTO 8);
          G <= rgb_mux(7  DOWNTO 4);
          B <= rgb_mux(3  DOWNTO 0);
        ELSE
          R <= BG_R;  G <= BG_G;  B <= BG_B;
        END IF;
      ELSE
        R <= (OTHERS => '0');
        G <= (OTHERS => '0');
        B <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;