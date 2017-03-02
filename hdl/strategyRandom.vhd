--------------------------------------------------------------------------------
-- filename : strategyRandom.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 20/02/17
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity strategyRandom is
	port(

		-- Clock signal.
		clk        : in  STD_LOGIC;

		-- Reset signal.
		reset      : in  STD_LOGIC;

		-- Miss signal from controller.
		miss       : in  STD_LOGIC;

		-- Index of cache, which to used.
		cacheIndex : out STD_LOGIC
	);
end;

architecture behav of strategyRandom is
	signal sCacheIndex : STD_LOGIC := '0';

begin

	-- Reset the output, when signal reset is active.
	-- Toggle the output, in case of cache miss.
	sCacheIndex <= '0' when reset = '1' and rising_edge(clk) else not (sCacheIndex) when miss = '1' and rising_edge(clk);

	-- Output the value.
	cacheIndex <= sCacheIndex;

end architecture;