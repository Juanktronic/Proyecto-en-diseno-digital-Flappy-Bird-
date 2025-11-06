LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pipe_movement IS
  PORT(
    clk        : IN  std_logic;
    Frame_tick : IN  std_logic;

    pipe1_x_pos : OUT std_logic_vector(9 DOWNTO 0);
    pipe2_x_pos : OUT std_logic_vector(9 DOWNTO 0);
    pipe3_x_pos : OUT std_logic_vector(9 DOWNTO 0);
    pipe4_x_pos : OUT std_logic_vector(9 DOWNTO 0);

    pipe1_center : OUT std_logic_vector(9 DOWNTO 0);
    pipe2_center : OUT std_logic_vector(9 DOWNTO 0);
    pipe3_center : OUT std_logic_vector(9 DOWNTO 0);
    pipe4_center : OUT std_logic_vector(9 DOWNTO 0);

    pipe1_active : OUT std_logic;
    pipe2_active : OUT std_logic;
    pipe3_active : OUT std_logic;
    pipe4_active : OUT std_logic;

    pipe_gen   : OUT std_logic
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

  CONSTANT CENTER_MIN     : integer := 150;
  CONSTANT CENTER_MAX     : integer := 330;

  TYPE pipe_array IS ARRAY (0 TO MAX_PIPES-1) OF signed(15 DOWNTO 0);
  SIGNAL pipe_x      : pipe_array := (OTHERS => to_signed(PIPE_RESET_X, 16));
  SIGNAL pipe_center : pipe_array := (OTHERS => to_signed(240, 16));
  SIGNAL pipe_act    : std_logic_vector(MAX_PIPES-1 DOWNTO 0) := (OTHERS => '0');

  CONSTANT SPAWN_FRAMES : integer := PITCH_PIXELS / PIPE_SPEED;
  SIGNAL   spawn_cnt    : integer range 0 to SPAWN_FRAMES := 0;
  SIGNAL   spawn_pulse  : std_logic := '0';
  SIGNAL   first_spawn  : std_logic := '1';

  SIGNAL lfsr : std_logic_vector(15 DOWNTO 0) := x"ACE1";

BEGIN
  PROCESS(Frame_tick)
    VARIABLE next_x        : signed(15 DOWNTO 0);
    VARIABLE spawned       : std_logic;
    VARIABLE active_count  : integer range 0 to MAX_PIPES;
    VARIABLE random_val    : integer range 0 to 1023;
    VARIABLE new_center    : integer range 0 to 511;
    VARIABLE feedback      : std_logic;
  BEGIN
    IF rising_edge(Frame_tick) THEN
      
      feedback := lfsr(15) XOR lfsr(13) XOR lfsr(12) XOR lfsr(10);
      lfsr <= lfsr(14 DOWNTO 0) & feedback;

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

      IF spawn_cnt > 0 THEN
        spawn_cnt <= spawn_cnt - 1;
      END IF;

      spawned := '0';
      active_count := 0;
      
      FOR i IN 0 TO MAX_PIPES-1 LOOP
        IF pipe_act(i) = '1' THEN
          active_count := active_count + 1;
        END IF;
      END LOOP;

      IF ((spawn_cnt = 0) OR (first_spawn = '1')) AND (active_count < MAX_PIPES) THEN
        
        random_val := to_integer(unsigned(lfsr(9 DOWNTO 0)));
        new_center := CENTER_MIN + (random_val mod (CENTER_MAX - CENTER_MIN + 1));
        
        FOR i IN 0 TO MAX_PIPES-1 LOOP
          IF (pipe_act(i) = '0') AND (spawned = '0') THEN
            pipe_x(i)      <= to_signed(PIPE_START_X, 16);
            pipe_center(i) <= to_signed(new_center, 16);
            pipe_act(i)    <= '1';
            spawned        := '1';
            
            spawn_cnt   <= SPAWN_FRAMES;
            first_spawn <= '0';
          END IF;
        END LOOP;
        
      END IF;

      IF spawned = '1' THEN
        spawn_pulse <= '1';
      ELSE
        spawn_pulse <= '0';
      END IF;

    END IF;
  END PROCESS;

  pipe_gen <= spawn_pulse;

  pipe1_x_pos <= std_logic_vector(pipe_x(0)(9 DOWNTO 0));
  pipe2_x_pos <= std_logic_vector(pipe_x(1)(9 DOWNTO 0));
  pipe3_x_pos <= std_logic_vector(pipe_x(2)(9 DOWNTO 0));
  pipe4_x_pos <= std_logic_vector(pipe_x(3)(9 DOWNTO 0));

  pipe1_center <= std_logic_vector(pipe_center(0)(9 DOWNTO 0));
  pipe2_center <= std_logic_vector(pipe_center(1)(9 DOWNTO 0));
  pipe3_center <= std_logic_vector(pipe_center(2)(9 DOWNTO 0));
  pipe4_center <= std_logic_vector(pipe_center(3)(9 DOWNTO 0));

  pipe1_active <= pipe_act(0);
  pipe2_active <= pipe_act(1);
  pipe3_active <= pipe_act(2);
  pipe4_active <= pipe_act(3);

END ARCHITECTURE;