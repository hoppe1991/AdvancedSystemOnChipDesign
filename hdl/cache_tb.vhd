--------------------------------------------------------------------------------
-- filename : cache_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.cache_pkg.all;


entity cache_tb is
	generic(
		MEMORY_ADDRESS_WIDTH : INTEGER := 32; -- Memory address is 32-bit wide.
		DATA_WIDTH           : INTEGER := 32; -- Length of instruction/data words.
		BLOCKSIZE            : INTEGER := 4; -- Number of words that a block contains.
		ADDRESSWIDTH         : INTEGER := 256; -- Number of cache blocks.
		OFFSET               : INTEGER := 8; -- Number of bits that can be selected in the cache.
		TAG_FILENAME         : STRING  := "../imem/tagCache";
		DATA_FILENAME        : STRING  := "../imem/dataCache"
	);

end;

architecture tests of cache_tb is
	constant indexNrOfBits       : INTEGER := DETERMINE_NR_BITS(ADDRESSWIDTH);
	constant offsetNrOfBits      : INTEGER := DETERMINE_NR_BITS(BLOCKSIZE * DATA_WIDTH / OFFSET);
	constant offsetBlockNrOfBits : INTEGER := DETERMINE_NR_BITS(BLOCKSIZE);
	constant offsetByteNrOfBits  : INTEGER := DETERMINE_NR_BITS(DATA_WIDTH / OFFSET);
	constant tagNrOfBits         : INTEGER := MEMORY_ADDRESS_WIDTH - indexNrOfBits - offsetNrOfBits;
	constant cacheLineBits       : INTEGER := BLOCKSIZE * DATA_WIDTH;

	signal clk, reset, memwrite : STD_LOGIC := '0';

	signal stallCPU : STD_LOGIC                                           := '0';
	signal rdCPU    : STD_LOGIC                                           := '0';
	signal wrCPU    : STD_LOGIC                                           := '0';
	signal addrCPU  : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
	signal dataCPU  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)           := (others => '0');
	signal readyMEM : STD_LOGIC                                           := '0';
	signal rdMEM    : STD_LOGIC                                           := '0';
	signal wrMEM    : STD_LOGIC                                           := '0';
	signal addrMEM  : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
	signal dataMEM  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)           := (others => '0');

	signal tagI        : INTEGER := 0;
	signal indexI      : INTEGER := 0;
	signal offsetI     : INTEGER := 0;
	signal offsetBlockI : INTEGER := 0;
	signal offsetByteI : INTEGER := 0;

	signal tagV         : STD_LOGIC_VECTOR(tagNrOfBits - 1 downto 0)         := (others => '0');
	signal indexV       : STD_LOGIC_VECTOR(indexNrOfBits - 1 downto 0)       := (others => '0');
	signal offsetV      : STD_LOGIC_VECTOR(offsetNrOfBits - 1 downto 0)      := (others => '0');
	signal offsetBlockV : STD_LOGIC_VECTOR(offsetBlockNrOfBits - 1 downto 0) := (others => '0');
	signal offsetByteV  : STD_LOGIC_VECTOR(offsetByteNrOfBits - 1 downto 0)  := (others => '0');
	
	signal hitCounter : INTEGER := 0;
	signal missCounter : INTEGER := 0;
begin
	cache : entity work.cacheController
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME
		)
		port map(clk      => clk,
			     reset    => reset,
			     stallCPU => stallCPU,
			     dataCPU  => dataCPU,
			     addrCPU  => addrCPU,
			     readyMEM => readyMEM,
			     dataMEM  => dataMEM,
			     rdCPU    => rdCPU,
			     wrCPU    => wrCPU,
			     hitCounter => hitCounter,
			     missCounter => missCounter
		);

	-- Generate clock with 10 ns period
	process
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end process;
	
	indexV <= STD_LOGIC_VECTOR( TO_UNSIGNED( indexI, indexNrOfBits ));
	tagV <= STD_LOGIC_VECTOR( TO_UNSIGNED( tagI, tagNrOfBits ));
	offsetBlockV <= STD_LOGIC_VECTOR( TO_UNSIGNED( offsetBlockI, offsetBlockNrOfBits ));
	offsetByteV <= STD_LOGIC_VECTOR( TO_UNSIGNED( offsetByteI, offsetByteNrOfBits ));
	 
	process
	begin
		wait for 10 ns;
		indexI <= 1;
		tagI <= 0;
		offsetI <= 0;
		dataCPU <= "11111111111111111111111111111111";
		rdCPU <= '0';
		wrCPU <= '1'; 
		wait for 10 ns;
		indexI <= 2;
		wait for 10 ns;
	end process;
	
	-- Generate reset for first two clock cycles
	process
	begin
		reset <= '0';
		wait for 50 ns;
		reset <= '1';
		wait for 20 ns;
		reset <= '0';
		wait;
	end process;

end tests;
