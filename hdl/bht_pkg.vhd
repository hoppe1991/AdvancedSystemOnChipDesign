---------------------------------------------------------------------------------
-- filename: bht_pkg.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 01/04/17 
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

package bht_pkg is

	-- Saturation counter stands in one of the following states:
	--		1. Strong Predict Not Taken
	--  	2. Weak Predict Not Taken
	--		3. Weak Predict Taken
	--		4. Strong Predict Taken
	type STATE_SATURATION_COUNTER is (
		STRONGLY_TAKEN,
		WEAKLY_TAKEN,
		WEAKLY_NOT_TAKEN,
		STRONGLY_NOT_TAKEN
	);

	-- Converts the given state to vector.
	function TO_STD_LOGIC_VECTOR_STATE(state : in STATE_SATURATION_COUNTER) return STD_LOGIC_VECTOR;

	-- Converts the given vector to state of the saturation counter.
	function TO_STATEBHT(v : in STD_LOGIC_VECTOR(1 downto 0)) return STATE_SATURATION_COUNTER;

end bht_pkg;

package body bht_pkg is

	-- Converts the given vector to state of the saturation counter.
	function TO_STATEBHT(v : in STD_LOGIC_VECTOR(1 downto 0)) return STATE_SATURATION_COUNTER is
	begin
		case v is
			when "11" => return STRONGLY_TAKEN;
			when "10" => return WEAKLY_TAKEN;
			when "01" => return WEAKLY_NOT_TAKEN;
			when others => return STRONGLY_NOT_TAKEN;
		end case;
	end function;

	-- Converts the given state to vector.
	function TO_STD_LOGIC_VECTOR_STATE(state : in STATE_SATURATION_COUNTER) return STD_LOGIC_VECTOR is
	begin
		case state is
			when STRONGLY_TAKEN => return "11";
			when WEAKLY_TAKEN => return "10";
			when WEAKLY_NOT_TAKEN => return "01";
			when others => return "00";
		end case;
	end function;

end bht_pkg;