--------------------------------------------------------------------------------
-- filename : cache_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

use work.mips_pkg.all;
use work.casts.all;

entity mainMemory is
	generic(

		-- Number of cache blocks.
		ADDRESSWIDTH         : INTEGER := 256;

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
		clk         : in  STD_LOGIC;
		readyMEM    : out STD_LOGIC;
		rdMEM       : in  STD_LOGIC;
		wrMEM       : in  STD_LOGIC;
		addrMEM     : in  STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataMEM  	: inout  STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0); 
		reset       : in  STD_LOGIC
	);
end;

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
	
	bramMainMemory : entity work.bram   -- data memory
		generic map(INIT => (DATA_FILENAME & FILE_EXTENSION),
			        ADDR => bramAddrWidth,
			        DATA => DATA_WIDTH
		)
		port map(clk, writeToBRAM, addrBram, dataToBRAM, dataFromBRAM);


	mainMemoryContr: entity work.mainMemoryController
	generic map (

		ADDRESSWIDTH => ADDRESSWIDTH,
		MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
		BLOCKSIZE => BLOCKSIZE,
		DATA_WIDTH => DATA_WIDTH,
		BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
		FILE_EXTENSION => FILE_EXTENSION,
		DATA_FILENAME => DATA_FILENAME
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
