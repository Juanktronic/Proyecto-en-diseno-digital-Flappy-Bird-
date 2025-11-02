LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pipe_sprite IS
  PORT(
    clk         : IN  std_logic;
    row         : IN  std_logic_vector(9 DOWNTO 0);
    column      : IN  std_logic_vector(9 DOWNTO 0);
    x_pos       : IN  std_logic_vector(9 DOWNTO 0);
    center      : IN  std_logic_vector(9 DOWNTO 0);
    pixel_data  : OUT std_logic_vector(11 DOWNTO 0);
    visible     : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF pipe_sprite IS

  CONSTANT IMG_W      : integer := 56;
  CONSTANT IMG_H      : integer := 21;
  CONSTANT GAP_HEIGHT : integer := 113;
  CONSTANT SCREEN_H   : integer := 480;

  -- addr needs to index up to IMG_W*IMG_H - 1 = 1791 -> 11 bits
  SIGNAL addr    : std_logic_vector(11 DOWNTO 0); -- <-- 11 bits
  SIGNAL color   : std_logic_vector(11 DOWNTO 0);
  SIGNAL show_px : std_logic := '0';

  SIGNAL x_int, y_int, x0_int, c_int : integer;

BEGIN

  -- Convert coordinates once
  x_int  <= to_integer(unsigned(column));
  y_int  <= to_integer(unsigned(row));
  x0_int <= to_integer(unsigned(x_pos));
  c_int  <= to_integer(unsigned(center));

  -----------------------------------------------------------------
  -- Address generation (TOP reflected by scanning ROM upward,
  -- BOTTOM normal, plus body extension by clamping)
  -----------------------------------------------------------------
  process(x_int, y_int, x0_int, c_int)
    variable y_img : integer;
    variable index : integer;
    variable gap_top : integer;
    variable gap_bottom : integer;
  begin
    addr    <= (others => '0');
    show_px <= '0';
    index   := 0;

    gap_top := c_int - (GAP_HEIGHT / 2);
    gap_bottom := c_int + (GAP_HEIGHT / 2);

    if (x_int >= x0_int) and (x_int < x0_int + IMG_W) then

      -- TOP PIPE (we scan ROM rows upward from the gap; no inversion)
      if (y_int < gap_top) then
        -- distance from the pixel to the row just above the gap
        y_img := (gap_top - 1) - y_int;  -- 0 = pixel immediately above gap

        -- clamp to ROM height to extend body (repeat last ROM row)
        if y_img < 0 then
          y_img := 0;
        elsif y_img >= IMG_H then
          y_img := IMG_H - 1;
        end if;

        -- row-major index: row * IMG_W + column_offset
        index := y_img * IMG_W + (x_int - x0_int);
        show_px <= '1';

      -- BOTTOM PIPE (normal orientation)
      elsif (y_int >= gap_bottom) then
        y_img := y_int - gap_bottom; -- 0 = pixel immediately below gap

        if y_img >= IMG_H then
          y_img := IMG_H - 1;
        end if;

        index := y_img * IMG_W + (x_int - x0_int);
        show_px <= '1';
      end if;

      -- write address with correct width
      addr <= std_logic_vector(to_unsigned(index, addr'length));
    end if;
  end process;

  -----------------------------------------------------------------
  -- ROM instance (pipe head facing down)
  -----------------------------------------------------------------
  u_rom : ENTITY work.pipe_rom
    PORT MAP (
      clk    => clk,
      r_addr => addr,
      r_data => color
    );

  -----------------------------------------------------------------
  -- Visibility + transparency
  -----------------------------------------------------------------
  process(show_px, color)
  begin
    if (show_px = '1') and (color /= x"BBB") then
      visible <= '1';
    else
      visible <= '0';
    end if;
    pixel_data <= color;
  end process;

END ARCHITECTURE;

