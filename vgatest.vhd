LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY vgatest IS
  PORT(
    clock      : IN  std_logic;
    btn_saltar : IN  std_logic;
    R, G, B    : OUT std_logic_vector(3 DOWNTO 0);
    H, V       : OUT std_logic
  );
END ENTITY;

ARCHITECTURE test OF vgatest IS
  COMPONENT vga_driver IS
    PORT(
      clock       : IN  std_logic;
      row         : OUT std_logic_vector(9 DOWNTO 0);
      column      : OUT std_logic_vector(9 DOWNTO 0);
      H, V        : OUT std_logic;
      frame_flag  : OUT std_logic
    );
  END COMPONENT;

  SIGNAL row, column  : std_logic_vector(9 DOWNTO 0);
  SIGNAL frame_tick   : std_logic;

  SIGNAL bird_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL bird_visible : std_logic;
  SIGNAL bird_x_pos   : std_logic_vector(9 DOWNTO 0);
  SIGNAL bird_y_pos   : std_logic_vector(9 DOWNTO 0);

  SIGNAL pipe1_x_pos, pipe2_x_pos, pipe3_x_pos, pipe4_x_pos : std_logic_vector(9 DOWNTO 0);
  SIGNAL pipe1_center, pipe2_center, pipe3_center, pipe4_center : std_logic_vector(9 DOWNTO 0);
  SIGNAL pipe1_active, pipe2_active, pipe3_active, pipe4_active : std_logic;
  SIGNAL pipe_gen : std_logic;

  SIGNAL pipe1_rgb, pipe2_rgb, pipe3_rgb, pipe4_rgb : std_logic_vector(11 DOWNTO 0);
  SIGNAL pipe1_visible, pipe2_visible, pipe3_visible, pipe4_visible : std_logic;

  CONSTANT BIRD_X : integer := 100;
BEGIN
  u_vga : vga_driver
    PORT MAP (
      clock       => clock,
      row         => row,
      column      => column,
      H           => H,
      V           => V,
      frame_flag  => frame_tick
    );

  u_bird_movement : ENTITY work.bird_movement
    PORT MAP (
      clk           => clock,
      Frame_tick    => frame_tick,
      btn_saltar    => btn_saltar,
      bird_y_pos    => bird_y_pos
    );

  u_pipe_movement : ENTITY work.pipe_movement
    PORT MAP (
      clk           => clock,
      Frame_tick    => frame_tick,
      pipe1_x_pos   => pipe1_x_pos,
      pipe2_x_pos   => pipe2_x_pos,
      pipe3_x_pos   => pipe3_x_pos,
      pipe4_x_pos   => pipe4_x_pos,
      pipe1_center  => pipe1_center,
      pipe2_center  => pipe2_center,
      pipe3_center  => pipe3_center,
      pipe4_center  => pipe4_center,
      pipe1_active  => pipe1_active,
      pipe2_active  => pipe2_active,
      pipe3_active  => pipe3_active,
      pipe4_active  => pipe4_active,
      pipe_gen      => pipe_gen
    );

  bird_x_pos <= std_logic_vector(to_unsigned(BIRD_X, 10));

  u_bird : ENTITY work.bird_sprite
    PORT MAP (
      clk         => clock,
      row         => row,
      column      => column,
      x_pos       => bird_x_pos,
      y_pos       => bird_y_pos,
      pixel_data  => bird_rgb,
      visible     => bird_visible
    );

  u_pipe1 : ENTITY work.pipe_sprite
    PORT MAP (
      clk         => clock,
      row         => row,
      column      => column,
      x_pos       => pipe1_x_pos,
      center      => pipe1_center,
      pixel_data  => pipe1_rgb,
      visible     => pipe1_visible
    );

  u_pipe2 : ENTITY work.pipe_sprite
    PORT MAP (
      clk         => clock,
      row         => row,
      column      => column,
      x_pos       => pipe2_x_pos,
      center      => pipe2_center,
      pixel_data  => pipe2_rgb,
      visible     => pipe2_visible
    );

  u_pipe3 : ENTITY work.pipe_sprite
    PORT MAP (
      clk         => clock,
      row         => row,
      column      => column,
      x_pos       => pipe3_x_pos,
      center      => pipe3_center,
      pixel_data  => pipe3_rgb,
      visible     => pipe3_visible
    );

  u_pipe4 : ENTITY work.pipe_sprite
    PORT MAP (
      clk         => clock,
      row         => row,
      column      => column,
      x_pos       => pipe4_x_pos,
      center      => pipe4_center,
      pixel_data  => pipe4_rgb,
      visible     => pipe4_visible
    );

  PROCESS(clock)
  BEGIN
    IF rising_edge(clock) THEN
      IF bird_visible = '1' THEN
        R <= bird_rgb(11 DOWNTO 8);
        G <= bird_rgb(7 DOWNTO 4);
        B <= bird_rgb(3 DOWNTO 0);
      ELSIF pipe1_visible = '1' THEN
        R <= pipe1_rgb(11 DOWNTO 8);
        G <= pipe1_rgb(7 DOWNTO 4);
        B <= pipe1_rgb(3 DOWNTO 0);
      ELSIF pipe2_visible = '1' THEN
        R <= pipe2_rgb(11 DOWNTO 8);
        G <= pipe2_rgb(7 DOWNTO 4);
        B <= pipe2_rgb(3 DOWNTO 0);
      ELSIF pipe3_visible = '1' THEN
        R <= pipe3_rgb(11 DOWNTO 8);
        G <= pipe3_rgb(7 DOWNTO 4);
        B <= pipe3_rgb(3 DOWNTO 0);
      ELSIF pipe4_visible = '1' THEN
        R <= pipe4_rgb(11 DOWNTO 8);
        G <= pipe4_rgb(7 DOWNTO 4);
        B <= pipe4_rgb(3 DOWNTO 0);
      ELSE
        R <= "0000"; 
        G <= "0000"; 
        B <= "0000";
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;