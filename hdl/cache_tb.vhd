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
use work.cache_pkg.all;

entity cache_tb is
	generic(
		MEMORY_ADDRESS_WIDTH : INTEGER := 32; -- Memory address is 32-bit wide.
		DATA_WIDTH           : INTEGER := 32; -- Length of instruction/data words.
		BLOCKSIZE            : INTEGER := 4; -- Number of words that a block contains.
		ADDRESSWIDTH         : INTEGER := 256; -- Number of cache blocks.
		OFFSET               : INTEGER := 8; -- Number of bits that can be selected in the cache.
		BRAM_ADDR_WIDTH 	: INTEGER := 10; -- Number of bits defining the BRAM address wide.
		TAG_FILENAME         : STRING  := "../imem/tagCache";
		DATA_FILENAME        : STRING  := "../imem/dataCache";
		MAIN_MEMORY_FILENAME : STRING  := "../imem/mainMemory";
		FILE_EXTENSION       : STRING  := ".imem"
	);
end;

architecture tests of cache_tb is
	-- Constant object.
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);

	signal clk, reset, memwrite : STD_LOGIC := '0';

	signal stallCPU : STD_LOGIC                                             := '0';
	signal rdCPU    : STD_LOGIC                                             := '0';
	signal wrCPU    : STD_LOGIC                                             := '0';
	signal addrCPU  : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0)   := (others => '0');
	signal dataCPU  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)             := (others => '0');
	signal readyMEM : STD_LOGIC                                             := '0';
	signal rdMEM    : STD_LOGIC                                             := '0';
	signal wrMEM    : STD_LOGIC                                             := '0';
	signal addrMEM  : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0)   := (others => '0');
	signal dataMEM  : STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0) := (others => '0');

	signal tagI         : INTEGER := 0;
	signal indexI       : INTEGER := 0;
	signal offsetI      : INTEGER := 0;
	signal offsetBlockI : INTEGER := 0;
	signal offsetByteI  : INTEGER := 0;

	signal tagV         : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0)         := (others => '0');
	signal indexV       : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0)       := (others => '0');
	signal offsetV      : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0)      := (others => '0');
	signal offsetBlockV : STD_LOGIC_VECTOR(config.offsetBlockNrOfBits - 1 downto 0) := (others => '0');
	signal offsetByteV  : STD_LOGIC_VECTOR(config.offsetByteNrOfBits - 1 downto 0)  := (others => '0');

	signal hitCounter  : INTEGER := 0;
	signal missCounter : INTEGER := 0;
begin
	
	cache : entity work.cache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME
		)
		port map(clk         => clk,
			     reset       => reset,
			     hitCounter  => hitCounter,
			     missCounter => missCounter,
			     stallCPU    => stallCPU,
			     rdCPU       => rdCPU,
			     wrCPU       => wrCPU,
			     dataCPU     => dataCPU,
			     addrCPU     => addrCPU,
			     readyMEM    => readyMEM,
			     rdMEM       => rdMEM,
			     wrMEM       => wrMEM,
			     addrMEM     => addrMEM,
			     dataMEM     => dataMEM
		);

	mainMemoryController : entity work.mainMemory
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			DATA_WIDTH           => DATA_WIDTH,
			BRAM_ADDR_WIDTH		 => BRAM_ADDR_WIDTH,
			DATA_FILENAME        => MAIN_MEMORY_FILENAME,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk         => clk,
			readyMEM    => readyMEM,
			addrMEM     => addrMEM,
			rdMEM       => rdMEM,
			wrMEM       => wrMEM,
			dataMEM_in  => dataMEM,
			dataMEM_out => dataMEM,
			reset       => reset
		);

	-- Generate clock with 10 ns period
	clockProcess : process
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end process;

	-- Generate reset for first two clock cycles
	process
	begin
		reset <= '0';
		wait for 10 ns;
	end process;

	indexV       <= STD_LOGIC_VECTOR(TO_UNSIGNED(indexI, config.indexNrOfBits));
	tagV         <= STD_LOGIC_VECTOR(TO_UNSIGNED(tagI, config.tagNrOfBits));
	offsetBlockV <= STD_LOGIC_VECTOR(TO_UNSIGNED(offsetBlockI, config.offsetBlockNrOfBits));
	offsetByteV  <= STD_LOGIC_VECTOR(TO_UNSIGNED(offsetByteI, config.offsetByteNrOfBits));

end tests;
