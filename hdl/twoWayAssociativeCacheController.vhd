--------------------------------------------------------------------------------
-- filename : twoWayAssociativeCacheController.vhd
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
entity twoWayAssociativeCacheController is
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
		FILE_EXTENSION       : STRING  := ".txt";
		REPLACEMENT_STRATEGY : replacementStrategy
	);

	port(
		-- Clock signal is used for BRAM.
		clk                                : in    STD_LOGIC;
		hit                                : out   STD_LOGIC_VECTOR(1 downto 0);
		wrCBLine, rdCBLine, rdWord, wrWord : out   STD_LOGIC_VECTOR(1 downto 0);
		valid, dirty, setValid, setDirty   : out   STD_LOGIC_VECTOR(1 downto 0);
		newCacheBlockLine1                 : out   STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0) := (others => '0');
		newCacheBlockLine0                 : out   STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0) := (others => '0');
		writeMode             			   : out   STD_LOGIC_VECTOR(1 downto 0);
		addrCPU                            : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0); -- Memory address from CPU is divided into block address and block offset.
		dataCPU                            : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.
		dataCPU0                           : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.
		dataCPU1                           : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.

		dataToMEM                            : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0); -- Data from memory to cache or from cache to memory.
		readyMEM                           : in    STD_LOGIC; -- Signal identifies whether the main memory is ready.
		stallCPU                           : out   STD_LOGIC; -- Signal identifies whether to stall the CPU or not.

		wrCPU                              : in    STD_LOGIC; -- Write signal identifies whether a complete cache block should be written into cache.
		rdCPU                              : in    STD_LOGIC; -- Read signal identifies whether a complete cache block should be read from cache.

		hitCounter                         : out   INTEGER; -- Signal counts the number of cache hits.
		missCounter                        : out   INTEGER; -- Signal counts the number of cache misses.
		wrMEM                              : out   STD_LOGIC; -- Read signal identifies to read data from the cache.
		rdMEM                              : out   STD_LOGIC -- Write signal identifies to write data into the cache.
	);
end;

-- =============================================================================
-- Definition of architecture.
-- =============================================================================
architecture synth of twoWayAssociativeCacheController is
begin
	
	-- TODO Implementation of FSM.
end synth;
