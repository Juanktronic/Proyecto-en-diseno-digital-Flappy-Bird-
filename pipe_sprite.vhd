LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pipe_sprite IS
  PORT(
    clk        : IN std_logic;
    row        : IN std_logic_vector(9 DOWNTO 0);
    column     : IN std_logic_vector(9 DOWNTO 0);
    x_pos      : IN std_logic_vector(10 DOWNTO 0);
    center     : IN std_logic_vector(9 DOWNTO 0);
    pixel_data : OUT std_logic_vector(11 DOWNTO 0);
    visible    : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF pipe_sprite IS
  CONSTANT IMG_W      : integer := 56;
  CONSTANT IMG_H      : integer := 21;
  CONSTANT GAP_HEIGHT : integer := 132;
  CONSTANT TRANSP     : std_logic_vector(11 DOWNTO 0) := x"BBB";
  CONSTANT SCREEN_H       : integer := 480;
  CONSTANT BOTTOM_MARGIN  : integer := 60;
  CONSTANT BOTTOM_LIMIT   : integer := SCREEN_H - BOTTOM_MARGIN;
  
  SIGNAL addr    : std_logic_vector(11 DOWNTO 0);
  SIGNAL color   : std_logic_vector(11 DOWNTO 0);
  
  SIGNAL x_i, y_i, x0_i, c_i      : integer;
  SIGNAL gap_top_i, gap_bot_i     : integer;
  SIGNAL within_x                 : std_logic;
  SIGNAL top_zone, bot_zone       : std_logic;
  SIGNAL inside_any               : std_logic;
  SIGNAL dx_i                     : integer;
  SIGNAL y_top_raw, y_bot_raw     : integer;
  SIGNAL y_top_clamp, y_bot_clamp : integer;
  SIGNAL y_sel                    : integer;
  SIGNAL index_i                  : integer;
  
  -- Señales registradas para compensar latencia de ROM
  SIGNAL inside_any_d1 : std_logic;
  
BEGIN
  x_i  <= to_integer(unsigned(column));
  y_i  <= to_integer(unsigned(row));
  x0_i <= to_integer(signed(x_pos)); 
  c_i  <= to_integer(unsigned(center));
  
  gap_top_i <= c_i - (GAP_HEIGHT/2);
  gap_bot_i <= c_i + (GAP_HEIGHT/2);
  
  within_x  <= '1' WHEN (x_i >= x0_i) AND (x_i < x0_i + IMG_W) ELSE '0';
  top_zone  <= '1' WHEN (within_x = '1') AND (y_i <  gap_top_i) ELSE '0';
  bot_zone  <= '1' WHEN (within_x = '1') AND (y_i >= gap_bot_i) AND (y_i < BOTTOM_LIMIT) ELSE '0';
  inside_any<= '1' WHEN (top_zone = '1') OR (bot_zone = '1') ELSE '0';
  
  dx_i <= x_i - x0_i;
  
  y_top_raw   <= (gap_top_i - 1) - y_i;
  y_top_clamp <= 0                WHEN y_top_raw < 0 ELSE
                 (IMG_H - 1)      WHEN y_top_raw >= IMG_H ELSE
                 y_top_raw;
  
  y_bot_raw   <= y_i - gap_bot_i;
  y_bot_clamp <= 0                WHEN y_bot_raw < 0 ELSE
                 (IMG_H - 1)      WHEN y_bot_raw >= IMG_H ELSE
                 y_bot_raw;
  
  y_sel <= y_top_clamp WHEN top_zone = '1' ELSE
           y_bot_clamp WHEN bot_zone = '1' ELSE
           0;
  
  index_i <= y_sel * IMG_W + dx_i WHEN inside_any = '1' ELSE 0;
  addr <= std_logic_vector(to_unsigned(index_i, addr'length));
  
  u_rom : ENTITY work.pipe_rom
    PORT MAP (
      clk    => clk,
      r_addr => addr,
      r_data => color
    );
  
  -- Proceso para registrar inside_any y compensar latencia de ROM
  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      inside_any_d1 <= inside_any;
    END IF;
  END PROCESS;
  
  pixel_data <= color;
  
  -- Usar la señal retrasada que está sincronizada con el dato de la ROM
  visible <= '1' WHEN (inside_any_d1 = '1') AND (color /= TRANSP)
             ELSE '0';
  
END ARCHITECTURE;
