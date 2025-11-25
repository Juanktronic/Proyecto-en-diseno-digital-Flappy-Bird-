LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY vga_driver IS
  PORT(
    clock       : IN  std_logic;
    row, column : OUT std_logic_vector(9 DOWNTO 0);
	 frame_flag  : OUT std_logic;
    H, V        : OUT std_logic
  );
END ENTITY;

ARCHITECTURE behaviour OF vga_driver IS
  CONSTANT b : natural := 96;    --Retrace
  CONSTANT c : natural := 48;    --Back Porch
  CONSTANT d : natural := 640;   --Screen
  CONSTANT e : natural := 16;    --Front Porch
  CONSTANT a : natural := b + c + d + e; --=800
  CONSTANT p : natural := 2;     --Back Porch
  CONSTANT q : natural := 33;    --Retrace
  CONSTANT r : natural := 480;   --Screen
  CONSTANT s : natural := 10;    --Front Porch
  CONSTANT o : natural := p + q + r + s; --=525

  -- Señales de los contadores
  SIGNAL h_cnt_slv : std_logic_vector(9 DOWNTO 0);
  SIGNAL v_cnt_slv : std_logic_vector(9 DOWNTO 0);
  SIGNAL h_tick    : std_logic;
  SIGNAL v_tick    : std_logic;

  -- Vistas unsigned para comparar cómodamente
  SIGNAL h_cnt_u   : unsigned(9 DOWNTO 0);
  SIGNAL v_cnt_u   : unsigned(9 DOWNTO 0);
BEGIN

  h_cnt_u <= unsigned(h_cnt_slv);
  v_cnt_u <= unsigned(v_cnt_slv);
  

	u_h : ENTITY work.contador
	  GENERIC MAP ( N => 10 )
	  PORT MAP (
		 clk      => clock,
		 en       => '1',
		 max      => std_logic_vector(to_unsigned(a-1, 10)),
		 max_tick => h_tick,
		 counter  => h_cnt_slv
	  );

	u_v : ENTITY work.contador
	  GENERIC MAP ( N => 10 )
	  PORT MAP (
		 clk      => clock,                 -- mismo reloj
		 en       => h_tick,                 -- avance sólo fin de línea
		 max      => std_logic_vector(to_unsigned(o-1, 10)),
		 max_tick => v_tick,
		 counter  => v_cnt_slv
	  );

  H <= '0' WHEN (h_cnt_u >= to_unsigned(d+e, 10)) AND
                 (h_cnt_u <  to_unsigned(d+e+b, 10))
       ELSE '1';

  V <= '0' WHEN (v_cnt_u >= to_unsigned(r+s, 10)) AND
                 (v_cnt_u <  to_unsigned(r+s+p, 10))
       ELSE '1';

  row    <= std_logic_vector(v_cnt_u);
  column <= std_logic_vector(h_cnt_u);
  
  frame_flag <= v_tick;
  
END ARCHITECTURE;	