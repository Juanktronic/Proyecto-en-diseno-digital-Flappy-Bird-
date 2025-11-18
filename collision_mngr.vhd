LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY collision_mngr IS
  PORT(
    clk           : IN  std_logic;
    frame_tick    : IN  std_logic;
    bird_visible  : IN  std_logic;
    pipe_visible  : IN  std_logic;
    collision_px  : OUT std_logic;
    collision_frm : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF collision_mngr IS
  SIGNAL lat      : std_logic := '0';
  SIGNAL col_px_s : std_logic;
BEGIN
  col_px_s     <= bird_visible AND pipe_visible;
  collision_px <= col_px_s;

  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF frame_tick = '1' THEN
        lat <= '0';
      ELSIF col_px_s = '1' THEN
        lat <= '1';
      END IF;
    END IF;
  END PROCESS;

  collision_frm <= lat;
END ARCHITECTURE;
