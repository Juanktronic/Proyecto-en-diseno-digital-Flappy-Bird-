LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY second_text_sprite IS
  GENERIC(
    X_POS : integer := 220;
    Y_POS : integer := 195
  );
  PORT(
    clk         : IN  std_logic;
    row         : IN  std_logic_vector(9 DOWNTO 0);
    column      : IN  std_logic_vector(9 DOWNTO 0);
    enable      : IN  std_logic;
    rom_data    : IN  std_logic_vector(3 DOWNTO 0);     
    rom_addr    : OUT std_logic_vector(12 DOWNTO 0);
    pixel_data  : OUT std_logic_vector(11 DOWNTO 0);      -- VGA 12 BITS
    visible     : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF second_text_sprite IS
  CONSTANT IMG_W  : integer := 130;
  CONSTANT IMG_H  : integer := 34;

  CONSTANT TRANSP_IDX : std_logic_vector(3 DOWNTO 0) := "1111";

  TYPE palette16 IS ARRAY(0 TO 15) OF std_logic_vector(11 DOWNTO 0);
  CONSTANT VGA_PALETTE : palette16 := (
    x"000", x"FFF", x"F00", x"0F0",
    x"00F", x"FF0", x"F0F", x"0FF",
    x"888", x"A52", x"F80", x"0A0",
    x"00A", x"A0A", x"0AA", x"BBB"
  );

  SIGNAL x_i, y_i     : integer;
  SIGNAL within_area  : std_logic;
  SIGNAL dx_i, dy_i   : integer;
  SIGNAL index_i      : integer;

BEGIN
  x_i <= to_integer(unsigned(column));
  y_i <= to_integer(unsigned(row));

  within_area <= '1' WHEN (enable = '1') AND
                          (x_i >= X_POS) AND 
                          (x_i < X_POS + IMG_W) AND
                          (y_i >= Y_POS) AND 
                          (y_i < Y_POS + IMG_H)
                 ELSE '0';

  dx_i <= x_i - X_POS WHEN within_area = '1' ELSE 0;
  dy_i <= y_i - Y_POS WHEN within_area = '1' ELSE 0;

  index_i <= dy_i * IMG_W + dx_i;
  rom_addr <= std_logic_vector(to_unsigned(index_i, 13));

  pixel_data <= VGA_PALETTE(to_integer(unsigned(rom_data)));
  visible <= '1' WHEN (within_area = '1') AND (rom_data /= TRANSP_IDX) ELSE '0';

END ARCHITECTURE;
