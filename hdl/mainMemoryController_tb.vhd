--------------------------------------------------------------------------------
-- filename : mainMemoryController_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 10/02/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mainMemoryController_tb is
	generic(

		-- Width of bit string containing the memory address. 
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Number of words that a cache block contains.
		BLOCKSIZE            : integer := 4;

		-- Width of bit string containing a data/instruction word.
		DATA_WIDTH           : INTEGER := 32;

		-- File extension regarding BRAM.
		FILE_EXTENSION       : STRING  := ".imem";

		-- Filename regarding regarding BRAM.
		DATA_FILENAME        : STRING  := "../imem/mainMemory"
	);
end;

architecture mainMemory_testbench of mainMemoryController_tb is
	signal clk         : STD_LOGIC                                             := '0';
	signal readyMEM    : STD_LOGIC                                             := '0';
	signal rdMEM       : STD_LOGIC                                             := '0';
	signal wrMEM       : STD_LOGIC                                             := '0';
	signal addrMEM     : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0)   := (others => '0');
	signal dataMEM_in  : STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0) := (others => '0');
	signal dataMEM_out : STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0) := (others => '0');
begin
	mainMemory : entity work.mainMemoryController
		generic map(MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			        BLOCKSIZE            => BLOCKSIZE,
			        DATA_WIDTH           => DATA_WIDTH,
			        FILE_EXTENSION       => FILE_EXTENSION,
			        DATA_FILENAME        => DATA_FILENAME
		)
		port map(clk, readyMEM, rdMEM, wrMEM, addrMEM, dataMEM_in, dataMEM_out);

	-- Generate clock with 10 ns period
	process
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end process;

	process
	begin
		wait for 10 ns;
		rdMEM   <= '1';
		wait for 20 ns;
		rdMEM <= '0';
		wait for 10 ns;
	end process;

end mainMemory_testbench;