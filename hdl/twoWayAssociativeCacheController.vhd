--------------------------------------------------------------------------------
-- filename : twoWayAssociativeCacheController.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 21/02/17
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Include packages.
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =============================================================================
-- Define the generic variables and ports of the entity.
-- =============================================================================
entity twoWayAssociativeCacheController is
	generic(
		-- Memory address is 32-bit wide.
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Instruction and data words of the MIPS are 32-bit wide, but other CPUs
		-- have quite different instruction word widths.
		DATA_WIDTH           : integer := 32;

		-- Is the depth of the cache, i.e. the number of cache blocks / lines.
		ADDRESSWIDTH         : integer := 256;

		-- Number of words that a block contains and which are simultaneously loaded from the main memory into cache.
		BLOCKSIZE            : integer := 4;

		-- The number of bits specifies the smallest unit that can be selected
		-- in the cache. Byte (8 Bits) access should be possible.
		OFFSET               : integer := 8;

		-- Filename for tag BRAM.
		TAG_FILENAME          : STRING  := "../imem/tagFileName";

		-- Filename for data BRAM.
		DATA_FILENAME         : STRING  := "../imem/dataFileName";

		-- File extension for BRAM.
		FILE_EXTENSION       : STRING  := ".txt"
	);

	port(
		-- Clock signal is used for BRAM.
		clk              : in    STD_LOGIC;

		-- Reset signal to reset the cache.
		reset            : in    STD_LOGIC
	);
end;

-- =============================================================================
-- Definition of architecture.
-- =============================================================================
architecture synth of twoWayAssociativeCacheController is

begin
	

end synth;
