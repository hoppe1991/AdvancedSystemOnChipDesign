--------------------------------------------------------------------------------
-- filename : directMappedCache_tb.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 09/02/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

package bht_pkg is
 
	-- Replacement strategy used by the two way associative cache.
	-- There are two replacement strategies:
	-- 1. Random replacement.
	-- 2. Least Recently Used (LRU) replacement. 	
	type stateBHT is (
		STRONGLY_TAKEN,
		WEAKLY_TAKEN,
		WEAKLY_NOT_TAKEN,
		STRONGLY_NOT_TAKEN
	);
	
	function TO_STD_LOGIC_VECTOR( state : in stateBHT ) return STD_LOGIC_VECTOR;
	
	function TO_STATEBHT( v : in STD_LOGIC_VECTOR(1 downto 0)) return STATEBHT;
	
end bht_pkg;

package body bht_pkg is


function TO_STATEBHT( v : in STD_LOGIC_VECTOR(1 downto 0)) return STATEBHT is
	variable s : STATEBHT;
begin
		if (v="11") then
			s := STRONGLY_TAKEN;
		elsif (v="10") then
			s := WEAKLY_TAKEN;
		elsif (v="01") then 
			s := WEAKLY_NOT_TAKEN;
		else
			s := STRONGLY_NOT_TAKEN;
		end if;
		
	
end function;

	function TO_STD_LOGIC_VECTOR( state : in stateBHT ) return STD_LOGIC_VECTOR is
		variable s : STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
	begin
		if (state=STRONGLY_TAKEN) then
			s := "11";
		elsif (state=WEAKLY_TAKEN) then
			s := "10";
		elsif (state=WEAKLY_NOT_TAKEN) then 
			s := "01";
		else
			s := "00";
		end if;
		
		return s;
	end function;
	
	

end bht_pkg;