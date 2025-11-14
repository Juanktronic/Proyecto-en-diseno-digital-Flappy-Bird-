LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

--------------------------------------------------------------------------------
-- SCORE COUNTER: Tracks how many pipes the bird has passed
-- Increments score when pipe passes the bird's X position
--------------------------------------------------------------------------------
ENTITY score_counter IS
  GENERIC (
    BIRD_X     : integer := 100;  -- Bird's X position
    PIPE_WIDTH : integer := 56    -- Width of pipe
  );
  PORT(
    clk        : IN  std_logic;
    frame_tick : IN  std_logic;                    -- Pulse once per frame
    game_state : IN  std_logic_vector(1 DOWNTO 0); -- Game state
    pipe_x     : IN  std_logic_vector(10 DOWNTO 0);-- Pipe X position
    score      : OUT unsigned(6 DOWNTO 0);          -- Current score (0-99)
	 best_score : OUT unsigned(6 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF score_counter IS
  -- Game states (deben coincidir con tu definición)
  CONSTANT ST_START   : std_logic_vector(1 DOWNTO 0) := "00";
  CONSTANT ST_PLAYING : std_logic_vector(1 DOWNTO 0) := "01";
  CONSTANT ST_DEAD    : std_logic_vector(1 DOWNTO 0) := "10";
  
  -- Pipe position tracking
  SIGNAL pipe_x_int  : integer;
  SIGNAL pipe_x_prev : integer := 0;
  
  -- Score detection
  SIGNAL pipe_just_passed : std_logic;
  
  -- Counter signals
  SIGNAL counter_en   : std_logic;
  SIGNAL counter_out  : std_logic_vector(6 DOWNTO 0);
  SIGNAL counter_max  : std_logic_vector(6 DOWNTO 0);
  SIGNAL counter_rst  : std_logic;
  
  SIGNAL max_score : unsigned(6 DOWNTO 0) := (OTHERS => '0');

  -- Para detectar transición Start -> Playing
  SIGNAL game_state_prev : std_logic_vector(1 DOWNTO 0) := ST_START;
  SIGNAL new_game_pulse  : std_logic;

BEGIN
  
  -- Convert pipe position to integer
  pipe_x_int <= to_integer(unsigned(pipe_x));
  
  -- Configuración del contador
  counter_max <= std_logic_vector(to_unsigned(99, 7));

  -- 🔹 Reset SOLO cuando hay flanco ST_START -> ST_PLAYING
  new_game_pulse <= '1' WHEN (game_state_prev = ST_START AND game_state = ST_PLAYING)
                    ELSE '0';

  counter_rst <= new_game_pulse;

  -- Instancia del contador
  u_contador : ENTITY work.contador
    GENERIC MAP(
      n => 7  -- 7 bits para 0-99
    )
    PORT MAP(
      clk      => clk,
      en       => counter_en,
      rst      => counter_rst,
      max      => counter_max,
      max_tick => OPEN,
      counter  => counter_out
    );
  
  -- Output del score actual
  score <= unsigned(counter_out);
  
  ---------------------------------------------------------------------------
  -- Lógica principal: detección de paso de tubo + actualización de max_score
  ---------------------------------------------------------------------------
  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN

      -- Guardar estado previo para detectar transición
      game_state_prev <= game_state;

      IF frame_tick = '1' THEN
        pipe_x_prev <= pipe_x_int;

        IF game_state = ST_PLAYING THEN

          IF (pipe_x_prev + PIPE_WIDTH >= BIRD_X) AND
             (pipe_x_int  + PIPE_WIDTH <  BIRD_X) THEN
            pipe_just_passed <= '1';
          ELSE
            pipe_just_passed <= '0';
          END IF;
        ELSE
          pipe_just_passed <= '0';
        END IF;

      END IF;  -- frame_tick

      -- Actualizar best_score cuando pasas un tubo
      IF (pipe_just_passed = '1' AND frame_tick = '1') THEN
        -- Aquí el contador está incrementando de N a N+1,
        -- pero counter_out aún vale N, por eso sumamos 1.
        IF unsigned(counter_out) + 1 > max_score THEN
          max_score <= unsigned(counter_out) + 1;
        END IF;
      END IF;

    END IF; -- rising_edge
  END PROCESS;
  
  -- Enable del contador: 1 solo cuando el pájaro pasa el tubo
  counter_en <= pipe_just_passed AND frame_tick;
				 
  best_score <= max_score;

END ARCHITECTURE;