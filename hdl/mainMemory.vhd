--------------------------------------------------------------------------------
-- filename : mainMemory.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 10/02/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mainMemory is
	generic(
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;
		BLOCKSIZE            : integer := 4;
		DATA_WIDTH           : INTEGER := 32;
		FILE_EXTENSION   : STRING  := ".txt";
		DATA_FILENAME        : STRING  := "../imem/mainMemory"
	);

	port(
		clk         : in  STD_LOGIC;
		readyMEM    : out STD_LOGIC;
		rdMEM       : in  STD_LOGIC;
		wrMEM       : in  STD_LOGIC;
		addrMEM     : in  STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataMEM_in  : in  STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
		dataMEM_out : out STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0)
	);
end;

architecture synth of mainMemory is
	signal writeToBRAM : STD_LOGIC                                           := '0';
	signal addr        : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := (others => '1');
	signal bram_in     : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)           := (others => '0');
	signal bram_out    : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)           := (others => '0');

	signal cacheBlock : STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0) := (others => '0');
	signal indexStart : INTEGER                                               := 0;
	signal indexEnd   : INTEGER                                               := 0;

begin
	bramMainMemory : entity work.bram   -- data memory
		generic map(INIT => (DATA_FILENAME & FILE_EXTENSION),
			        ADDR => MEMORY_ADDRESS_WIDTH,
			        DATA => DATA_WIDTH
		)
		port map(clk, writeToBRAM, addr, bram_in, bram_out);

	process(clk)
	begin
		if rising_edge(rdMEM) then
			readyMEM    <= '0';
			dataMEM_out <= (others => 'U');
			writeToBRAM <= '0';

			for I in 0 to BLOCKSIZE-1 loop
				addr <= std_logic_vector(to_unsigned(to_integer(unsigned(addrMEM)) + (4 * I), MEMORY_ADDRESS_WIDTH));

				indexStart                             <= I * DATA_WIDTH;
				indexEnd                               <= indexStart + DATA_WIDTH;
				cacheBlock(indexStart downto indexEnd) <= bram_out;

			end loop;

			dataMEM_out <= cacheBlock;
			readyMEM    <= '1';

		elsif rising_edge(wrMEM) then
			readyMEM    <= '0';
			dataMEM_out <= (others => 'U');
			writeToBRAM <= '1';

			for I in 0 to BLOCKSIZE-1 loop
				addr <= std_logic_vector(to_unsigned(to_integer(unsigned(addrMEM)) + (4 * I), MEMORY_ADDRESS_WIDTH));

				indexStart <= I * DATA_WIDTH;
				indexEnd   <= indexStart + DATA_WIDTH;
				bram_in    <= cacheBlock(indexStart downto indexEnd);
			end loop;

			readyMEM <= '1';

		end if;

	end process;

end synth;