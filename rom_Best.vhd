-- ============================================
-- ROM PARA BEST
-- ============================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY rom_Best IS
    PORT(
        clk    : IN  STD_LOGIC;
        r_addr : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);  -- 12 bits para 2176 posiciones
        r_data : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF rom_Best IS
    CONSTANT DATA_WIDTH : integer := 2;
    CONSTANT ADDR_WIDTH : integer := 12;  -- 2^12 = 4096 > 2176 ✅
    
    SIGNAL data_reg : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    
    TYPE mem_type IS ARRAY (0 TO 2**ADDR_WIDTH - 1)
        OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    
    SIGNAL DATA_ROM : mem_type;
    
    ATTRIBUTE ram_init_file : STRING;
    ATTRIBUTE ram_init_file OF DATA_ROM : SIGNAL IS "Best.mif";
    
BEGIN
    read_process : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            -- Limitar acceso al tamaño real (64*34 = 2176)
            IF to_integer(unsigned(r_addr)) < 2176 THEN
                data_reg <= DATA_ROM(to_integer(unsigned(r_addr)));
            ELSE
                data_reg <= "10";  -- Transparente si está fuera de rango
            END IF;
        END IF;
    END PROCESS;
    
    r_data <= data_reg;
END ARCHITECTURE;