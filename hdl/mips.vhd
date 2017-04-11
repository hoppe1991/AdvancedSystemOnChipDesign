---------------------------------------------------------------------------------
-- filename: mips.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 01/04/17 
---------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.mips_pkg.all;
use work.casts.all;
use work.global_pkg.all;

---------------------------------------------------------------------------------
-- Interface of MIPS.
---------------------------------------------------------------------------------
entity mips is
  generic ( DFileName 			: STRING := "../dmem/isort_pipe";
            IFileName 			: STRING := "../imem/isort_pipe";
	        TAG_FILENAME 		: STRING := "../imem/tagCache";
			DATA_FILENAME		: STRING := "../imem/dataCache";
			FILE_EXTENSION		: STRING := ".imem"
            );
  port ( clk, reset        : in  STD_LOGIC;
         writedata, dataadr: out STD_LOGIC_VECTOR(31 downto 0);
         memwrite          : out STD_LOGIC
       );
end;