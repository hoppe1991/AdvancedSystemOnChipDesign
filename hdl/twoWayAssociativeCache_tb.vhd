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
entity twoWayAssociativeCache_tb is
	generic (
		
			-- Replacement Strategy of the 2-way associative cache.
			REPLACEMENT_STRATEGY : replacementStrategy := LRU_t;
			
			MEMORY_ADDRESS_WIDTH : INTEGER := 32;
			
			DATA_WIDTH           : INTEGER := 32;
			
			ADDRESSWIDTH         : INTEGER := 256;
			
			BLOCKSIZE            : INTEGER := 4;
			
			OFFSET               : INTEGER := 8;
			
			-- Number of bits defining the BRAM address wide.
			BRAM_ADDR_WIDTH 	 : INTEGER := 10; 
			
			-- Filename of data BRAM regarding cache 1.
			DATA_FILENAME_CACHE1 : STRING := "../imem/dataCache1";
			
			-- Filename of data BRAM regarding cache 2.
			DATA_FILENAME_CACHE2 : STRING := "../imem/dataCache2";
			
			-- Filename of tag BRAM regarding cache 1.
			TAG_FILENAME_CACHE1  : STRING := "../imem/tagCache1";
			
			-- Filename of tag BRAM regarding cache 2.
			TAG_FILENAME_CACHE2  : STRING := "../imem/tagCache2";
			
			MAIN_MEMORY_FILENAME 	: STRING  := "../imem/mainMemory";
			
			-- File extension of BRAMs.
			FILE_EXTENSION       : STRING := ".imem"
		
	);
end;

architecture tests of twoWayAssociativeCache_tb is
	
	-- Constant object.
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);
	
	-- Clock and reset signal.
	signal clk, reset : STD_LOGIC := '0';
	
	-- Address word from CPU.
	signal addrCPU     : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	
	-- Data word to be written to cache or to be read from cache.
	signal dataCPU     : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
	
	-- Data word to be written to main memory or to be read from main memory.
	signal dataToMEM   : STD_LOGIC_VECTOR(BLOCKSIZE*DATA_WIDTH/2-1 downto 0) := (others=>'0');
	
	-- Signal indicates whether the main memory is ready with read or write operation.
	signal readyMEM : STD_LOGIC := '0';
	
	-- Signal indicates whether to stall the CPU or not.
	signal stallCPU : STD_LOGIC := '0';
	
	-- Signal to write the cache.
	signal wrCPU : STD_LOGIC := '0';
	
	-- Signal to read the cache.
	signal rdCPU : STD_LOGIC := '0';
	
	-- Signal counts the number of cache hits.
	signal hitCounter : INTEGER := 0;
	
	-- Signal counts the number of cache misses.
	signal missCounter : INTEGER := 0;
	
	-- Signal indicates to write the main memory or not.
	signal wrMEM : STD_LOGIC := '0';
	
	-- Signal indicates to read the main memory or not.
	signal rdMEM : STD_LOGIC := '0';
	
	signal addrMEM : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);

begin
	
	twoWayAssociativeCache: entity work.twoWayAssociativeCache
		generic map(
			REPLACEMENT_STRATEGY => REPLACEMENT_STRATEGY,
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			OFFSET               => OFFSET,
			DATA_FILENAME_CACHE1 => DATA_FILENAME_CACHE1,
			DATA_FILENAME_CACHE2 => DATA_FILENAME_CACHE2,
			TAG_FILENAME_CACHE1  => TAG_FILENAME_CACHE1,
			TAG_FILENAME_CACHE2  => TAG_FILENAME_CACHE2,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			reset 		=> reset,
			clk         => clk,
			addrCPU     => addrCPU,
			dataCPU     => dataCPU,
			dataToMEM   => dataToMEM,
			readyMEM    => readyMEM,
			stallCPU    => stallCPU,
			wrCPU       => wrCPU,
			rdCPU       => rdCPU,
			hitCounter  => hitCounter,
			missCounter => missCounter,
			wrMEM       => wrMEM,
			addrMEM     => addrMEM,
			rdMEM       => rdMEM
		);
	
	
	-- ------------------------------------------------------------------------------------------
	-- Create main memory.
	-- ------------------------------------------------------------------------------------------
	mainMemoryController : entity work.mainMemory
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			BLOCKSIZE            => BLOCKSIZE/2,
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
			dataMEM  	=> dataToMEM,
			reset       => reset
		);
	
	
	
	-- ------------------------------------------------------------------------------------------
	-- Process generates clock.
	-- ------------------------------------------------------------------------------------------
	clockProcess : process
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end process;
	
	
	-- ------------------------------------------------------------------------------------------
	-- Process executes test cases.
	-- ------------------------------------------------------------------------------------------
	testProcess : process
	begin
		wait for 20 ns;
		--dataCPU <= (others=>'1');
		addrCPU(MEMORY_ADDRESS_WIDTH-1) <= '1';
		wait until rising_edge(clk);
		rdCPU <= '1';
		wait until rising_edge(clk);
		rdCPU <= '0';
		wait for 50 ns;
		
		wait for 200 ns;
		report "End of test bench." severity FAILURE;
	end process;
		
	
end;
	