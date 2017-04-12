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

--------------------------------------------------------------------------------
-- Architecture of MIPS defines only the pipelined mips (see task sheet 3) without
-- instruction cache and without branch prediction.
--------------------------------------------------------------------------------
architecture mips_arc_task3_pipelining of mips is
	
begin
	  mipsController: entity work.mips_controller_task3_pipelining
	  	generic map(
	  		DFileName => DFileName,
	  		IFileName => IFileName
	  	)
	  	port map(
	  		clk       => clk,
	  		reset     => reset,
	  		writedata => writedata,
	  		dataadr   => dataadr,
	  		memwrite  => memwrite
	  	);
	 
end mips_arc_task3_pipelining;