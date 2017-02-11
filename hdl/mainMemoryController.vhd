--------------------------------------------------------------------------------
-- filename : mainMemoryController.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 10/02/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mainMemoryController is
	generic(

		-- Number of cache blocks.
		ADDRESSWIDTH         : INTEGER := 256;

		-- Width of bit string containing the memory address. 
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Number of words that a cache block contains.
		BLOCKSIZE            : integer := 4;

		-- Width of bit string containing a data/instruction word.
		DATA_WIDTH           : INTEGER := 32;

		-- File extension regarding BRAM.
		FILE_EXTENSION       : STRING  := ".imem";

		-- Filename regarding regarding BRAM.
		DATA_FILENAME        : STRING  := "../imem/mainMemory"
	);

	port(
		clk         : in  STD_LOGIC;
		readyMEM    : out STD_LOGIC;
		rdMEM       : in  STD_LOGIC;
		wrMEM       : in  STD_LOGIC;
		addrMEM     : in  STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataMEM_in  : in  STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
		dataMEM_out : out STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0)
	);
end;

architecture synth of mainMemoryController is
	constant cacheLineBits : INTEGER := BLOCKSIZE * DATA_WIDTH;

	signal writeToBRAM : STD_LOGIC                                           := '0';
	signal addr        : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
	signal bram_in     : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)           := (others => '0');
	signal bram_out    : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)           := (others => '0');

	signal cacheBlock : STD_LOGIC_VECTOR(cacheLineBits - 1 downto 0) := (others => '0');
	signal indexStart : INTEGER                                      := 0;
	signal indexEnd   : INTEGER                                      := 0;

	signal myMEMORY_ADRRESS_WIDTH : INTEGER := MEMORY_ADDRESS_WIDTH;
	signal myDATA_WIDTH           : INTEGER := DATA_WIDTH;
	signal myBlocksize            : INTEGER := BLOCKSIZE;
	signal myCacheLineBits        : INTEGER := cacheLineBits;

	signal ready : STD_LOGIC := '0';

	TYPE BLOCK_LINE IS ARRAY (BLOCKSIZE - 1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	signal cacheBlockLine : BLOCK_LINE;

	function BLOCK_LINE_TO_STD_LOGIC_VECTOR(ARG : in BLOCK_LINE) return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR(cacheLineBits - 1 downto 0);
	begin
		v := (others => '0');
		for I in 0 to BLOCKSIZE - 1 loop
			v                          := std_logic_vector(unsigned(v) sll DATA_WIDTH);
			v(DATA_WIDTH - 1 downto 0) := ARG(I);
		end loop;
		return v;
	end;

	constant MyLength : INTEGER                                 := 10;
	signal addrLENGTH : INTEGER                                 := MyLength;
	signal addrVec    : STD_LOGIC_VECTOR(MyLength - 1 downto 0) := (others => '0');

	signal dataMEM_out_tmp : STD_LOGIC_VECTOR(cacheLineBits - 1 downto 0);
	signal bram_out_tmp    : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
	signal ii              : integer                                   := 0;

	signal counter : integer   := BLOCKSIZE+BLOCKSIZE;
	signal ifCase  : STD_LOGIC := '0';

	TYPE INT_ARRAY IS ARRAY (BLOCKSIZE - 1 downto 0) of INTEGER;
	signal startIndexArray : INT_ARRAY;
	signal endIndexArray   : INT_ARRAY;

	signal getRequest : STD_LOGIC := '0'; 

begin 

	bramMainMemory : entity work.bram   -- data memory
		generic map(INIT => (DATA_FILENAME & FILE_EXTENSION),
			        ADDR => 10,
			        DATA => DATA_WIDTH
		)
		port map(clk, writeToBRAM, addr(11 downto 2), bram_in, bram_out);

	readyMEM <= '0' when rdMEM='1' and counter < BLOCKSIZE else 
				'1' when getRequest='1' and counter>=BLOCKSIZE;
	getRequest              <= '1' when rdMEM='1' and rising_edge(clk) else 
	                           '0' when counter >= BLOCKSIZE-1 and rising_edge(clk);
	counter                 <= 0 when rising_edge(getRequest) else 
	                           counter + 1 when getRequest = '1' and rising_edge(clk) and counter <= BLOCKSIZE ;
	cacheBlockLine(counter-1) <= bram_out when counter > 0 and counter <= BLOCKSIZE;
	--cacheBlockLine(0) <= bram_out when counter = 0;
	addr                    <= STD_LOGIC_VECTOR(unsigned(addrMEM) + 4 * counter);
--	readyMEM <= '0' when getRequest='0' and rising_edge(rdMEM) and rising_edge(clk) else
--				'1' when getRequest='1' and rising_edge(clk) and counter >= BLOCKSIZE;
	dataMEM_out <= BLOCK_LINE_TO_STD_LOGIC_VECTOR(cacheBlockLine);
--	counter <= 0 when rising_edge(getRequest) else
--				counter + 1 when counter < BLOCKSIZE and rising_edge(clk);


end synth;