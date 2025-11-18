LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY game_over_sprite IS

  PORT(
    clk         : IN  std_logic;
    row         : IN  std_logic_vector(9 DOWNTO 0);
    column      : IN  std_logic_vector(9 DOWNTO 0);
    pixel_data  : OUT std_logic_vector(11 DOWNTO 0);
    visible     : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF game_over_sprite IS
  CONSTANT IMG_W      : integer := 324;
  CONSTANT IMG_H      : integer := 80;

  CONSTANT SCREEN_W   : integer := 640;
  CONSTANT SCREEN_H   : integer := 480;

  CONSTANT X_POS      : integer := (SCREEN_W - IMG_W) / 2;
  CONSTANT Y_POS      : integer := (SCREEN_H - IMG_H) / 2;

  CONSTANT TRANSP_IDX : std_logic_vector(3 DOWNTO 0) := "1111";

  TYPE palette16 IS ARRAY(0 TO 15) OF std_logic_vector(11 DOWNTO 0);
  CONSTANT VGA_PALETTE : palette16 := (
    x"000", x"FFF", x"F00", x"0F0",
    x"00F", x"FF0", x"F0F", x"0FF",
    x"888", x"A52", x"F80", x"0A0",
    x"00A", x"A0A", x"0AA", x"BBB"
  );

  SIGNAL show_sprite    : std_logic := '0';

  SIGNAL collision_prev : std_logic := '0';
  SIGNAL collision_edge : std_logic;

  SIGNAL addr           : std_logic_vector(14 DOWNTO 0);
  SIGNAL color_idx      : std_logic_vector(3 DOWNTO 0);   -- 🔥 4 BITS
  SIGNAL x_i, y_i       : integer;
  SIGNAL within_area    : std_logic;
  SIGNAL dx_i, dy_i     : integer;
  SIGNAL index_i        : integer;

BEGIN
  x_i <= to_integer(unsigned(column));
  y_i <= to_integer(unsigned(row));


  within_area <= '1' WHEN (show_sprite = '1') AND
                          (x_i >= X_POS) AND 
                          (x_i < X_POS + IMG_W) AND
                          (y_i >= Y_POS) AND 
                          (y_i < Y_POS + IMG_H)
                 ELSE '0';

  dx_i <= x_i - X_POS;
  dy_i <= y_i - Y_POS;

  index_i <= dy_i * IMG_W + dx_i WHEN within_area = '1' ELSE 0;

  addr <= std_logic_vector(to_unsigned(index_i, addr'length));

  -- ROM de 4 bits
  u_rom : ENTITY work.rom_GameOver
    PORT MAP (
      clk    => clk,
      r_addr => addr,
      r_data => color_idx
    );

  pixel_data <= VGA_PALETTE(to_integer(unsigned(color_idx)));
  visible    <= '1' WHEN (within_area = '1') AND (color_idx /= TRANSP_IDX) ELSE '0';

END ARCHITECTURE;
