--------------------------------------------------------------------------------
-- filename : directMappedCacheController.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
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
		OFFSET               : integer := 8
	);

	port(
		
		-- Clock and reset signal.
		clk              : in    STD_LOGIC; -- Clock signal is used for BRAM.
		reset            : in    STD_LOGIC; -- Reset signal to reset the cache.
		
		-- Ports regarding CPU and MEM.
		addrCPU          	: in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);	-- Memory address from CPU is divided into block address and block offset.
		dataCPU       	 	: inout STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); 			-- Data from CPU to cache or from cache to CPU.
		dataToMEM 		   	: out STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE-1 downto 0); -- Data from memory to cache or from cache to memory
		newCacheBlockLine 	: in STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE-1 downto 0);
		valid            	: inout STD_LOGIC; -- Identify whether the cache block/line contains valid content.
		dirty         	 	: inout STD_LOGIC; -- Identify whether the cache block/line is changed as against the main memory.
		setValid         	: in    STD_LOGIC; -- Identify whether the valid bit should be set.
		setDirty         	: in    STD_LOGIC; -- Identify whether the dirty bit should be set.
		hit 			 	: out   STD_LOGIC; -- Signal identify whether data are available in the cache ('1') or not ('0').
		
		-- Ports defines how to read or write the data BRAM.
		wrCBLine 	: in	STD_LOGIC; -- Write signal identifies whether a complete cache block should be written into cache.
		rdCBLine 	: in	STD_LOGIC; -- Read signal identifies whether a complete cache block should be read from cache.
		rdWord	 	: in	STD_LOGIC; -- Read signal identifies to read data word from the cache.
		wrWord   	: in	STD_LOGIC; -- Write signal identifies to write data word into the cache.
		writeMode 	: in	STD_LOGIC; -- '1' when write mode. '0' when read mode.

		-- Index determines to which line of BRAM should be written or read.
		index 		: out STD_LOGIC_VECTOR(DETERMINE_NR_BITS(ADDRESSWIDTH)-1 downto 0);
				
		-- Ports regarding BRAM tag.
		tagToBRAM 		: out STD_LOGIC_VECTOR(GET_TAG_NR_BITS( MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET )-1 downto 0);
		tagFromBRAM 	: in STD_LOGIC_VECTOR(GET_TAG_NR_BITS( MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET )-1 downto 0);
		writeToTagBRAM 	: out STD_LOGIC;
		
		-- Ports regarding BRAM data.
		writeToDataBRAM		: out STD_LOGIC;
		dataToBRAM		    : out STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE-1 downto 0);
		dataFromBRAM	    : in STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE-1 downto 0)
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
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);
	
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
		addr.offsetAsInteger := TO_INTEGER(UNSIGNED(addr.offset(3 downto 2)));
		
		if (addr.offsetAsInteger > 3 or addr.offsetAsInteger < 0) then
			report "offset as integer is false. " & INTEGER'IMAGE(addr.offsetAsInteger) severity FAILURE; 
		end if;
	
		if (addr.indexAsInteger > 256 or addr.indexAsInteger < 0) then
			report "index as integer is false. " & INTEGER'IMAGE(addr.indexAsInteger) severity FAILURE;
		end if;
		
		return addr;
	end function;

	signal memoryAddress : MEMORY_ADDRESS;
	
	type TAG_VECTOR is ARRAY(1 downto 0) of STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0);
	function TAG_VECTOR_INIT return TAG_VECTOR is
		variable t : TAG_VECTOR;
	begin
		t(0) := (others=>'0');
		t(1) := (others=>'0');
		return t;
	end function;
	
	signal tag_delayed : TAG_VECTOR := TAG_VECTOR_INIT;
	  	 
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
	
	signal myTestSignal : STD_LOGIC := '0';
	
	
  	type CACHE_MODE is ( 
  		READ_DATA,      -- Indicates to read a single word from the cache line.
  		READ_LINE,      -- Indicates to read a complete cache line.
  		WRITE_DATA,     -- Indicates to write a single word from the cache line.
  		WRITE_LINE,     -- Indicates to write a complete cache line.
  		NOTHING	        -- Do nothing.
  	);
  	signal myCacheMode : CACHE_MODE := NOTHING;
	
	-- -----------------------------------------------------------------------------------------------------------
	-- The function determines the start index of the data word in the cache line.
	-- -----------------------------------------------------------------------------------------------------------
	function GET_START_INDEX( offset : in INTEGER ) return INTEGER is
		variable index : INTEGER := 0;
	begin
		index := config.cacheLineBits-1-(DATA_WIDTH*offset);
		return index;
	end function;
	
	-- -----------------------------------------------------------------------------------------------------------
	-- The function determines the end index of the data word in the cache line.
	-- -----------------------------------------------------------------------------------------------------------
	function GET_END_INDEX( offset : in INTEGER ) return INTEGER is
		variable index : INTEGER := 0;
	begin
		index := config.cacheLineBits-1-(DATA_WIDTH*offset)-DATA_WIDTH+1;
		return index;
	end function;
	
	type CACHE_BLOCK_LINE is ARRAY ( BLOCKSIZE-1 downto 0) of STD_LOGIC_VECTOR( DATA_WIDTH-1 downto 0 );
	signal blockLineFromBRAM : CACHE_BLOCK_LINE;
	signal blockLineToBRAM : CACHE_BLOCK_LINE;
	function TO_CACHE_BLOCK_LINE( ARG : in STD_LOGIC_VECTOR ) return CACHE_BLOCK_LINE is
		variable b : CACHE_BLOCK_LINE;
		variable s : INTEGER;
		variable t : INTEGER;
	begin
		for I in 0 to BLOCKSIZE-1 loop
			s := GET_START_INDEX( I );
			t := GET_END_INDEX( I );
			b(I) := ARG( s downto t );
		end loop;
		return b;
	end function;
	function TO_STD_LOGIC_VECTOR( ARG : in CACHE_BLOCK_LINE ) return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR( DATA_WIDTH*BLOCKSIZE-1 downto 0 ) := (others=>'0');
		variable s, t : INTEGER;
	begin 
		for I in 0 to BLOCKSIZE-1 loop
			s := GET_START_INDEX( I );
			t := GET_END_INDEX( I );
			v(s downto t) := ARG(I);
		end loop;
		return v;
	end function;
	function SET_BLOCK_LINE( b_in : in CACHE_BLOCK_LINE; data : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); offset : in INTEGER ) return CACHE_BLOCK_LINE is
		variable b : CACHE_BLOCK_LINE;
	begin
		for I in 0 to BLOCKSIZE-1 loop
		if I=offset then
			b(I):=data;
		else
			b(I):=b_in(I);
		end if;
		end loop;
		return b;
	end function;
	
	
	function GET_VALIDBITS( index_in : in INTEGER; validBits_in : in STD_LOGIC_VECTOR(ADDRESSWIDTH - 1 downto 0)) return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR(ADDRESSWIDTH - 1 downto 0) := (others=>'0');
	begin
		v := validBits_in;
		v(index_in) := '1';
		return v;
	end;
	
	function GET_MODIFIED_DIRTYBITSVECTOR( index_in : in INTEGER; dirtyBits_in : in STD_LOGIC_VECTOR(ADDRESSWIDTH-1 downto 0); value_in : in STD_LOGIC) return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR(ADDRESSWIDTH-1 downto 0) := (others=>'0');
	begin
		v := dirtyBits_in;
		v(index_in) := value_in;
		return v;
	end;
	 
	signal tag_tmp1, tag_tmp2 : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) := (others=>'0');

-----------------------------------------------------------------------------------
begin
	
	-- -----------------------------------------------------------------------------
	-- Determines the read/write mode.
	-- -----------------------------------------------------------------------------
	myCacheMode <= READ_DATA  when wrWord='0' AND rdWord='1' AND wrCBLine='0' AND rdCBLine='0' else 
	 	           WRITE_DATA when wrWord='1' AND rdWord='0' AND wrCBLine='0' AND rdCBLine='0' else 
	 	           READ_LINE  when rdWord='0' and wrWord='0' AND wrCBLine='0' AND rdCBLine='1' else
	 	           WRITE_LINE when rdWord='0' AND wrWord='0' AND wrCBLine='1' AND rdCBLine='0' else 
	 	           NOTHING;

	-- -----------------------------------------------------------------------------
	-- Determine the offset, index and tag of the address signal.
	-- -----------------------------------------------------------------------------
	memoryAddress <= TO_MEMORY_ADDRESS( addrCPU ); 
	index 		  <= memoryAddress.index;

	-- -----------------------------------------------------------------------------
	-- Determine the valid bit.
	-- -----------------------------------------------------------------------------
	myTestSignal <= '1' when (memoryAddress.indexAsInteger<0 or memoryAddress.indexAsInteger>ADDRESSWIDTH) and writeToDataBRAMs='0' else '0';
	valid <= validBits(memoryAddress.indexAsInteger) when setValid = '0' else 
	         'Z';
	dirty <= dirtyBits(memoryAddress.indexAsInteger) when setDirty = '0' and rdWord='1' and reset = '0' else
	         'Z' when setDirty='1';

	-- -----------------------------------------------------------------------------
	-- Reset directly the valid bits and the dirty bits when to reset.
	-- Otherwise, set the correspondent dirty bit and valid bit.
	-- -----------------------------------------------------------------------------
	validBits <= (others=>'0') when reset='1' else
				 GET_VALIDBITS(memoryAddress.indexAsInteger, validBits) when writeToDataBRAMs='1';
	dirtyBits <= (others=>'0') when reset='1' else
		         GET_MODIFIED_DIRTYBITSVECTOR( memoryAddress.indexAsInteger, dirtyBits, dirty) when setDirty='1';
	-- -----------------------------------------------------------------------------
	-- Determine whether a cache block/line should be read or written.
	-- -----------------------------------------------------------------------------
	dataToMEM <= dataFromBRAM when myCacheMode=WRITE_DATA else
				 dataFromBRAM when myCacheMode=READ_DATA;

	-- -----------------------------------------------------------------------------
	-- Determine the new tag value to save in correspondent BRAM.
	-- -----------------------------------------------------------------------------
	tagToBRAM <= memoryAddress.tag when myCacheMode=WRITE_DATA else 
	             memoryAddress.tag when myCacheMode=WRITE_LINE;

	-- -----------------------------------------------------------------------------
	-- Determine the start index and end index of the correspondent word in the cache line.
	-- -----------------------------------------------------------------------------
	dataStartIndex <= GET_START_INDEX( memoryAddress.offsetAsInteger );
	dataEndIndex   <= GET_END_INDEX( memoryAddress.offsetAsInteger );

	-- -----------------------------------------------------------------------------
	-- Determine the new cache block line.
	-- -----------------------------------------------------------------------------

	blockLineToBRAM <= SET_BLOCK_LINE( blockLineFromBRAM, dataCPU, memoryAddress.offsetAsInteger ) when myCacheMode=WRITE_DATA else
					   blockLineFromBRAM;
	blockLineFromBRAM <=  TO_CACHE_BLOCK_LINE( dataFromBRAM );
	dataToBRAM <= newCacheBlockLine when myCacheMode=WRITE_LINE else 
	              TO_STD_LOGIC_VECTOR( blockLineToBRAM ) when myCacheMode=WRITE_DATA;

	dataCPU <= 
			   (others=>'0') when myCacheMode=READ_DATA and not(valid = '1' AND tagsAreEqual = '1') else
			   (others=>'Z') when writeMode='1' else
			   (blockLineFromBRAM(memoryAddress.offsetAsInteger)) when myCacheMode=READ_DATA else
		       (others=>'Z');

	-- -----------------------------------------------------------------------------
	-- Check whether to read or write the data BRAM.
	-- -----------------------------------------------------------------------------
	 writeToDataBRAMs <= '0' when myCacheMode=READ_DATA else 
	 	                 '1' when myCacheMode=WRITE_DATA else 
	 	                 '1' when myCacheMode=WRITE_LINE else
	 	                 '0' when myCacheMode=READ_LINE else 
	 	                 '0';
	 writeToDataBRAM <= writeToDataBRAMs;
	 writeToTagBRAM <= writeToDataBRAMs;
	  
	-- -----------------------------------------------------------------------------
	-- The hit signal is supposed to be an asynchronous signal.
	-- -----------------------------------------------------------------------------
	tag_delayed(0) <= memoryAddress.tag when rising_edge(clk);
	tag_delayed(1) <= tag_delayed(0) when rising_edge(clk);
	tag_tmp1 <= tagFromBRAM;
	tag_tmp2 <= memoryAddress.tag;
	tagsAreEqual <= '1' when tagFromBRAM=memoryAddress.tag else '0';
	hit 		 <= '1' when valid = '1' AND tagsAreEqual = '1' else '0';

end synth;
