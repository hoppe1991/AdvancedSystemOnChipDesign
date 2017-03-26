--------------------------------------------------------------------------------
-- filename : twoWayAssociativeCache.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 21/02/17
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Include packages.
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;

-- =============================================================================
-- Define the generic variables and ports of the entity.
-- =============================================================================
entity twoWayAssociativeCache is
	generic(
		-- Replacement strategy of the cache.
		REPLACEMENT_STRATEGY : replacementStrategy := LRU_t;

		-- Memory address is 32-bit wide.
		MEMORY_ADDRESS_WIDTH : INTEGER             := 32;

		-- Instruction and data words of the MIPS are 32-bit wide, but other CPUs
		-- have quite different instruction word widths.
		DATA_WIDTH           : integer             := 32;

		-- Is the depth of the cache, i.e. the number of cache blocks / lines.
		ADDRESSWIDTH         : integer             := 256;

		-- Number of words that a block contains and which are simultaneously loaded from the main memory into cache.
		BLOCKSIZE            : integer             := 4;

		-- The number of bits specifies the smallest unit that can be selected
		-- in the cache. Byte (8 Bits) access should be possible.
		OFFSET               : integer             := 8;

		-- Filename for data BRAM - Cache 1.
		DATA_FILENAME_CACHE1 : STRING              := "../imem/dataFileName1";

		-- Filename for data BRAM - Cache 2.
		DATA_FILENAME_CACHE2 : STRING              := "../imem/dataFileName2";

		-- Filename for tag BRAM - Cache 1.
		TAG_FILENAME_CACHE1  : STRING              := "../imem/tagFileName1";

		-- Filename for tag BRAM - Cache 2.
		TAG_FILENAME_CACHE2  : STRING              := "../imem/tagFileName2";

		-- File extension for BRAM.
		FILE_EXTENSION       : STRING              := ".txt"
	);

	port(
		-- Clock signal is used for BRAM.
		clk         : in    STD_LOGIC;
		reset		: in	STD_LOGIC; -- Signal to reset the cache.
		addrCPU     : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0); -- Memory address from CPU is divided into block address and block offset.
		dataCPU     : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.

		addrMEM     : out   STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataToMEM   : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE/2 - 1 downto 0); -- Data from memory to cache or from cache to memory.
		readyMEM    : in    STD_LOGIC;  -- Signal identifies whether the main memory is ready.
		stallCPU    : out   STD_LOGIC;  -- Signal identifies whether to stall the CPU or not.
		wrCPU       : in    STD_LOGIC;  -- Write signal identifies whether a complete cache block should be written into cache.
		rdCPU       : in    STD_LOGIC;  -- Read signal identifies whether a complete cache block should be read from cache.

		hitCounter  : out   INTEGER;    -- Signal counts the number of cache hits.
		missCounter : out   INTEGER;    -- Signal counts the number of cache misses.
		wrMEM       : out   STD_LOGIC;  -- Read signal identifies to read data from the cache.
		rdMEM       : out   STD_LOGIC   -- Write signal identifies to write data into the cache.
	);

end;

--  31  ...             10   9   ...             2   1  ...         0
-- +-----------------------+-----------------------+------------------+
-- | Tag                   | Index                 | Offset           |
-- +-----------------------+-----------------------+------------------+


-- =============================================================================
-- Definition of architecture.
-- =============================================================================
architecture rtl of twoWayAssociativeCache is
	constant config          : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);
	constant BLOCKSIZE_CACHE : INTEGER           := BLOCKSIZE / 2;

	-- Cache interface to direct mapped cache.
	type CACHE_INTERFACE is record
		hit : STD_LOGIC;
		wrCBLine, rdCBLine : STD_LOGIC;
		rdWord, wrWord : STD_LOGIC;
		valid, dirty : STD_LOGIC;
		setValid, setDirty : STD_LOGIC;	
		dataToMEM : STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE_CACHE - 1 downto 0);
		newCacheBlockLine : STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE_CACHE - 1 downto 0);
		writeMode : STD_LOGIC;
		dataCPU : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	end record;
	
	-- Record of two cache interfaces.
	type CACHES_INTERFACE is array(0 to 1) of CACHE_INTERFACE;
	
	-- Initializes cache interface.
	function INIT_CACHE_INTERFACE return CACHE_INTERFACE;
	
	-- Initializes record of cache interfaces.
	function INIT_CACHES return CACHES_INTERFACE;
	
	-- Cache interfaces.
	--signal caches : CACHES_INTERFACE := INIT_CACHES;


	signal hit : STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
	signal wrCBLine, rdCBLine : STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
	signal rdWord, wrWord : STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
	signal valid,dirty  : STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
	signal setValid, setDirty : STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
	signal writeMode : STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
	signal dataToMEM0,dataToMEM1 : STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE_CACHE-1 downto 0) := (others=>'0');
  	signal newCacheBlockLine0,newCacheBlockLine1 : STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE_CACHE-1 downto 0) := (others=>'0');
  	signal dataCPU0, dataCPU1 : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0'); 

 
	-- Initializes cache interface.
	function INIT_CACHE_INTERFACE return CACHE_INTERFACE is
		variable cache : CACHE_INTERFACE;
	begin
		cache.hit       := '0';
		cache.wrCBLine  := '0';
		cache.rdCBLine  := '0';
		cache.rdWord    := '0';
		cache.wrWord    := '0';
		cache.valid     := '0';
		cache.dirty     := '0';
		cache.setValid  := '0';
		cache.setDirty  := '0';
		cache.writeMode := '0';
		
		cache.dataToMEM         := (others=>'0');
		cache.newCacheBlockLine := (others=>'0');
		cache.dataCPu           := (others=>'0');
		
		return cache;
	end;

	-- Initializes record of cache interfaces.
	function INIT_CACHES return CACHES_INTERFACE is
		variable myCaches : CACHES_INTERFACE;
	begin
		myCaches(0) := INIT_CACHE_INTERFACE;
		myCaches(1) := INIT_CACHE_INTERFACE;
		return myCaches;
	end;
	
begin

	-- -----------------------------------------------------------------------------
	-- Controller for the cache.
	-- -----------------------------------------------------------------------------
	controller : entity work.twoWayAssociativeCacheController
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			OFFSET               => OFFSET,
			REPLACEMENT_STRATEGY => REPLACEMENT_STRATEGY
		)
		port map(
			addrCPU            => addrCPU,
			reset			   => reset,
			readyMEM           => readyMEM,
			wrCPU              => wrCPU,
			rdCPU              => rdCPU,
			clk                => clk,
			hit                => hit,
			wrCBLine           => wrCBLine, 
			rdCBLine           => rdCBLine,
			rdWord             => rdWord,
			wrWord             => wrWord,
			valid              => valid,
			dirty              => dirty,
			setValid           => setValid,
			setDirty 		   => setDirty,
			writeMode          => writeMode,
			dataToMEM0		   => dataToMEM0,
			dataToMEM1		   => dataToMEM1,
			newCacheBlockLine0 => newCacheBlockLine0,
			newCacheBlockLine1 => newCacheBlockLine1,
			dataCPU0           => dataCPU0,
			dataCPU1           => dataCPU1,
			dataCPU            => dataCPU,
			dataToMEM          => dataToMEM,
			stallCPU           => stallCPU,
			hitCounter         => hitCounter,
			missCounter        => missCounter,
			wrMEM              => wrMEM,
			rdMEM              => rdMEM,
			addrMEM			   => addrMEM
			);

	-- -----------------------------------------------------------------------------
	-- First Direct Mapped Cache.
	-- -----------------------------------------------------------------------------
	firstDMC : entity work.directMappedCache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			BLOCKSIZE            => BLOCKSIZE_CACHE,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME_CACHE1,
			DATA_FILENAME        => DATA_FILENAME_CACHE1,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk               => clk,
			reset             => reset,
			addrCPU           => addrCPU,
			newCacheBlockLine => newCacheBlockLine0,
			writeMode         => writeMode(0),
			dataCPU           => dataCPU0,
			dataToMEM         => dataToMEM0,
			wrCBLine          => wrCBLine(0),
			rdCBLine          => rdCBLine(0),
			rdWord            => rdWord(0),
			wrWord            => wrWord(0),
			valid             => valid(0),
			dirty             => dirty(0),
			setValid          => setValid(0),
			setDirty          => setDirty(0),
			hit               => hit(0)
		);

	-- -----------------------------------------------------------------------------
	-- Second Direct Mapped Cache.
	-- -----------------------------------------------------------------------------
	secondDMC : entity work.directMappedCache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			BLOCKSIZE            => BLOCKSIZE_CACHE,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME_CACHE2,
			DATA_FILENAME        => DATA_FILENAME_CACHE2,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk               => clk,
			reset             => reset,
			addrCPU           => addrCPU,
			newCacheBlockLine => newCacheBlockLine1,
			writeMode         => writeMode(1),
			dataCPU           => dataCPU1,
			dataToMEM         => dataToMEM1,
			wrCBLine          => wrCBLine(1),
			rdCBLine          => rdCBLine(1),
			rdWord            => rdWord(1),
			wrWord            => wrWord(1),
			valid             => valid(1),
			dirty             => dirty(1),
			setValid          => setValid(1),
			setDirty          => setDirty(1),
			hit               => hit(1)
		);
end rtl;
