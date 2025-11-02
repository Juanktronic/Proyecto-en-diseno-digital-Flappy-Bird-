LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

-----------------------------------------------------------
ENTITY pipe_rom IS
    PORT(
        clk     : IN  STD_LOGIC;
        r_addr  : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);     -- 10 bits → 1024 posiciones
        r_data  : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)     -- 12 bits por pixel (RGB 4:4:4)
    );
END ENTITY;
------------------------------------------------------------

ARCHITECTURE rtl OF pipe_rom IS

    CONSTANT DATA_WIDTH : integer := 12;
    CONSTANT ADDR_WIDTH : integer := 12;

    SIGNAL data_reg : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

    -- Tipo de memoria (ROM)
    TYPE mem_type IS ARRAY (0 TO 2**ADDR_WIDTH - 1)
        OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

    SIGNAL DATA_ROM : mem_type;

    -- Cargar archivo MIF generado de la imagen (bird.mif)
    ATTRIBUTE ram_init_file : STRING;
    ATTRIBUTE ram_init_file OF DATA_ROM : SIGNAL IS "pipe1.mif";

BEGIN

    --===================== READ PROCESS =====================--
    read_process : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            data_reg <= DATA_ROM(to_integer(unsigned(r_addr)));
        END IF;
    END PROCESS;

    --===================== READ OUTPUT =====================--
    r_data <= data_reg;

END ARCHITECTURE;
------------------------------------------------------------
