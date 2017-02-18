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
		DATA_FILENAME        : STRING  := "../imem/dataCache"
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
	signal rd                 : STD_LOGIC := '0';
	signal wr                 : STD_LOGIC := '0';
	signal dirty_in           : STD_LOGIC := '0';
	signal setValid           : STD_LOGIC := '0';
	signal setDirty           : STD_LOGIC := '0';
	signal cacheBlockLine_in  : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
	signal cacheBlockLine_out : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
	signal hit                : STD_LOGIC := '0';
	signal dirty_out          : STD_LOGIC := '0';
	signal valid              : STD_LOGIC := '0';
	signal wrCacheBlockLine   : STD_LOGIC := '0';
	signal dataCPU_in  		  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	signal dataCPU_out 	      : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	

begin
	myDirectMappedCache : work.directMappedCache
		port map(
			clk                => clk,
			reset              => reset,
			addrCPU            => addrCPU,
			dataCPU_in         => dataCPU,
			dataCPU_out        => dataCPU,
			dataMEM            => dataMEM,
			cacheBlockLine_in  => cacheBlockLine_in,
			cacheBlockLine_out => cacheBlockLine_out,
			wrCacheBlockLine   => wrCacheBlockLine,
			rd                 => rd,
			wr                 => wr,
			valid              => valid,
			dirty_in           => dirty_in,
			dirty_out          => dirty_out,
			setValid           => setValid,
			setDirty           => setDirty,
			hit                => hit
		);
		
		cacheContr: work.cacheController
		port map (
			hitCounter => hitCounter,
			missCounter => missCounter,
			clk => clk,
			reset => reset,
			stallCPU => stallCPU,
			rdCPU => rdCPU,
			wrCPU => wrCPU,
			addrCPU => addrCPU,
			dataCPU_in => dataCPU_in,
			dataCPU_out => dataCPU_out,
			readyMEM => readyMEM,
			rdMEM => rdMEM,
			wrMEM => wrMEM,
			addrMEM => addrMEM,
			dataMEM => dataMEM
		);
		
end rtl;