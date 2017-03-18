-- --------------------------------------------------------------------------------
-- filename : directMappedCache_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 11/02/2017
-- --------------------------------------------------------------------------------


-- Include packages.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;          -- VHDL2008 lib
use STD.textio.all;
use work.cache_pkg.all;

-- --------------------------------------------------------------------------------
-- Definition of entity.
-- --------------------------------------------------------------------------------
entity creatorOfCacheFiles is
	generic(

		-- Memory address is 32-bit wide.
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Instruction and data words of the MIPS are 32-bit wide, but other CPUs
		-- have quite different instruction word widths.
		DATA_WIDTH           : integer := 32;

		-- Is the depth of the cache, i.e. the number of cache blocks / lines.
		ADDRESS_WIDTH        : integer := 256;

		-- Number of words that a block contains and which are simultaneously loaded from the main memory into cache.
		BLOCKSIZE            : integer := 4;

		-- The number of bits specifies the smallest unit that can be selected
		-- in the cache. Byte (8 Bits) access should be possible.
		OFFSET               : integer := 8;

		-- Filename of tag cache.
		TAG_FILENAME         : STRING  := "../imem/cacheTag";

		-- Filename of instruction cache.
		DATA_FILENAME        : STRING  := "../imem/cacheData";

		-- File extension of instruction file.
		FILE_EXTENSION       : STRING  := ".imem"
	);

end;

architecture behav of creatorOfCacheFiles is
	constant indexNrOfBits       : INTEGER := DETERMINE_NR_BITS(ADDRESS_WIDTH);
	constant offsetNrOfBits      : INTEGER := DETERMINE_NR_BITS(BLOCKSIZE * DATA_WIDTH / OFFSET);
	constant offsetBlockNrOfBits : INTEGER := DETERMINE_NR_BITS(BLOCKSIZE);
	constant offsetByteNrOfBits  : INTEGER := DETERMINE_NR_BITS(DATA_WIDTH / OFFSET);
	constant tagNrOfBits         : INTEGER := MEMORY_ADDRESS_WIDTH - indexNrOfBits - offsetNrOfBits;
	constant cacheLineBits       : INTEGER := BLOCKSIZE * DATA_WIDTH;

begin
	process
		file tagFile : TEXT open WRITE_MODE is TAG_FILENAME & FILE_EXTENSION;
		file dataFile : TEXT open WRITE_MODE is DATA_FILENAME & FILE_EXTENSION;
		variable cacheBlock    : STD_LOGIC_VECTOR(cacheLineBits - 1 downto 0) := (others => '0');
		variable tag           : STD_LOGIC_VECTOR(tagNrOfBits - 1 downto 0)   := (others => '0');
		variable cacheTagLine  : LINE;
		variable cacheDataLine : LINE;

	begin
		for j in 0 to ADDRESS_WIDTH - 1 loop
			hwrite(cacheTagLine, tag);
			writeline(tagFile, cacheTagLine);

			hwrite(cacheDataLine, cacheBlock);
			writeline(dataFile, cacheDataLine);
		end loop;

		wait;

	end process;

end architecture;