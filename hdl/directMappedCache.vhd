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
USE ieee.math_real.log2;
USE ieee.math_real.ceil;


-- =============================================================================
-- Define the generics and ports of the entity.
-- =============================================================================
entity directMappedCache is
  generic (
      -- Instruction and data words of the MIPS are 32-bit wide, but other CPUs
      -- have quite different instruction word widths.
      DATA_WIDTH     : integer := 32;

      -- Is the depth of the cache, i.e. the number of cache blocks / lines.
      ADDRESSWIDTH  : integer := 256;

      -- Number of words that a block contains and which are simulatenously
      -- loaded from the main memory into cache.
      BLOCKSIZE     : integer := 4;               -- What is the purpose of this generic variale?

      -- The number of bits specifies the smallest unit that can be selected
      -- in the cache.
      OFFSET        : integer := 8; -- Byte (8 Bits) access possible.

      -- Filename for tag BRAM.
      TagFileName  : STRING := "../imem/tagFileName";

      -- Filename for data BRAM.
      DataFileName : STRING := "../imem/dataFileName"
    );

  port (
         -- Clock signal is used for BRAM.                                      TODO Is this clock signal neccassary?
         clk : in STD_LOGIC;

         -- Memory address from CPU is divided into block address and block offset.
        addrCPU : in STD_LOGIC_VECTOR( DATA_WIDTH-1 downto 0 );

         -- Data from CPU to cache.                                             TODO Is it possible to define one single dataCPU signal as an inout signal?
         dataCPUIn  : in STD_LOGIC_VECTOR( OFFSET-1 downto 0 );

         -- Data from cache to CPU.
         dataCPUOut : out sTD_LOGIC_VECTOR( OFFSET-1 downto 0 );

         -- Data from memory to cache.
         dataMEMIn : in STD_LOGIC_VECTOR( OFFSET-1 downto 0 );

         -- Data from cache to memory.
         dataMEMOut : out STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) ;

         --
         cacheBlockLine : inout STD_LOGIC_VECTOR( (BLOCKSIZE*OFFSET)-1 downto 0 ) ;

         wrCacheBlockLine : in STD_LOGIC;

         -- Read signal identify to read data from the cache.
         rd      : in STD_LOGIC;

         -- Write signal identify to write data into the cache.
         wr      : in STD_LOGIC;

         --
         valid   : inout STD_LOGIC;

         --
         dirty   : out STD_LOGIC;

         -- Signal identify whether data are available in the cache ('1') or not ('0').
         hit : out STD_LOGIC
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

constant indexNrOfBits  : INTEGER := INTEGER( CEIL( LOG2( REAL( ADDRESSWIDTH ))));
constant offsetNrOfBits : INTEGER := INTEGER( CEIL( LOG2( REAL( BLOCKSIZE ))));
constant tagNrOfBits    : INTEGER := 32 - indexNrOfBits - offsetNrOfBits;
constant cacheLineBits  : INTEGER := BLOCKSIZE * OFFSET;

constant tagIndexH    : INTEGER := offsetNrOfBits + indexNrOfBits + tagNrOfBits - 1;
constant tagIndexL    : INTEGER := offsetNrOfBits + indexNrOfBits;
constant indexIndexH  : INTEGER := offsetNrOfBits + indexNrOfBits - 1;
constant indexIndexL  : INTEGER := offsetNrOfBits;
constant offsetIndexH : INTEGER := offsetNrOfBits - 1;
constant offsetIndexL : INTEGER := 0;

signal vIndex  : STD_LOGIC_VECTOR( indexNrOfBits-1 downto 0) := (others => '0');
signal iIndex  : INTEGER := 0;
signal vOffset : STD_LOGIC_VECTOR( offsetNrOfBits-1 downto 0) := (others => '0');
signal vTag    : STD_LOGIC_VECTOR( tagNrOfBits-1 downto 0 ) := (others => '0');

signal cacheLine : STD_LOGIC_VECTOR( cacheLineBits-1 downto 0 ) := (others => '0');

signal tagBramIn : STD_LOGIC_VECTOR( tagNrOfBits-1 downto 0 ) := (others => '0');
signal tagBramOut : STD_LOGIC_VECTOR( tagNrOfBits-1 downto 0 ) := (others => '0');
signal writeToTagBRAM : STD_LOGIC := '0';

signal dataBramIn  : STD_LOGIC_VECTOR( cacheLineBits-1 downto 0 ) := (others => '0');
signal dataBramOut : STD_LOGIC_VECTOR( cacheLineBits-1 downto 0 ) := (others => '0');
signal writeToDataBRAM : STD_LOGIC := '0';
signal writeToDataBRAMHelper : STD_LOGIC := '0';

signal validBits : STD_LOGIC_VECTOR( ADDRESSWIDTH-1 downto 0) := (others => 'U');
signal tagsAreEqual : STD_LOGIC := '0';

signal dataStartIndex : INTEGER := 0;
signal dataEndIndex : INTEGER := 0;

signal addrDataBram : INTEGER := 0;
signal dataDataBram : Integer := 0;


signal testA : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0');
signal testB : STD_LOGIC_VECTOR( cacheLineBits-OFFSET-1 downto 0 ) := (others => '0');
--------------

begin

-- -----------------------------------------------------------------------------
-- The tag area should be BRAM blocks.
-- -----------------------------------------------------------------------------
tagBRAM:  entity work.bram   -- data memory
          generic map ( INIT =>  (TagFileName & ".cache"),
                        ADDR => indexNrOfBits,
                        DATA => tagNrOfBits
          )
          port    map ( clk, writeToTagBRAM, vIndex, tagBramIn, tagBramOut);

-- -----------------------------------------------------------------------------
-- The data area should be BRAM blocks.
-- -----------------------------------------------------------------------------
dataBRAM:   entity work.bram   -- data memory
            generic map ( INIT =>  (DataFileName & ".cache"),
                          ADDR => indexNrOfBits,
                          DATA => cacheLineBits
                          )
            port map ( clk, writeToDataBRAM, vIndex, dataBramIn, dataBramOut);


-- -----------------------------------------------------------------------------
-- Determine the offset, index and tag of the address signal.
-- -----------------------------------------------------------------------------
vOffset <= addrCPU( offsetIndexH downto offsetIndexL );
vIndex  <= addrCPU( indexIndexH  downto indexIndexL );
iIndex  <= TO_INTEGER( SIGNED( vIndex ) );
vTag    <= addrCPU( tagIndexH    downto tagIndexL );


-- -----------------------------------------------------------------------------
-- Determine the valid bit.
-- -----------------------------------------------------------------------------
valid <= '1' when rd='1' AND wr='0' AND validBits( iIndex )='1' else
         '0' when rd='1' AND wr='0' AND validBits( iIndex )='0';

-- -----------------------------------------------------------------------------
-- Set the valid bit.
-- -----------------------------------------------------------------------------
validBits( iIndex ) <= '1' when rd='0' AND wr='1' AND valid='1' else
                       '0' when rd='0' AND wr='1' AND valid='0';

-- -----------------------------------------------------------------------------
-- Check whether the tags are equal.
-- -----------------------------------------------------------------------------
tagsAreEqual <= '1' when tagBramOut=vTag else
                '0';

-- -----------------------------------------------------------------------------
-- Determine whether a cache block line should be read or written.
-- -----------------------------------------------------------------------------
writeToDataBRAM <= '0' when wrCacheBlockLine='0' else
                   '0' when rd='1' OR wr='1' else
                   '1';

cacheBlockLine <= dataBramOut when rd='0' AND wr='0' AND wrCacheBlockLine='0';

dataBramIn <= cacheBlockLine when rd='0' AND wr='0' AND wrCacheBlockLine='1';


-- -----------------------------------------------------------------------------
-- Determine whether a tag should be read or written.
-- -----------------------------------------------------------------------------
writeToTagBRAM <= '1' when wr='1' AND rd='1' else
                  '1' when wrCacheBlockLine='1' AND wr='0' AND rd='0' else
                  '0';



dataStartIndex <= cacheLineBits-1 - (OFFSET * iIndex);
dataEndIndex <= dataStartIndex - OFFSET + 1;

-- -----------------------------------------------------------------------------
-- Write the correspondent data to data BRAM.
-- -----------------------------------------------------------------------------
writeToDataBRAMHelper <= '1' when wr='1' AND rd='0' AND wrCacheBlockLine='0';

process( writeToDataBRAMHelper )
begin
  if writeToDataBRAMHelper = '1' then

    -- Read the actual cache block/line.
    writeToDataBRAM <= '0';



    -- Modiy the actual cache block/line.
    if iIndex=0 then
      dataBramIn( dataStartIndex downto dataEndIndex ) <= dataCPUIn;
      dataBramIn( dataEndIndex-1 downto 0 ) <= dataBramOut( dataEndIndex-1 downto 0 );
    elsif iIndex=(BLOCKSIZE-1) then
      dataBramIn( dataStartIndex downto dataEndIndex ) <= dataCPUIn( dataStartIndex downto dataEndIndex );
      dataBramIn( cacheLineBits-1 downto dataStartIndex+1 ) <= dataBramOut( cacheLineBits-1 downto dataStartIndex+1 );
    else
      dataBramIn( cacheLineBits-1 downto dataStartIndex+1 ) <= dataBramOut( cacheLineBits-1 downto dataStartIndex+1 );
      dataBramIn( dataStartIndex downto dataEndIndex ) <= dataCPUIn( dataStartIndex downto dataEndIndex );
      dataBramIn( dataEndIndex-1 downto 0 ) <= dataBramOut( dataEndIndex-1 downto 0 );
    end if;

    -- Write the actual cache block/line.
    writeToDataBRAM <= '1';
    end if;

end process;


-- -----------------------------------------------------------------------------
-- Read the correspondent data area.
-- -----------------------------------------------------------------------------
writeToDataBRAM <= '0' when wr='0' AND rd='1' AND wrCacheBlockLine='0';
dataCPUOut <= dataBramOut( dataStartIndex downto dataEndIndex ) when wr='1' AND rd='1';

-- -----------------------------------------------------------------------------
-- The hit signal is supposed to be an asynchronous signal.
-- -----------------------------------------------------------------------------
hit <= '1' when valid='1' AND tagsAreEqual='1' else
       '0';


end synth;
