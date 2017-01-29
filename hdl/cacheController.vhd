--------------------------------------------------------------------------------
-- filename : cacheController.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity cacheController is
  generic ( DATAWIDTH     : integer := 32;  -- Length of instruction/data words.
            BLOCKSIZE     : integer := 4;  -- Number of words that a block contains.
            ADDRESSWIDTH  : integer := 256;   -- Number of cache blocks.
            OFFSET        : integer := 2    -- Number of bits that can be selected in the cache.
          );

  port ( clk      : in    STD_LOGIC;
         rdCPU    : in    STD_LOGIC;
         wrCPU    : in    STD_LOGIC;
         addrCPU  : in    STD_LOGIC_VECTOR();
         readyMEM : in    STD_LOGIC;
         dataCPU  : inout STD_LOGIC_VECTOR();
         dataMEM  : inout STD_LOGIC_VECTOR();
         rdMEM    : out   STD_LOGIC;
         wrMEM    : out   STD_LOGIC;
         addrMEM  : out   STD_LOGIC_VECTOR();
         stallCPU : out   STD_LOGIC
   );

end;


architecture synth of cacheController is

begin




end synth;
