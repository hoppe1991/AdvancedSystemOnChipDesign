--------------------------------------------------------------------------------
-- filename : twoWayAssociativeCache.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 21/02/17
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Include packages.
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =============================================================================
-- Define the generic variables and ports of the entity.
-- =============================================================================
entity twoWayAssociativeCache is
	generic(
		-- Memory address is 32-bit wide.
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Instruction and data words of the MIPS are 32-bit wide, but other CPUs
		-- have quite different instruction word widths.
		DATA_WIDTH           : integer := 32;

		-- Is the depth of the cache, i.e. the number of cache blocks / lines.
		ADDRESSWIDTH         : integer := 256;

		-- Number of words that a block contains and which are simultaneously loaded from the main memory into cache.
		BLOCKSIZE            : integer := 4;

		-- The number of bits specifies the smallest unit that can be selected
		-- in the cache. Byte (8 Bits) access should be possible.
		OFFSET               : integer := 8;

		-- Filename for tag BRAM.
		TAG_FILENAME         : STRING  := "../imem/tagFileName";

		-- Filename for data BRAM.
		DATA_FILENAME        : STRING  := "../imem/dataFileName";

		-- File extension for BRAM.
		FILE_EXTENSION       : STRING  := ".txt"
	);

	port(
		-- Clock signal is used for BRAM.
		clk            : in    STD_LOGIC;

		-- Reset signal to reset the cache.
		reset          : in    STD_LOGIC;
		addrCPU        : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0); -- Memory address from CPU is divided into block address and block offset.
		dataCPU        : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.


		dataMEM        : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0); -- Data from memory to cache or from cache to memory.
		cacheBlockLine : inout STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
		wrCBLine       : in    STD_LOGIC; -- Write signal identifies whether a complete cache block should be written into cache.
		rdCBLine       : in    STD_LOGIC; -- Read signal identifies whether a complete cache block should be read from cache.
		rdWord         : in    STD_LOGIC; -- Read signal identifies to read data from the cache.
		wrWord         : in    STD_LOGIC; -- Write signal identifies to write data into the cache.

		valid          : inout STD_LOGIC; -- Identify whether the cache block/line contains valid content.
		dirty          : inout STD_LOGIC; -- Identify whether the cache block/line is changed as against the main memory.
		setValid       : in    STD_LOGIC; -- Identify whether the valid bit should be set.
		setDirty       : in    STD_LOGIC; -- Identify whether the dirty bit should be set.

		hit            : out   STD_LOGIC -- Signal identify whether data are available in the cache ('1') or not ('0').
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
	constant BLOCKSIZE_CACHE : INTEGER := BLOCKSIZE / 2;
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
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk   => clk,
			reset => reset
		);

	GEN1 : for I in 1 to 2 generate
	GEN1_I: entity work.directMappedCache
		generic map ( 
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			BLOCKSIZE            => BLOCKSIZE_CACHE,
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
			cacheBlockLine => cacheBlockLine,
			wrCBLine       => wrCBLine,
			rdCBLine       => rdCBLine,
			rdWord         => rdWord,
			wrWord         => wrWord,
			valid          => valid,
			dirty          => dirty,
			setValid       => setValid,
			setDirty       => setDirty,
			hit            => hit
		);
		end generate GEN1;
		


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
			cacheBlockLine => cacheBlockLine,
			wrCBLine       => wrCBLine,
			rdCBLine       => rdCBLine,
			rdWord         => rdWord,
			wrWord         => wrWord,
			valid          => valid,
			dirty          => dirty,
			setValid       => setValid,
			setDirty       => setDirty,
			hit            => hit
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
			cacheBlockLine => cacheBlockLine,
			wrCBLine       => wrCBLine,
			rdCBLine       => rdCBLine,
			rdWord         => rdWord,
			wrWord         => wrWord,
			valid          => valid,
			dirty          => dirty,
			setValid       => setValid,
			setDirty       => setDirty,
			hit            => hit
		);
end rtl;
