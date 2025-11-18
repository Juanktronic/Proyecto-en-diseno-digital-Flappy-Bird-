LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY rom_score1 IS
    PORT(
        clk     : IN  STD_LOGIC;
        r_addr  : IN  STD_LOGIC_VECTOR(12 DOWNTO 0);
        r_data  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF rom_score1 IS
    CONSTANT DATA_WIDTH : integer := 4;
    CONSTANT ADDR_WIDTH : integer := 12;

    SIGNAL data_reg : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

    TYPE mem_type IS ARRAY (0 TO 2**ADDR_WIDTH - 1)
        OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

    SIGNAL DATA_ROM : mem_type;

    ATTRIBUTE ram_init_file : STRING;
    ATTRIBUTE ram_init_file OF DATA_ROM : SIGNAL IS "score.mif";
BEGIN
    read_process : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            data_reg <= DATA_ROM(to_integer(unsigned(r_addr)));
        END IF;
    END PROCESS;

    r_data <= data_reg;
END ARCHITECTURE;