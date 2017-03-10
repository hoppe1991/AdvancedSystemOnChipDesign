--------------------------------------------------------------------------------
-- filename : mainMemory.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Include packages.
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.mips_pkg.ALL;
use work.casts.ALL;

-- =============================================================================
-- Entity of the Main Memory.
-- =============================================================================
entity mainMemory is
	generic(

		-- Width of bit string containing the memory address. 
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Number of words that a cache block contains.
		BLOCKSIZE            : integer := 4;

		-- Width of bit string containing a data/instruction word.
		DATA_WIDTH           : INTEGER := 32;

		-- Width of BRAM address (10 <=> Compare code in file mips.vhd).
		BRAM_ADDR_WIDTH 	: INTEGER := 10;
		
		-- File extension regarding BRAM.
		FILE_EXTENSION       : STRING  := ".imem";

		-- Filename regarding regarding BRAM.
		DATA_FILENAME        : STRING  := "../imem/mainMemory"
	);
	port(
		
		-- Clock signal.
		clk         : in  STD_LOGIC;
		
		-- Signal to reset the main memory.
		reset       : in  STD_LOGIC;
		
		-- Signal identifies whether the main memory is ready or not.
		readyMEM    : out STD_LOGIC;
		
		-- Control signal to read from main memory.
		rdMEM       : in  STD_LOGIC;
		
		-- Control signal to write to main memory.
		wrMEM       : in  STD_LOGIC;
		
		-- Address used for reading or writing the main memory.
		addrMEM     : in  STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		
		-- Data to be read from main memory or to be written to main memory.
		dataMEM  	: inout  STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0)
	);
end;

-- =============================================================================
-- Architecture of the entity of the Main Memory.
-- =============================================================================
architecture rtl of mainMemory is

	-- Width of BRAM address (10 <=> Compare code in file mips.vhd).
	constant bramAddrWidth : INTEGER := 10;

	-- Data word should be written to BRAM.
	signal dataFromBRAM : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');

	-- Data word should be read from BRAM.
	signal dataToBRAM : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');

	-- Signal identify whether a word should be written to BRAM ('1') or should be read from BRAM ('0').
	signal writeToBRAM : STD_LOGIC := '0';

	-- Bit string containing the address for the BRAM.
	signal addrBram : STD_LOGIC_VECTOR(bramAddrWidth - 1 downto 0) := (others => '0');
	  
begin
	
	-- ------------------------------------------------------------------------------------------------
	-- BRAM stores the data.
	-- ------------------------------------------------------------------------------------------------
	BRAM_main_memory : entity work.bram
		generic map(INIT => (DATA_FILENAME & FILE_EXTENSION),
			        ADDR => bramAddrWidth,
			        DATA => DATA_WIDTH
		)
		port map(clk, writeToBRAM, addrBram, dataToBRAM, dataFromBRAM);


	-- ------------------------------------------------------------------------------------------------
	-- Controller handles the read and write operations to BRAM.
	-- ------------------------------------------------------------------------------------------------
	controller_main_Memory: entity work.mainMemoryController
	generic map (
		MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
		BLOCKSIZE => BLOCKSIZE,
		DATA_WIDTH => DATA_WIDTH,
		BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH
	)
	port map (
		clk => clk,
		reset => reset,
		readyMEM => readyMEM,
		rdMEM => rdMEM,
		wrMEM => wrMEM,
		addrMEM => addrMEM,
		dataMEM => dataMEM,
		dataFromBRAM => dataFromBRAM,
		dataToBRAM => dataToBRAM,
		writeToBRAM => writeToBRAM,
		addrBRAM => addrBRAM 
	);

end architecture;
