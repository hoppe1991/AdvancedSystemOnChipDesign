--------------------------------------------------------------------------------
-- filename : directMappedCache.vhd
-- author   : Hoppe
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
use work.cache_pkg.all;
use work.mips_pkg.all;

-- =============================================================================
-- Define the generic variables and ports of the entity.
-- =============================================================================
entity directMappedCache is
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
		TAGFILENAME          : STRING  := "../imem/tagFileName";

		-- Filename for data BRAM.
		DATAFILENAME         : STRING  := "../imem/dataFileName";

		-- File extension for BRAM.
		FILE_EXTENSION       : STRING  := ".txt"
	);

	port(
		-- Clock signal is used for BRAM.
		clk              : in    STD_LOGIC;

		-- Reset signal to reset the cache.
		reset            : in    STD_LOGIC;
		addrCPU          : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0); -- Memory address from CPU is divided into block address and block offset.
		dataCPU_in       : in    STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.
		dataCPU_out      : out   STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.
		dataMEM          : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0); -- Data from memory to cache or from cache to memory.
		cacheBlockLine_in : in STD_LOGIC_VECTOR( (BLOCKSIZE*DATA_WIDTH)-1 downto 0 );
		cacheBlockLine_out : out STD_LOGIC_VECTOR( (BLOCKSIZE*DATA_WIDTH)-1 downto 0 );

		wrCacheBlockLine : in    STD_LOGIC; -- Write signal identifies whether a complete cache block should be written into cache.
		rd               : in    STD_LOGIC; -- Read signal identifies to read data from the cache.
		wr               : in    STD_LOGIC; -- Write signal identifies to write data into the cache.

		valid            : inout STD_LOGIC; -- Identify whether the cache block/line contains valid content.
		dirty_in         : in    STD_LOGIC; -- Identify whether the cache block/line is changed as against the main memory.
		dirty_out        : out   STD_LOGIC; -- Identify whether the cache block/line is changed as against the main memory.
		setValid         : in    STD_LOGIC; -- Identify whether the valid bit should be set.
		setDirty         : in    STD_LOGIC; -- Identify whether the dirty bit should be set.

		hit              : out   STD_LOGIC -- Signal identify whether data are available in the cache ('1') or not ('0').
	);

end;

--  31  ...             10   9   ...             2   1  ...         0
-- +-----------------------+-----------------------+------------------+
-- | Tag                   | Index                 | Offset           |
-- +-----------------------+-----------------------+------------------+


-- =============================================================================
-- Definition of architecture.
-- =============================================================================
architecture synth of directMappedCache is
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);

	-- Signal identifies whether a tag should be written ('1') to BRAM or should be read ('0') from BRAM.
	signal writeToTagBRAM : STD_LOGIC := '0';

	-- Cache block to be written into BRAM or to be read from BRAM.
	signal cbBramIn  : STD_LOGIC_VECTOR(config.cacheLineBits - 1 downto 0) := (others => '0');
	signal cbBramOut : STD_LOGIC_VECTOR(config.cacheLineBits - 1 downto 0) := (others => '0');
 
	signal writeToDataBRAM : STD_LOGIC := '0';
	signal index : STD_LOGIC_VECTOR(DETERMINE_NR_BITS(ADDRESSWIDTH)-1 downto 0);
	signal tagBRAM : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0);
begin
	
	-- -----------------------------------------------------------------------------
	-- The tag area should be BRAM blocks.
	-- -----------------------------------------------------------------------------
	 DirectMappedCacheCont: entity work.directMappedCacheController
	 	generic map (
		MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
		DATA_WIDTH => DATA_WIDTH,
		ADDRESSWIDTH => ADDRESSWIDTH,
		BLOCKSIZE => BLOCKSIZE,
		OFFSET => OFFSET,
		TAGFILENAME => TAGFILENAME,
		DATAFILENAME => DATAFILENAME,
		FILE_EXTENSION => FILE_EXTENSION
		)
	port map (
		clk => clk,
		reset => reset,
		
		addrCPU => addrCPU,
		dataCPU_in => dataCPU_in,
		dataCPU_out => dataCPU_out,
		dataMEM => dataMEM,
		cacheBlockLine_in => cacheBlockLine_in,
		cacheBlockLine_out => cacheBlockLine_out,
		wrCacheBlockLine => wrCacheBlockLine,
		rd => rd,
		wr => wr,
		valid => valid,
		dirty_in => dirty_in,
		dirty_out => dirty_out,
		setValid => setValid,
		setDirty => setDirty,
		hit => hit,
		writeToTagBRAM => writeToTagBRAM,
		index => index,
		tagBRAM => tagBRAM,
		cbBramIn => cbBramIn,
		cbBramOut => cbBramOut,
		writeToDataBRAM => writeToDataBRAM
	);
	 
	-- -----------------------------------------------------------------------------
	-- The tag area should be BRAM blocks.
	-- -----------------------------------------------------------------------------
	BRAMtag : entity work.bram          -- data memory
		generic map(INIT => (TAGFILENAME & FILE_EXTENSION),
			        ADDR => config.indexNrOfBits,
			        DATA => config.tagNrOfBits
		)
		port map(clk, writeToTagBRAM, index, tagBRAM, tagBRAM);

	-- -----------------------------------------------------------------------------
	-- The data area should be BRAM blocks.
	-- -----------------------------------------------------------------------------
	BRAMdata : entity work.bram         -- data memory
		generic map(INIT => (DATAFILENAME & FILE_EXTENSION),
			        ADDR => config.indexNrOfBits,
			        DATA => config.cacheLineBits,
			        MODE => WRITE_FIRST
		)
		port map(clk, writeToDataBRAM, index, cbBramIn, cbBramOut);
 
end synth;
