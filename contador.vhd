LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY contador IS
  GENERIC (
    n : integer := 28
  );
  PORT (
    clk      : IN  std_logic;
    max      : IN  std_logic_vector(n-1 DOWNTO 0);  -- valor máximo (inclusive)
    max_tick : OUT std_logic;                       -- pulso 1 ciclo al llegar a max
    counter  : OUT std_logic_vector(n-1 DOWNTO 0)   -- cuenta actual
  );
END ENTITY;

ARCHITECTURE rtl OF contador IS
  SIGNAL count_s      : unsigned(n-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL max_u        : unsigned(n-1 DOWNTO 0);
  SIGNAL max_tick_reg : std_logic := '0';
BEGIN
  max_u <= unsigned(max);

  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF count_s = max_u THEN
        count_s      <= (OTHERS => '0'); -- reinicio en 0 al llegar a max
        max_tick_reg <= '1';             -- pulso de 1 ciclo
      ELSE
        count_s      <= count_s + 1;
        max_tick_reg <= '0';
      END IF;
    END IF;
  END PROCESS;

  counter  <= std_logic_vector(count_s);
  max_tick <= max_tick_reg;
END ARCHITECTURE;