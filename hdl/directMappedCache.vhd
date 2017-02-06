--------------------------------------------------------------------------------
-- filename : directMappedCache.vhd
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
USE ieee.math_real.log2;
USE ieee.math_real.ceil;

entity directMappedCache is
  generic ( DATAWIDTH     : integer := 32;  -- Length of instruction/data words.
            BLOCKSIZE     : integer := 4;   -- Number of words that a block contains.
            ADDRESSWIDTH  : integer := 256; -- Number of cache blocks.
            OFFSET        : integer := 2;    -- Number of bits that can be selected in the cache.


            TagFileName  : STRING := "../imem/tagFileName";
            DataFileName : STRING := "../imem/dataFileName";
            IFileName : STRING := "../imem/my_cache"
          );

  port ( clk : in STD_LOGIC;
         addrCPU : in STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0);
         dataIn  : in STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0);
         dataOut : out sTD_LOGIC_VECTOR(DATAWIDTH-1 downto 0);
         rw      : in STD_LOGIC;
         wr      : in STD_LOGIC;
         valid   : inout STD_LOGIC;
         dirty   : out STD_LOGIC;
         miss : out STD_LOGIC;
         hit : out STD_LOGIC
   );

end;


architecture synth of directMappedCache is

signal writeToCache : STD_LOGIC := '0';
signal instruction  : STD_LOGIC_VECTOR(31 downto 0) := (others=>'0');
signal validVector  : STD_LOGIC_VECTOR(2**ADDRESSWIDTH-1 downto 0) := (others => 'U'); -- TODO Update the size.
signal index        : STD_LOGIC_VECTOR(ADDRESSWIDTH-1 downto 0) := (others => '0'); -- TODO Update the size.
signal offsetV       : STD_LOGIC_VECTOR(ADDRESSWIDTH-1 downto 0) := (others => '0'); -- TODO Update the size.
signal tag          : STD_LOGIC_VECTOR(ADDRESSWIDTH-1 downto 0) := (others => '0'); -- TODO Update the size.

signal indexInt     : INTEGER := 0;

signal tagsAreEqual : STD_LOGIC := '0';
signal validBitSet : STD_LOGIC := '0';


signal addresswidth_neu : integer := ADDRESSWIDTH;
signal count_width : integer := INTEGER(CEIL(LOG2(Real(ADDRESSWIDTH))));


begin

process(clk) begin
  if rising_edge(clk) then
    if (tagsAreEqual='1' AND validBitSet='1') then
      hit <= '1';
      miss <= '1';
    else
      hit <= '0';
      miss <= '1';
    end if;
  end if;
end process;

process(clk) begin
  if rising_edge(clk) then
    indexInt <= TO_INTEGER( SIGNED( index ));
    if rw = '1' then
      --valid <= validVector( to_integer(index) );
      valid <= validVector( TO_INTEGER( SIGNED( index )));
    else
      validVector( TO_INTEGER( SIGNED( index ))) <= valid;
    end if;
  end if;
end process;

-- -----------------------------------------------------------------------------
-- Ports of BRAM.
-- -----------------------------------------------------------------------------
-- work.bram( clk     : in STD_LOGIC,
--            we : in STD_LOGIC, -- 1, when write to file. 0, otherwise.
--            adr     : in STD_LOGIC_VECTOR(ADDR-1 downto 0);
--            din     : in STD_LOGIC_VECTOR(DATA-1 downto 0);
--            dout    : out STD_LOGIC_VECTOR(DATA-1 downto 0)
--          );

-- -----------------------------------------------------------------------------
-- The tag area should be BRAM blocks.
-- -----------------------------------------------------------------------------
--tag:    entity work.bram   -- data memory
--        generic map ( INIT =>  (IFileName & ".cache"))
--        port    map ( clk, writeToCache, addrCPU, dataIn, dataOut);

-- -----------------------------------------------------------------------------
-- The data area should be BRAM blocks.
-- -----------------------------------------------------------------------------
--data:   entity work.bram   -- data memory
--        generic map ( INIT =>  (IFileName & ".cache"),
--                      DATA => DATAWIDTH,
--                      ADDR => DATAWIDTH)
--        port    map ( clk, writeToCache, addrCPU, dataIn, dataOut);




-- -----------------------------------------------------------------------------
-- The hit signal is supposed to be an asynchronous signal.
-- -----------------------------------------------------------------------------
hit <= '0';


end synth;
