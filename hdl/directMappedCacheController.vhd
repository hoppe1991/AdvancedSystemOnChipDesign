--------------------------------------------------------------------------------
-- filename : directMappedCacheController.vhd
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
entity directMappedCacheController is
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

		hit              : out   STD_LOGIC; -- Signal identify whether data are available in the cache ('1') or not ('0').
		
		writeToTagBRAM : out STD_LOGIC;
		index : out STD_LOGIC_VECTOR(DETERMINE_NR_BITS(ADDRESSWIDTH)-1 downto 0);
		tagBRAM_in : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-DETERMINE_NR_BITS(ADDRESSWIDTH)-DETERMINE_NR_BITS(BLOCKSIZE*DATA_WIDTH/OFFSET)-1 downto 0);
		tagBRAM_out : out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-DETERMINE_NR_BITS(ADDRESSWIDTH)-DETERMINE_NR_BITS(BLOCKSIZE*DATA_WIDTH/OFFSET)-1 downto 0);
	
		cbBramIn  : out STD_LOGIC_VECTOR(BLOCKSIZE*DATA_WIDTH-1 downto 0);
		cbBramOut : in STD_LOGIC_VECTOR(BLOCKSIZE*DATA_WIDTH-1 downto 0);
		writeToDataBRAM : out STD_LOGIC
	
	
	);

end;

--  31  ...             10   9   ...             2   1  ...         0
-- +-----------------------+-----------------------+------------------+
-- | Tag                   | Index                 | Offset           |
-- +-----------------------+-----------------------+------------------+


-- =============================================================================
-- Definition of architecture.
-- =============================================================================
architecture synth of directMappedCacheController is
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);

	type MEMORY_ADDRESS is record
		tag    : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0);
		index  : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0);
		offset : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0);
		indexAsInteger : INTEGER;
		offsetAsInteger : INTEGER;
	end record;

	function TO_MEMORY_ADDRESS(ARG : in STD_LOGIC_VECTOR) return MEMORY_ADDRESS is
		variable addr : MEMORY_ADDRESS;
	begin
		addr.tag    := ARG(config.tagIndexH downto config.tagIndexL);
		addr.index  := ARG(config.IndexIndexH downto config.IndexIndexL);
		addr.offset := ARG(config.offsetIndexH downto config.offsetIndexL);
		addr.indexAsInteger := TO_INTEGER(UNSIGNED(addr.index));
		addr.offsetAsInteger := TO_INTEGER(UNSIGNED(addr.offset));
		return addr;
	end function;
	
	signal memoryAddress : MEMORY_ADDRESS;
   
	-- Bit string contains a complete cache line.
	signal cacheLine : STD_LOGIC_VECTOR(config.cacheLineBits - 1 downto 0) := (others => '0');
  	
	signal myCacheLineBits : INTEGER := config.cacheLineBits;

	-- Bit string contains for each cache block the correspondent valid bit.
	signal validBits : STD_LOGIC_VECTOR(ADDRESSWIDTH - 1 downto 0) := (others => '0');

	-- Bit string contains for each cache block the correspondent dirty bit.
	-- 1 --> block line is modified, 0 --> block line is unmodified.
	signal dirtyBits : STD_LOGIC_VECTOR(ADDRESSWIDTH - 1 downto 0) := (others => '0');

	-- Signal identifies whether the tag of a cache block and the tag of the given memory address are equal.
	signal tagsAreEqual : STD_LOGIC := '0';

	-- Start index of the word in the cache line.
	signal dataStartIndex : INTEGER := 0;

	-- End index of the word in the cache line.
	signal dataEndIndex : INTEGER := 0;
	
	signal writeToDataBRAMs : STD_LOGIC := '0';
-----------------------------------------------------------------------------------
begin

	-- -----------------------------------------------------------------------------
	-- Determine the offset, index and tag of the address signal.
	-- -----------------------------------------------------------------------------
	memoryAddress <= TO_MEMORY_ADDRESS( addrCPU ); 
	index <= memoryAddress.index;

	-- -----------------------------------------------------------------------------
	-- Determine the valid bit.
	-- -----------------------------------------------------------------------------
	valid     <= validBits(memoryAddress.indexAsInteger) when setValid = '0' and rising_edge(clk);
	dirty_out <= dirtyBits(memoryAddress.indexAsInteger) when setDirty = '0' and rising_edge(clk) and reset = '0';

	-- -----------------------------------------------------------------------------
	-- Set the valid bit and the dirty bit.
	-- -----------------------------------------------------------------------------
	process(clk, reset, memoryAddress.indexAsInteger, writeToDataBRAMs)
	begin
		if rising_edge(clk) and reset='1' then
			validBits <= (others=>'0');
		elsif (writeToDataBRAMs='1') then
			validBits(memoryAddress.indexAsInteger) <= '1';
		end if;
	end process;
	
	dirtyBits(memoryAddress.indexAsInteger) <= dirty_in when setDirty = '1' and rising_edge(clk) else '0' when reset = '1' and rising_edge(clk);

	-- -----------------------------------------------------------------------------
	-- Check whether the tags are equal.
	-- -----------------------------------------------------------------------------
	tagsAreEqual <= '1' when tagBRAM_in = memoryAddress.tag else '0';

	-- -----------------------------------------------------------------------------
	-- Determine whether a cache block/line should be read or written.
	-- -----------------------------------------------------------------------------
	cacheBlockLine_out <= cbBramOut when rd = '1' AND wr = '0' AND wrCacheBlockLine = '0';

	-- -----------------------------------------------------------------------------
	-- Determine whether a tag should be read or written.
	-- -----------------------------------------------------------------------------

	tagBRAM_out <= memoryAddress.tag when rd = '0' AND wr = '1' AND wrCacheBlockLine = '0' else memoryAddress.tag when rd = '0' AND wr = '0' AND wrCacheBlockLine = '1';

	-- -----------------------------------------------------------------------------
	-- Determine the start index and end index of the correspondent word in the cache line.
	-- -----------------------------------------------------------------------------
	dataStartIndex <= config.cacheLineBits-1-DATA_WIDTH * memoryAddress.offsetAsInteger;
	dataEndIndex   <= dataStartIndex - DATA_WIDTH + 1;

	-- -----------------------------------------------------------------------------
	-- Determine the new cache block line.
	-- -----------------------------------------------------------------------------
	cbBramIn <= 
		cacheBlockLine_in when writeToDataBRAMs='0' and wr='0' and rd='0' and wrCacheBlockLine='1' and rising_edge(clk) else
		dataCPU_in & cbBramOut(dataEndIndex - 1 downto 0) when writeToDataBRAMs = '1' AND memoryAddress.offsetAsInteger = 0 AND rising_edge(clk) else 
		cbBramOut(config.cacheLineBits - 1 downto dataStartIndex + 1) & dataCPU_in when writeToDataBRAMs = '1' AND memoryAddress.offsetAsInteger = (BLOCKSIZE - 1) AND rising_edge(clk) else
		cbBramOut(config.cacheLineBits - 1 downto dataStartIndex + 1) & dataCPU_in & cbBramOut(dataEndIndex - 1 downto 0) when writeToDataBRAMs = '1' AND rising_edge(clk);

	-- -----------------------------------------------------------------------------
	-- Check whether to read or write the data BRAM.
	-- -----------------------------------------------------------------------------
	
	
	 writeToDataBRAMs <= '0' when wr = '0' AND rd = '1' AND wrCacheBlockLine = '0' else 
	 	                 '1' when wr = '1' AND rd = '0' AND wrCacheBlockLine = '0' else 
	 	                 wrCacheBlockLine when rd = '0' and wr = '0' else 
	 	                 'U';
	 writeToDataBRAM <= writeToDataBRAMs;
	 writeToTagBRAM <= writeToDataBRAMs;
	-- -----------------------------------------------------------------------------
	-- Determine the output data signal, which will be sent to CPU.
	-- -----------------------------------------------------------------------------                   
	dataCPU_out <= cbBramOut(127 downto 96) when wr = '0' and rd = '1' and dataStartIndex=127 else
				   cbBramOut(95 downto 64) when wr = '0' and rd = '1' and dataStartIndex=95 else
				   cbBramOut(63 downto 32) when wr = '0' and rd = '1' and dataStartIndex=63 else
				   cbBramOut(31 downto 0) when wr = '0' and rd = '1' and dataStartIndex=31 else
				   dataCPU_in when wr = '1' and rd = '0' else
				   dataCPU_in when wr = '0' and rd = '0' else (others => 'U'); -- TODO 

	-- -----------------------------------------------------------------------------
	-- The hit signal is supposed to be an asynchronous signal.
	-- -----------------------------------------------------------------------------
	hit <= '1' when valid = '1' AND tagsAreEqual = '1' else '0';

end synth;
