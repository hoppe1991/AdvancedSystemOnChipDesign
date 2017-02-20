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
		dataMEM_in  : in STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0);
		dataMEM_out : out STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0)
	);
end;

architecture rtl of cache is
	signal rdCache                 : STD_LOGIC := '0';
	signal wrCache                 : STD_LOGIC := '0';
	signal dirty_in           : STD_LOGIC := '0';
	signal dirty : STD_LOGIC := '0';
	signal setValid           : STD_LOGIC := '0';
	signal setDirty           : STD_LOGIC := '0';
	signal cacheBlockLine  : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
	signal cacheBlockLine_in  : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
	signal cacheBlockLine_out : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
	signal hit                : STD_LOGIC := '0';
	signal dirty_out          : STD_LOGIC := '0';
	signal valid              : STD_LOGIC := '0';
	signal wrCacheBlockLine   : STD_LOGIC := '0';
	signal dataCPU_in  		  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	signal dataCPU_out 	      : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	signal dataMEMcache : STD_LOGIC_VECTOR(BLOCKSIZE*DATA_WIDTH-1 downto 0);
	signal dataCPUcache : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

begin
	myDirectMappedCache : entity work.directMappedCache
	generic map (
		MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
		DATA_WIDTH => DATA_WIDTH,
		ADDRESSWIDTH => ADDRESSWIDTH,
		BLOCKSIZE => BLOCKSIZE,
		OFFSET => OFFSET,
		TAG_FILENAME => TAG_FILENAME,
		DATA_FILENAME => DATA_FILENAME,
		FILE_EXTENSION => FILE_EXTENSION 
	)
		port map(
			clk                => clk,
			reset              => reset,
			
			addrCPU            => addrCPU,
			dataCPU_in         => dataCPU,
			dataCPU_out        => dataCPU,
			dataMEM_in         => dataMEM_in,
			dataMEM_out		   => dataMEM_out,
			cacheBlockLine_in  => cacheBlockLine_in,
			cacheBlockLine_out => cacheBlockLine_out,
			wrCacheBlockLine   => wrCacheBlockLine,
			rd                 => rdCache,
			wr                 => wrCache,
			valid              => valid,
			dirty_in           => dirty_in,
			dirty_out          => dirty_out,
			setValid           => setValid,
			setDirty           => setDirty,
			hit                => hit
		);
		
		cacheContr: entity work.cacheController
		generic map (
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH => DATA_WIDTH,
			ADDRESSWIDTH => ADDRESSWIDTH,
			BLOCKSIZE => BLOCKSIZE,
			OFFSET => OFFSET
		)
		port map (
			
			-- Clock and reset signal.
			clk => clk,
			reset => reset,
			
			-- Ports regarding Direct Mapped Cache.
			rdCache => rdCache,
			wrCache => wrCache,
			wrCacheLine => wrCacheBlockLine,
			cacheBlockLine => cacheBlockLine,
			valid => valid,
			dirty => dirty,
			setValid => setValid,
			setDirty => setDirty,
			hitFromCache => hit,
			dataMEMcache => dataMEMcache,
			dataCPUcache => dataCPUcache,
		 
			-- Ports regarding CPU.
			hitCounter => hitCounter,
			missCounter => missCounter,
			stallCPU => stallCPU,
			rdCPU => rdCPU,
			wrCPU => wrCPU,
			addrCPU => addrCPU,
			dataCPU => dataCPU_in,
			
			-- Ports regarding MEM.
			readyMEM => readyMEM,
			rdMEM => rdMEM,
			wrMEM => wrMEM,
			addrMEM => addrMEM,
			dataMEM_in => dataMEM_in,
			dataMEM_out => dataMEM_out
		);
		
end rtl;