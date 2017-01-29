--------------------------------------------------------------------------------
-- filename : directMappedCached.vhd
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

entity directMappedCache is
  generic ( DATAWIDTH     : integer := 32;  -- Length of instruction/data words.
            BLOCKSIZE     : integer := 32;  -- Number of words that a block contains.
            ADDRESSWIDTH  : integer := 32;   -- Number of cache blocks.
            OFFSET        : integer := 2    -- Number of bits that can be selected in the cache.
          );

  port ( clk : in STD_LOGIC;
         addrCPU : in STD_LOGIC_VECTOR(ADDRESSWIDTH-1 downto 0);
         dataCPU : inout STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0);
         hit : out STD_LOGIC
   );

end;


architecture synth of directMappedCache is

begin


-- -----------------------------------------------------------------------------
-- Ports of BRAM.
-- -----------------------------------------------------------------------------
-- work.bram( clk, we : in STD_LOGIC,
--            adr     : in STD_LOGIC_VECTOR(ADDR-1 downto 0);
--            din     : in STD_LOGIC_VECTOR(DATA-1 downto 0);
--            dout    : out STD_LOGIC_VECTOR(DATA-1 downto 0)
--          );



-- -----------------------------------------------------------------------------
-- The tag area should be BRAM blocks.
-- -----------------------------------------------------------------------------
tag:    entity work.bram   -- data memory
        generic map ( INIT =>  (IFileName & ".cache"))
        port    map ( clk, '0', pc(11 downto 2), (others=>'0'), IF_ir);



-- -----------------------------------------------------------------------------
-- The data area should be BRAM blocks.
-- -----------------------------------------------------------------------------
data:    entity work.bram   -- data memory
        generic map ( INIT =>  (IFileName & ".cache"))
        port    map ( clk, '0', pc(11 downto 2), (others=>'0'), IF_ir);



-- -----------------------------------------------------------------------------
-- The hit signal is supposed to be an asynchronous signal.
-- -----------------------------------------------------------------------------
hit <= '0';


end synth;
