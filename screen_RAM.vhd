LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY screen_RAM IS
  GENERIC( DATA_WIDTH : integer := 4;
           ADDR_WIDTH : integer := 19);
  PORT(
    clk     : IN  STD_LOGIC;
    wr_en   : IN  STD_LOGIC;
    w_addr  : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    w_data  : IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    r_addr  : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    r_data  : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF screen_RAM IS
  TYPE mem_type IS ARRAY (0 TO 2**ADDR_WIDTH-1) OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
  SIGNAL ram      : mem_type;
  SIGNAL addr_reg : STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
BEGIN
  -- WRITE PROCESS
  write_process : PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (wr_en = '1') THEN
        ram(to_integer(unsigned(w_addr))) <= w_data;
      END IF;
      addr_reg <= r_addr;
    END IF;
  END PROCESS;

  -- READ
  r_data <= ram(to_integer(unsigned(addr_reg)));
END ARCHITECTURE;
