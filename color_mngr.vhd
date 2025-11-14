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
    score_rgb         : IN  std_logic_vector(11 DOWNTO 0);
    score_visible     : IN  std_logic;

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

  SIGNAL score_vis_sr  : bit_arr(0 TO SPR_LAT);
  SIGNAL bird_vis_sr   : bit_arr(0 TO SPR_LAT);
  SIGNAL pipe_vis_sr   : bit_arr(0 TO SPR_LAT);
  SIGNAL pipe_act_sr   : bit_arr(0 TO SPR_LAT);

  SIGNAL rgb_mux       : std_logic_vector(11 DOWNTO 0);
  SIGNAL vis_any       : std_logic;

  CONSTANT BG_R : std_logic_vector(3 DOWNTO 0) := "0000";
  CONSTANT BG_G : std_logic_vector(3 DOWNTO 0) := "0000";
  CONSTANT BG_B : std_logic_vector(3 DOWNTO 0) := "0000";
BEGIN
  x <= unsigned(column);
  y <= unsigned(row);

  h_active <= '1' WHEN x < 640 ELSE '0';
  v_active <= '1' WHEN y < 480 ELSE '0';
  de_now   <= h_active AND v_active;

  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      de_shift(0)      <= de_now;

      score_rgb_sr(0)  <= score_rgb;
      bird_rgb_sr(0)   <= bird_rgb;
      pipe_rgb_sr(0)   <= pipe_rgb;

      score_vis_sr(0)  <= score_visible;
      bird_vis_sr(0)   <= bird_visible;
      pipe_vis_sr(0)   <= pipe_visible;
      pipe_act_sr(0)   <= pipe_active;

      FOR i IN 0 TO SPR_LAT-1 LOOP
        de_shift(i+1)      <= de_shift(i);

        score_rgb_sr(i+1)  <= score_rgb_sr(i);
        bird_rgb_sr(i+1)   <= bird_rgb_sr(i);
        pipe_rgb_sr(i+1)   <= pipe_rgb_sr(i);

        score_vis_sr(i+1)  <= score_vis_sr(i);
        bird_vis_sr(i+1)   <= bird_vis_sr(i);
        pipe_vis_sr(i+1)   <= pipe_vis_sr(i);
        pipe_act_sr(i+1)   <= pipe_act_sr(i);
      END LOOP;
    END IF;
  END PROCESS;

  -- Prioridad: score > bird > pipe
  rgb_mux <= score_rgb_sr(SPR_LAT)   WHEN score_vis_sr(SPR_LAT)   = '1' ELSE
             bird_rgb_sr(SPR_LAT)    WHEN bird_vis_sr(SPR_LAT)    = '1' ELSE
             pipe_rgb_sr(SPR_LAT)    WHEN (pipe_act_sr(SPR_LAT)   = '1' AND pipe_vis_sr(SPR_LAT) = '1') ELSE
             (OTHERS => '0');

  vis_any <= '1' WHEN (score_vis_sr(SPR_LAT) = '1') OR
                      (bird_vis_sr(SPR_LAT)  = '1') OR
                      ((pipe_act_sr(SPR_LAT) = '1') AND (pipe_vis_sr(SPR_LAT) = '1'))
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
