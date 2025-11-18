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

ARCHITECTURE rtl OF vgatest IS
  COMPONENT vga_driver IS
    PORT(
      clock       : IN  std_logic;
      row         : OUT std_logic_vector(9 DOWNTO 0);
      column      : OUT std_logic_vector(9 DOWNTO 0);
      H, V        : OUT std_logic;
      frame_flag  : OUT std_logic
    );
  END COMPONENT;

  SIGNAL PLLclk       : std_logic;
  SIGNAL row, column  : std_logic_vector(9 DOWNTO 0);
  SIGNAL frame_tick   : std_logic;

  SIGNAL bird_rgb     : std_logic_vector(11 DOWNTO 0);
  SIGNAL bird_visible : std_logic;
  SIGNAL bird_x_pos   : std_logic_vector(9 DOWNTO 0);
  SIGNAL bird_y_pos   : std_logic_vector(9 DOWNTO 0);

  CONSTANT BIRD_X : integer := 100;
BEGIN
  u_pll : ENTITY work.PLL_25_175Mhz
    PORT MAP ( areset=>'0', inclk0=>clock, c0=>PLLclk );

  u_vga : vga_driver
    PORT MAP (
      clock       => PLLclk,
      row         => row,
      column      => column,
      H           => H,
      V           => V,
      frame_flag  => frame_tick
    );

  u_bird_movement : ENTITY work.bird_movement
    PORT MAP (
      clk        => clock,
      Frame_tick => frame_tick,
      btn_saltar => btn_saltar,
      bird_y_pos => bird_y_pos
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

  u_color_mngr : ENTITY work.color_mngr
    GENERIC MAP(
      SPR_LAT => 1,
      BIRD_W  => 34,
      BIRD_H  => 24
    )
    PORT MAP(
      clk          => PLLclk,
      row          => row,
      column       => column,
      bird_x_pos   => bird_x_pos,
      bird_y_pos   => bird_y_pos,
      bird_rgb     => bird_rgb,
      bird_visible => bird_visible,
      R            => R,
      G            => G,
      B            => B
    );
END ARCHITECTURE;
