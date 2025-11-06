LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY btn_debouncer IS
  GENERIC (
    CLOCK_HZ    : integer := 50_000_000; -- Frecuencia del reloj del sistema
    DEBOUNCE_MS : integer := 3           -- Tiempo de estabilización típico (1..10 ms)
  );
  PORT (
    clk      : IN  std_logic;
    btn_raw  : IN  std_logic;  -- botón mecánico sin filtrar
    btn_rise : OUT std_logic   -- pulso 1 clk en flanco ascendente, ya debounced
  );
END ENTITY;

ARCHITECTURE rtl OF btn_debouncer IS
  -- Doble sincronizador para metastabilidad
  SIGNAL s0, s1 : std_logic := '0';

  -- Estado estable actual del botón (debounced)
  SIGNAL stable : std_logic := '0';

  -- Contador de estabilidad
  CONSTANT C_MAX : integer := (CLOCK_HZ / 1000) * DEBOUNCE_MS; -- ciclos a esperar
  SIGNAL   cnt   : integer range 0 to C_MAX := 0;

  SIGNAL rise_i : std_logic := '0'; -- pulso interno de 1 ciclo
BEGIN
  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      -- Sincronizar a 'clk'
      s0 <= btn_raw;
      s1 <= s0;

      -- Por defecto, sin pulso
      rise_i <= '0';

      -- Si no hay cambio respecto al nivel estable, reiniciamos el conteo
      IF s1 = stable THEN
        cnt <= 0;
      ELSE
        -- Hay diferencia: contamos hasta confirmar que se mantenga estable
        IF cnt = C_MAX THEN
          -- Confirmado el cambio estable
          stable <= s1;
          IF s1 = '1' THEN
            rise_i <= '1'; -- generar pulso solo en flanco ascendente
          END IF;
          cnt <= 0;
        ELSE
          cnt <= cnt + 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  btn_rise <= rise_i;
END ARCHITECTURE;
