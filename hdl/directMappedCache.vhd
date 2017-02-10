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
use work.my_pkg.all;
 
-- =============================================================================
-- Define the generic variables and ports of the entity.
-- =============================================================================
entity directMappedCache is
	generic (
		-- Memory address is 32-bit wide.
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;
		
		-- Instruction and data words of the MIPS are 32-bit wide, but other CPUs
      	-- have quite different instruction word widths.
      	DATA_WIDTH     : integer := 32;
      	
      	-- Is the depth of the cache, i.e. the number of cache blocks / lines.
      	ADDRESSWIDTH  : integer := 256;
      	
      	-- Number of words that a block contains and which are simultaneously loaded from the main memory into cache.
		BLOCKSIZE     : integer := 4; 
		
		-- The number of bits specifies the smallest unit that can be selected
		-- in the cache. Byte (8 Bits) access should be possible.
		OFFSET        : integer := 8;
		
		-- Filename for tag BRAM.
      	TAGFILENAME  : STRING := "../imem/tagFileName";
      	
      	-- Filename for data BRAM.
      	DATAFILENAME : STRING := "../imem/dataFileName";
      	
      	-- File extension for BRAM.
      	FILE_EXTENSION : STRING := ".txt"
    );

  port (
         -- Clock signal is used for BRAM.
         clk : in STD_LOGIC;
         
         -- Reset signal to reset the cache.
         reset : in STD_LOGIC;
         
         addrCPU     :  in STD_LOGIC_VECTOR( MEMORY_ADDRESS_WIDTH-1 downto 0 ); -- Memory address from CPU is divided into block address and block offset.
         dataCPU_in  :  in STD_LOGIC_VECTOR( DATA_WIDTH-1 downto 0 ); -- Data from CPU to cache or from cache to CPU.
         dataCPU_out : out STD_LOGIC_VECTOR( DATA_WIDTH-1 downto 0 ); -- Data from CPU to cache or from cache to CPU.
         dataMEM : inout STD_LOGIC_VECTOR( DATA_WIDTH-1 downto 0 ); -- Data from memory to cache or from cache to memory.
         cacheBlockLine : inout STD_LOGIC_VECTOR( (BLOCKSIZE * DATA_WIDTH)-1 downto 0 ); -- Cache block line. 
         
         wrCacheBlockLine	: in STD_LOGIC; -- Write signal identifies whether a complete cache block should be written into cache.
         rd					: in STD_LOGIC; -- Read signal identifies to read data from the cache.
         wr      			: in STD_LOGIC; -- Write signal identifies to write data into the cache.
         
         valid : inout STD_LOGIC; -- Identify whether the cache block/line contains valid content.
         dirty : inout STD_LOGIC; -- Identify whether the cache block/line is changed as against the main memory.
         setValid : in STD_LOGIC; -- Identify whether the valid bit should be set.
         setDirty : in STD_LOGIC; -- Identify whether the dirty bit should be set.

         hit : out STD_LOGIC -- Signal identify whether data are available in the cache ('1') or not ('0').
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

constant indexNrOfBits  : INTEGER := DETERMINE_NR_BITS( ADDRESSWIDTH );
constant offsetNrOfBits : INTEGER := DETERMINE_NR_BITS( BLOCKSIZE * DATA_WIDTH / OFFSET );
constant offsetBlockNrOfBits : INTEGER := DETERMINE_NR_BITS( BLOCKSIZE );
constant offsetByteNrOfBits : INTEGER := DETERMINE_NR_BITS( DATA_WIDTH / OFFSET );
constant tagNrOfBits    : INTEGER := MEMORY_ADDRESS_WIDTH - indexNrOfBits - offsetNrOfBits;
constant cacheLineBits  : INTEGER := BLOCKSIZE * DATA_WIDTH;

constant tagIndexH    : INTEGER := offsetNrOfBits + indexNrOfBits + tagNrOfBits - 1;
constant tagIndexL    : INTEGER := offsetNrOfBits + indexNrOfBits;
constant indexIndexH  : INTEGER := offsetNrOfBits + indexNrOfBits - 1;
constant indexIndexL  : INTEGER := offsetNrOfBits;
constant offsetIndexH : INTEGER := offsetNrOfBits - 1;
constant offsetIndexL : INTEGER := 0;

-- Bit string contains the index.
signal indexV  : STD_LOGIC_VECTOR( indexNrOfBits-1 downto 0) := (others => '0');

-- Index as integer value.
signal indexI  : INTEGER := 0;

-- Bit string contains the offset.
signal offsetV : STD_LOGIC_VECTOR( offsetNrOfBits-1 downto 0) := (others => '0');

-- Offset as integer value.
signal offsetI : INTEGER := 0;

-- Bit string contains the tag.
signal tagV    : STD_LOGIC_VECTOR( tagNrOfBits-1 downto 0 ) := (others => '0');

-- Bit string contains a complete cache line.
signal cacheLine : STD_LOGIC_VECTOR( cacheLineBits-1 downto 0 ) := (others => '0');

-- Bit string contains tag to be written or read from BRAM.
signal tagBramIn  : STD_LOGIC_VECTOR( tagNrOfBits-1 downto 0 ) := (others => '0');
signal tagBramOut : STD_LOGIC_VECTOR( tagNrOfBits-1 downto 0 ) := (others => '0');

-- Signal identifies whether a tag should be written ('1') to BRAM or should be read ('0') from BRAM.
signal writeToTagBRAM : STD_LOGIC := '0';

-- Cache block to be written into BRAM or to be read from BRAM.
signal cacheBlockBramIn  : STD_LOGIC_VECTOR( cacheLineBits-1 downto 0 ) := (others => '0');
signal cacheBlockBramOut : STD_LOGIC_VECTOR( cacheLineBits-1 downto 0 ) := (others => '0');

signal writeToDataBRAM : STD_LOGIC := '0';
signal writeToDataBRAMHelper : STD_LOGIC := '0';

signal validBits : STD_LOGIC_VECTOR( ADDRESSWIDTH-1 downto 0) := (others => '0');
signal dirtyBits : STD_LOGIC_VECTOR( ADDRESSWIDTH-1 downto 0) := (others => '0');
signal tagsAreEqual : STD_LOGIC := '0';

signal dataStartIndex : INTEGER := 0;
signal dataEndIndex : INTEGER := 0;

signal addrDataBram : INTEGER := 0;
signal dataDataBram : Integer := 0;


signal testA : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0');
signal testB : STD_LOGIC_VECTOR( cacheLineBits-OFFSET-1 downto 0 ) := (others => '0');

signal tmpWrite : STD_LOGIC := '0';
signal dataTMPHELPER : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := "11111111";

signal dataRest96 : STD_LOGIC_VECTOR( cacheLineBits - DATA_WIDTH - 1 downto 0 ) := (others=>'0');
signal dataRest32 : STD_LOGIC_VECTOR( 32 - 1 downto 0 ) := (others=>'0');
signal dataRest64 : STD_LOGIC_VECTOR( 64 - 1 downto 0 ) := (others=>'0');
--------------

begin

-- -----------------------------------------------------------------------------
-- The tag area should be BRAM blocks.
-- -----------------------------------------------------------------------------
BRAMtag:  entity work.bram   -- data memory
          generic map ( INIT =>  (TAGFILENAME & FILE_EXTENSION),
                        ADDR => indexNrOfBits,
                        DATA => tagNrOfBits
          )
          port    map ( clk, writeToTagBRAM, IndexV, tagBramIn, tagBramOut);

-- -----------------------------------------------------------------------------
-- The data area should be BRAM blocks.
-- -----------------------------------------------------------------------------
BRAMdata:   entity work.bram   -- data memory
            generic map ( INIT =>  (DATAFILENAME & FILE_EXTENSION),
                          ADDR => indexNrOfBits,
                          DATA => cacheLineBits
                          )
            port map ( clk, writeToDataBRAM, indexV, cacheBlockBramIn, cacheBlockBramOut);


-- -----------------------------------------------------------------------------
-- Determine the offset, index and tag of the address signal.
-- -----------------------------------------------------------------------------
offsetV <= addrCPU( offsetIndexH downto offsetIndexL );
offsetI <= TO_INTEGER( SIGNED( offsetV ));
indexV  <= addrCPU( indexIndexH  downto indexIndexL );
indexI  <= TO_INTEGER( SIGNED( indexV ) );
tagV    <= addrCPU( tagIndexH    downto tagIndexL );


-- -----------------------------------------------------------------------------
-- Determine the valid bit.
-- -----------------------------------------------------------------------------
valid <= validBits( indexI ) when setValid='0' and rising_edge( clk );
dirty <= dirtyBits( indexI ) when setValid='0' and rising_edge( clk );

-- -----------------------------------------------------------------------------
-- Set the valid bit and the dirty bit.
-- -----------------------------------------------------------------------------
validBits( indexI ) <= valid when setValid='1' and rising_edge( clk ) else
					   '0' when reset='1' and rising_edge( clk );
					   
dirtyBits( indexI ) <= dirty when setDirty='1' and rising_edge( clk ) else
						'0' when reset='1' and rising_edge( clk );

-- -----------------------------------------------------------------------------
-- Check whether the tags are equal.
-- -----------------------------------------------------------------------------
tagsAreEqual <= '1' when tagBramOut=tagV else
                '0';


-- -----------------------------------------------------------------------------
-- Determine whether a cache block/line should be read or written.
-- -----------------------------------------------------------------------------

cacheBlockLine <= cacheBlockBramOut when rd='1' AND wr='0' AND wrCacheBlockLine='0';
 


-- -----------------------------------------------------------------------------
-- Determine whether a tag should be read or written.
-- -----------------------------------------------------------------------------
writeToTagBRAM <= '1' when wr='1' AND rd='0' else
                  '1' when wrCacheBlockLine='1' AND wr='0' AND rd='0' else
                  '0';

tagBramIn <= tagV when rd='0' AND wr='1' AND wrCacheBlockLine='0' else
	       tagV when rd='0' AND wr='0' AND wrCacheBlockLine='1';


-- -----------------------------------------------------------------------------
-- Determine the start index and end index of the correspondent word in the cache line.
-- -----------------------------------------------------------------------------
dataStartIndex <= cacheLineBits-1 - DATA_WIDTH * offsetI;
dataEndIndex <= dataStartIndex - DATA_WIDTH + 1;

-- -----------------------------------------------------------------------------
-- Write the correspondent data to data BRAM.
-- -----------------------------------------------------------------------------
writeToDataBRAMHelper <= '1' when wr='1' AND rd='0' AND wrCacheBlockLine='0' else
				         '0';

--cacheBlockBramIn <= cacheBlockBramOut;


dataRest32 <= cacheBlockBramOut( dataEndIndex-1 downto 0 ) when writeToDataBRAM='1' AND offsetI=(BLOCKSIZE-1) else (others=>'U');
dataRest64 <= cacheBlockBramOut( dataEndIndex-1 downto 0) when writeToDataBRAM='1' AND (offsetI/=0) AND (offsetI/=(BLOCKSIZE-1)) AND rising_edge(clk);
dataRest96 <= cacheBlockBramOut( dataEndIndex-1 downto 0 ) when writeToDataBRAM='1' AND offsetI=0 else (others=>'U');

cacheBlockBramIn <= 
	dataCPU_in & cacheBlockBramOut( dataEndIndex-1 downto 0 )                                                                when writeToDataBRAM='1' AND offsetI=0 AND rising_edge(clk) else
	cacheBlockBramOut( cacheLineBits-1 downto dataStartIndex+1 ) & dataCPU_in                                                when writeToDataBRAM='1' AND offsetI=(BLOCKSIZE-1) AND rising_edge(clk) else
    cacheBlockBramOut( cacheLineBits-1 downto dataStartIndex+1 ) & dataCPU_in & cacheBlockBramOut( dataEndIndex-1 downto 0 ) when writeToDataBRAM='1' AND rising_edge(clk);

-- -----------------------------------------------------------------------------
-- Read the correspondent data area.
-- -----------------------------------------------------------------------------
writeToDataBRAM <= tmpWrite;
tmpWrite <='0' when wr='0' AND rd='1' AND wrCacheBlockLine='0' AND writeToDataBRAMHelper='0' else
                   '1' when wr='1' AND rd='0' AND wrCacheBlockLine='0' AND writeToDataBRAMHelper='0' else
                   wrCacheBlockLine when rd='0' and wr='0' AND writeToDataBRAMHelper='0' else
                   'U' when writeToDataBRAMHelper='0' ;
                   
dataCPU_out <= cacheBlockBramOut( dataStartIndex downto dataEndIndex ) when wr='0' and rd='1' else
	       dataCPU_in when wr='1' and rd='0' else
	       dataCPU_in when wr='0' and rd='0' else
	       (others => 'U'); --TODO 

-- -----------------------------------------------------------------------------
-- The hit signal is supposed to be an asynchronous signal.
-- -----------------------------------------------------------------------------
hit <= '1' when valid='1' AND tagsAreEqual='1' else
       '0';


end synth;
