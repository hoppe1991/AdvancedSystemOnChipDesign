--------------------------------------------------------------------------------
-- filename : mips_arc_task3_pipelining.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.mips_pkg.all;
use work.casts.all;
use work.global_pkg.all;

entity testbench_configuration is
	
	generic(

		-- Width of bit string containing the memory address. 
		CONFIG_ID : INTEGER := 1
	);
	port(
		USED_CONFIG : out INTEGER := 1
		);
end;
	
--------------------------------------------------------------------------------
-- Architecture of MIPS defines only the pipelined mips (see task sheet 3) without
-- instruction cache and without branch prediction.
--------------------------------------------------------------------------------
architecture arcTestbenchConfig of testbench_configuration is
	
begin
	 USED_CONFIG <= CONFIG_ID;
end;