-- RGB VGA test pattern  (con gradiente 12-bit: 4b por canal)

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY vgatest IS
  PORT(
    clock         : IN  std_logic;                   -- reloj base (p.ej. 50 MHz)
    R, G, B       : OUT std_logic_vector(3 DOWNTO 0);-- 4 bits por canal
    H, V          : OUT std_logic
  );
END ENTITY;

ARCHITECTURE test OF vgatest IS
  ----------------------------------------------------------------
  -- Señales del PLL (sin 'locked')
  ----------------------------------------------------------------

  ----------------------------------------------------------------
  -- Driver VGA (solo genera sincronías y coordenadas)
  ----------------------------------------------------------------
  COMPONENT vga_driver IS
    PORT(
      clock   : IN  std_logic;                          -- reloj de píxel
      row     : OUT std_logic_vector(9 DOWNTO 0);       -- 0..524
      column  : OUT std_logic_vector(9 DOWNTO 0);       -- 0..799
      H, V    : OUT std_logic
    );
  END COMPONENT;

  -- >>> Añadido: señales para recibir row/column del driver
  SIGNAL row    : std_logic_vector(9 DOWNTO 0);
  SIGNAL column : std_logic_vector(9 DOWNTO 0);

  -- Colores internos (4 bits por canal)
  SIGNAL r_i, g_i, b_i : std_logic_vector(3 DOWNTO 0);
BEGIN
  ----------------------------------------------------------------
  -- Driver VGA: coordenadas y sincronías
  ----------------------------------------------------------------
  u_vga : vga_driver
    PORT MAP (
      clock  => clock,
      row    => row,
      column => column,
      H      => H,
      V      => V
    );

  ----------------------------------------------------------------
  -- “Gradiente”/rectángulos de color (12-bit) usando comparaciones válidas
  ----------------------------------------------------------------
  RGB : process(row, column)
  begin
-- Rojo: (0,0) a (359,349)
if (unsigned(row)    < to_unsigned(360,10)) and
   (unsigned(column) < to_unsigned(350,10)) then
  R <= x"F";          -- antes "0001"
else
  R <= x"0";
end if;

-- Verde: (0,250) a (359,639)
if (unsigned(row)    < to_unsigned(360,10)) and
   (unsigned(column) > to_unsigned(250,10)) and
   (unsigned(column) < to_unsigned(640,10)) then
  G <= x"F";          -- antes "0001"
else
  G <= x"0";
end if;

-- Azul: (120,150) a (479,499)
if (unsigned(row)    > to_unsigned(120,10)) and
   (unsigned(row)    < to_unsigned(480,10)) and
   (unsigned(column) > to_unsigned(150,10)) and
   (unsigned(column) < to_unsigned(500,10)) then
  B <= x"F";          -- antes "0001"
else
  B <= x"0";
end if;

  end process;
END ARCHITECTURE;
