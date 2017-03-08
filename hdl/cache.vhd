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

entity cache is
	generic(
		MEMORY_ADDRESS_WIDTH : INTEGER := 32; -- Memory address is 32-bit wide.
		DATA_WIDTH           : INTEGER := 32; -- Length of instruction/data words.
		BLOCKSIZE            : INTEGER := 4; -- Number of words that a block contains.
		ADDRESSWIDTH         : INTEGER := 256; -- Number of cache blocks.
		OFFSET               : INTEGER := 8; -- Number of bits that can be selected in the cache.
		TAG_FILENAME         : STRING  := "../imem/tagCache";
		DATA_FILENAME        : STRING  := "../imem/dataCache";
		FILE_EXTENSION       : STRING  := ".txt" -- File extension for BRAM.
	);

	port(
		-- Clock and reset.
		clk         : in    STD_LOGIC;
		reset       : in    STD_LOGIC;

		-- Hit/Miss counter.
		hitCounter  : out   INTEGER;
		missCounter : out   INTEGER;

		-- Port regarding the CPU.
		stallCPU    : out   STD_LOGIC;
		rdCPU       : in    STD_LOGIC;
		wrCPU       : in    STD_LOGIC;
		addrCPU     : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataCPU     : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

		-- Ports regarding the Main Memory.
		readyMEM    : in    STD_LOGIC;
		rdMEM       : out   STD_LOGIC;
		wrMEM       : out   STD_LOGIC;
		addrMEM     : out   STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataMEM     : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0)
	);
end;

architecture rtl of cache is
	
	-- Signal identifies whether to read a single data word from cache block line.
	signal rdWord           : STD_LOGIC := '0';
	
	-- Signal identifies whether to write a single data word to cache block line.
	signal wrWord           : STD_LOGIC := '0';
	
	-- Signal identifies whether to read a complete cache block line.
	signal rdCBLine         : STD_LOGIC := '0';
	
	-- Signal identifies whether to write a complete cache block line.
	signal wrCBLine         : STD_LOGIC := '0';
	
	-- Signal identifies whether to write or read from cache.
	signal writeMode	    : STD_LOGIC := '0';
	
	-- Control signal identifies whether a new cache block line should be written into cache.
	signal wrNewCBLine : STD_LOGIC := '0';
	
	-- Signal identifies whether a cache block line is dirty or not.
	signal dirty            : STD_LOGIC := '0';
	
	-- Signal identifies whether a cache block line is valid or not.
	signal valid            : STD_LOGIC := '0';
	
	-- Signal identifies whether the valid bit of a cache block line should be updated.
	signal setValid         : STD_LOGIC := '0';
	
	-- Signal identifies whether the dirty bit of a cache block line should be updated.
	signal setDirty         : STD_LOGIC := '0';
	
	-- Signal identifies whether a cache hit or cache miss is reached.
	signal hit              : STD_LOGIC := '0'; 
	
	-- New cache block line will be written into cache.
	signal newCacheBlockLine : STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0) := (others=>'0');
	

begin
	dataCPU <= (others=>'Z');
	
	direct_mapped_cache : entity work.directMappedCache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk            => clk,
			reset          => reset,
			addrCPU        => addrCPU,
			dataCPU        => dataCPU,
			dataMEM        => dataMEM,
			rdCBLine       => rdCBLine,
			wrCBLine       => wrCBLine,
			newCacheBlockLine => newCacheBlockLine,
			wrNewCBLine	   => wrNewCBLine,
			rdWord         => rdWord,
			wrWord         => wrWord,
			writeMode	   => writeMode,
			valid          => valid,
			dirty          => dirty,
			setValid       => setValid,
			setDirty       => setDirty,
			hit            => hit
		);

	cache_controller : entity work.cacheController
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			OFFSET               => OFFSET
		)
		port map(

			-- Clock and reset signal.
			clk            => clk,
			reset          => reset,

			-- Ports regarding Direct Mapped Cache.
			wrNewCBLine	   => wrNewCBLine,
			rdWord         => rdWord,
			wrWord         => wrWord,
			wrCBLine       => wrCBLine,
			rdCBLine       => rdCBLine,
			writeMode	   => writeMode,
			valid          => valid,
			dirty          => dirty,
			setValid       => setValid,
			setDirty       => setDirty,
			hitFromCache   => hit,
			newCacheBlockLine => newCacheBlockLine,

			-- Ports regarding CPU.
			hitCounter     => hitCounter,
			missCounter    => missCounter,
			stallCPU       => stallCPU,
			rdCPU          => rdCPU,
			wrCPU          => wrCPU,
			addrCPU        => addrCPU,
			dataCPU        => dataCPU,

			-- Ports regarding MEM.
			readyMEM       => readyMEM,
			rdMEM          => rdMEM,
			wrMEM          => wrMEM,
			addrMEM        => addrMEM,
			dataMEM        => dataMEM
		);

end rtl;