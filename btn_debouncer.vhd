LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY btn_debouncer IS
  GENERIC (
    N           : integer := 20;
    CLOCK_HZ    : integer := 50_000_000;
    DEBOUNCE_MS : integer := 3
  );
  PORT(
    clock   : IN  std_logic;
    in_btn  : IN  std_logic;
    out_btn : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF btn_debouncer IS
  TYPE state IS (press_btn, waitfor);
  SIGNAL state_reg, next_state : state := press_btn;

  SIGNAL last_stable   : std_logic := '0';
  SIGNAL last_stable_n : std_logic := '0';

  SIGNAL out_pulse     : std_logic := '0';

  SIGNAL enable        : std_logic := '0';
  SIGNAL done_waiting  : std_logic;
  SIGNAL wait_time     : std_logic_vector(N-1 DOWNTO 0);
  SIGNAL cnt_dummy     : std_logic_vector(N-1 DOWNTO 0);

  CONSTANT WAIT_TICKS  : integer := (CLOCK_HZ/1000) * DEBOUNCE_MS - 1;
BEGIN
  wait_time <= std_logic_vector(to_unsigned(WAIT_TICKS, N));

  PROCESS(clock)
  BEGIN
    IF rising_edge(clock) THEN
      state_reg   <= next_state;
      last_stable <= last_stable_n;
      out_btn     <= out_pulse;
    END IF;
  END PROCESS;

  PROCESS (in_btn, state_reg, done_waiting, last_stable)
  BEGIN
    next_state     <= state_reg;
    enable         <= '0';
    out_pulse      <= '0';
    last_stable_n  <= last_stable;

    CASE state_reg IS
      WHEN press_btn =>
        IF (in_btn /= last_stable) THEN
          next_state <= waitfor;
        ELSE
          next_state <= press_btn;
        END IF;

      WHEN waitfor =>
        IF (in_btn = last_stable) THEN
          enable     <= '0';
          next_state <= press_btn;
        ELSE
          enable <= '1';
          IF done_waiting = '1' THEN
            last_stable_n <= in_btn;
            -- Pulso solo en flanco de subida
            IF (last_stable = '0' AND in_btn = '1') THEN
              out_pulse <= '1';
            ELSE
              out_pulse <= '0';
            END IF;
            next_state <= press_btn;
          ELSE
            next_state <= waitfor;
          END IF;
        END IF;
    END CASE;
  END PROCESS;

  u_v : ENTITY work.contador
    GENERIC MAP ( n => N )
    PORT MAP (
      clk      => clock,
      en       => enable,
      max      => wait_time,
      max_tick => done_waiting,
      counter  => cnt_dummy
    );

END ARCHITECTURE;

