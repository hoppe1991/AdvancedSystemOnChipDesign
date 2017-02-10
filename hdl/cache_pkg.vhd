--------------------------------------------------------------------------------
-- filename : directMappedCache_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 09/02/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

package cache_pkg is
	function DETERMINE_NR_BITS(ARG : in INTEGER) return INTEGER;

	constant DATAWIDTH            : INTEGER := 32;
	constant MEMORY_ADDRESS_WIDTH : INTEGER := 32;
	constant DATA_WIDTH           : INTEGER := 32;
	constant ADDRESSWIDTH         : INTEGER := 256;
	constant BLOCKSIZE            : INTEGER := 4;
	constant OFFSET               : INTEGER := 8;

	constant INDEX_BITS        : INTEGER := DETERMINE_NR_BITS(ADDRESSWIDTH);
	constant OFFSET_BITS       : INTEGER := DETERMINE_NR_BITS(BLOCKSIZE * DATA_WIDTH / OFFSET);
	constant OFFSET_BLOCK_BITS : INTEGER := DETERMINE_NR_BITS(BLOCKSIZE);
	constant OFFSET_BYTE_BITS  : INTEGER := DETERMINE_NR_BITS(DATA_WIDTH / OFFSET);
	constant TAG_BITS          : INTEGER := MEMORY_ADDRESS_WIDTH - INDEX_BITS - OFFSET_BITS;
	constant BLOCK_BITS        : INTEGER := BLOCKSIZE * DATAWIDTH;

	type TAG_VECTOR is array (natural range <>) of STD_LOGIC;
	type INDEX_VECTOR is array (natural range <>) of STD_LOGIC;
	type OFFSET_VECTOR is array (natural range <>) of STD_LOGIC;

	type MEMORY_ADDRESS is record
		tag    : STD_LOGIC_VECTOR(TAG_BITS - 1 downto 0);
		index  : STD_LOGIC_VECTOR(INDEX_BITS - 1 downto 0);
		offset : STD_LOGIC_VECTOR(OFFSET_BITS - 1 downto 0);
	end record;

	function TO_STD_LOGIC_VECTOR(ARG : in MEMORY_ADDRESS) return STD_LOGIC_VECTOR;

	function INIT_MEMORY_ADDRESS return MEMORY_ADDRESS;
end cache_pkg;

package body cache_pkg is
	function INIT_MEMORY_ADDRESS return MEMORY_ADDRESS IS
		VARIABLE a : MEMORY_ADDRESS;
	begin
		a.tag    := (others => '0');
		a.index  := (others => '0');
		a.offset := (others => '0');
		return a;

	end;

	function TO_STD_LOGIC_VECTOR(ARG : in MEMORY_ADDRESS) return STD_LOGIC_VECTOR IS
		variable v : STD_LOGIC_VECTOR(TAG_BITS + INDEX_BITS + OFFSET_BITS - 1 downto 0);
	begin
		v := (ARG.tag) & ARG.index & ARG.offset;
		return v;
	end;
	function DETERMINE_NR_BITS(ARG : in INTEGER) return INTEGER IS
	begin
		return INTEGER(CEIL(LOG2(REAL(ARG))));
	end;

end cache_pkg;