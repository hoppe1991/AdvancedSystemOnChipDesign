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
  generic ( DATAWIDTH     : integer := 32;
            BLOCK         : integer := 32;
            ADDRESSWIDTH  : integer := 2;
            OFFSET        : integer := 2
          );

  port ( clk : in STD_LOGIC;
         w   : out STD_LOGIC

   );

end;


architecture synth of directMappedCache is

begin

end synth;
