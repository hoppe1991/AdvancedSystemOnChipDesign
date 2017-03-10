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

package cache_pkg is
 
	-- Replacement strategy used by the two way associative cache.
	-- There are two replacement strategies:
	-- 1. Random replacement.
	-- 2. Least Recently Used (LRU) replacement. 	
	type replacementStrategy is (
		RANDOM,
		LRU
	);
 
	-- -----------------------------------------------------------------------------------------
	-- The record type CONFIG_BITS_WIDTH contains the number of bits
	-- used for index vector, offset vector and tag vector regarding the memory address.
	-- This record type also contains the number of bits of a cache block line.
	-- -----------------------------------------------------------------------------------------
	type CONFIG_BITS_WIDTH is record
	
		-- Number of bits regarding the index vector.
		indexNrOfBits       : INTEGER;
		
		-- Number of bits regarding the offset vector.
		offsetNrOfBits      : INTEGER;
		
		-- Number of bits regarding the block offset vector.
		offsetBlockNrOfBits : INTEGER;
		
		-- Number of bits regarding the byte offset vector.
		offsetByteNrOfBits  : INTEGER;
		
		-- Number of bits regarding the tag vector.
		tagNrOfBits         : INTEGER;
		
		-- Number of bits regarding a cache block line.
		cacheLineBits       : INTEGER;

		tagIndexH    : INTEGER;
		tagIndexL    : INTEGER;
		indexIndexH  : INTEGER;
		indexIndexL  : INTEGER;
		offsetIndexH : INTEGER;
		offsetIndexL : INTEGER;
	end record;

	-- -----------------------------------------------------------------------------------------
	-- The auxiliary function DETERMINE_NR_BITS returns an INTEGER by calculation
	-- the log-function by the given INTEGER value.
	-- -----------------------------------------------------------------------------------------
	function DETERMINE_NR_BITS(ARG : in INTEGER) return INTEGER;
 
	-- -----------------------------------------------------------------------------------------
	-- The function GET_CONFIG_BITS_WIDTH calculates the number of bits
	-- used for the index vector, tag vector and offset vector regarding
	-- the memory address.
	-- Also, calculates the number of bits of a whole cache block line.
	-- -----------------------------------------------------------------------------------------
	function GET_CONFIG_BITS_WIDTH(MEMORY_ADDRESS_WIDTH : in INTEGER; ADDRESSWIDTH : in INTEGER; BLOCKSIZE : in INTEGER;
		DATA_WIDTH   : in INTEGER; OFFSET : in INTEGER) return CONFIG_BITS_WIDTH;
	
	-- ---------------------------------------------------------------------------------------------------------
	-- This function determines the number of bits of the tag bit vector.
	-- ---------------------------------------------------------------------------------------------------------
	function GET_TAG_NR_BITS( MEMORY_ADDRESS_WIDTH : in INTEGER; ADDRESSWIDTH : in INTEGER;
		BLOCKSIZE : in INTEGER; DATA_WIDTH : in INTEGER; OFFSET : in INTEGER
	) return INTEGER;
	
end cache_pkg;

package body cache_pkg is


	-- ---------------------------------------------------------------------------------------------------------
	-- This function determines the number of bits of the tag bit vector.
	-- ---------------------------------------------------------------------------------------------------------
	function GET_TAG_NR_BITS( MEMORY_ADDRESS_WIDTH : in INTEGER; ADDRESSWIDTH : in INTEGER;
		BLOCKSIZE : in INTEGER; DATA_WIDTH : in INTEGER; OFFSET : in INTEGER
	) return INTEGER is
	variable r : INTEGER := 0;
	begin
		r :=MEMORY_ADDRESS_WIDTH-DETERMINE_NR_BITS(ADDRESSWIDTH)-DETERMINE_NR_BITS(BLOCKSIZE*DATA_WIDTH/OFFSET);
		return r;
	end function;
	
	-- -----------------------------------------------------------------------------------------
	-- The function GET_CONFIG_BITS_WIDTH calculates the number of bits
	-- used for the index vector, tag vector and offset vector regarding
	-- the memory address.
	-- Also, calculates the number of bits of a whole cache block line.
	-- -----------------------------------------------------------------------------------------
	function GET_CONFIG_BITS_WIDTH(
		MEMORY_ADDRESS_WIDTH : in INTEGER;
		ADDRESSWIDTH : in INTEGER;
		BLOCKSIZE : in INTEGER;
		DATA_WIDTH : in INTEGER;
		OFFSET : in INTEGER)
	return CONFIG_BITS_WIDTH is
		variable config : CONFIG_BITS_WIDTH;
	begin
		config.indexNrOfBits       := DETERMINE_NR_BITS(ADDRESSWIDTH);
		config.offsetNrOfBits      := DETERMINE_NR_BITS(BLOCKSIZE * DATA_WIDTH / OFFSET);
		config.offsetBlockNrOfBits := DETERMINE_NR_BITS(BLOCKSIZE);
		config.offsetByteNrOfBits  := DETERMINE_NR_BITS(DATA_WIDTH / OFFSET);
		config.tagNrOfBits         := MEMORY_ADDRESS_WIDTH - config.indexNrOfBits - config.offsetNrOfBits;
		config.cacheLineBits       := BLOCKSIZE * DATA_WIDTH;
		config.tagIndexH           := config.offsetNrOfBits + config.indexNrOfBits + config.tagNrOfBits - 1;
		config.tagIndexL           := config.offsetNrOfBits + config.indexNrOfBits;
		config.indexIndexH         := config.offsetNrOfBits + config.indexNrOfBits - 1;
		config.indexIndexL         := config.offsetNrOfBits;
		config.offsetIndexH        := config.offsetNrOfBits - 1;
		config.offsetIndexL        := 0;
		return config;
	end;
 
	-- -----------------------------------------------------------------------------------------
	-- The auxiliary function DETERMINE_NR_BITS returns an INTEGER by calculation
	-- the log-function by the given INTEGER value.
	-- -----------------------------------------------------------------------------------------
	function DETERMINE_NR_BITS(ARG : in INTEGER) return INTEGER IS
	begin
		return INTEGER(CEIL(LOG2(REAL(ARG))));
	end;

end cache_pkg;