--------------------------------------------------------------------------------
-- filename : strategyLRU.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 20/02/17
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity strategyLRU is
	port(

		-- Clock signal.
		clk        : in  STD_LOGIC;

		-- Reset signal.
		reset      : in  STD_LOGIC;
		
		-- 1, when update the leastRecentlyUsed index. 0, when return the leastRecentlyUsed index.
		write	   : in STD_LOGIC; 

		-- Miss signal from controller.
		leastRecentlyUsed : inout  STD_LOGIC
	);
end;

architecture behav of strategyLRU is
	signal sleastRecentlyUsed : STD_LOGIC := '0';

begin

	-- Reset the output, when signal reset is active.
	-- Update the index otherwise.
	sleastRecentlyUsed <= '0' when reset = '1' and rising_edge(clk) else leastRecentlyUsed when write='1' and rising_edge(clk);

	-- Output the set index.
	leastRecentlyUsed <= sleastRecentlyUsed when write='0' and reset='0' else 'Z';

end architecture;