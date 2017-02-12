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
		dataMEM_out : out STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
		reset : in STD_LOGIC
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
	signal cacheBlockLine    : BLOCK_LINE;
	signal cacheBlockLine_in : BLOCK_LINE;

	function STD_LOGIC_VECTOR_TO_BLOCK_LINE(ARG : in STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0)) return BLOCK_LINE is
		variable v : BLOCK_LINE;
		variable a : STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
	begin
		a := ARG;
		for I in 0 to BLOCKSIZE - 1 loop
			v(I) := a(DATA_WIDTH - 1 downto DATA_WIDTH - DATA_WIDTH);
			a    := std_logic_vector(unsigned(a) sll DATA_WIDTH);
		end loop;
		return v;
	end;

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

	signal counter : integer   := BLOCKSIZE + BLOCKSIZE;
	signal ifCase  : STD_LOGIC := '0';

	TYPE INT_ARRAY IS ARRAY (BLOCKSIZE - 1 downto 0) of INTEGER;
	signal startIndexArray : INT_ARRAY;
	signal endIndexArray   : INT_ARRAY;

	signal getRequest : STD_LOGIC := '0';

	type statetype is (
		IDLE,
		READ,
		WRITE
	); 

	signal state     : statetype  := IDLE;
	signal nextstate : statetype := IDLE;
	
	signal addrMEM_tmp : STD_LOGIC_VECTOR( MEMORY_ADDRESS_WIDTH-1 downto 0 ) := (others=>'0');
begin
	bramMainMemory : entity work.bram   -- data memory
		generic map(INIT => (DATA_FILENAME & FILE_EXTENSION),
			        ADDR => 10,
			        DATA => DATA_WIDTH
		)
		port map(clk, writeToBRAM, addr(11 downto 2), bram_in, bram_out);

	-- state register
	state <= IDLE when reset = '1' else nextstate when rising_edge(clk);

	transition_logic : process(clk)
	begin
		case state is
			when IDLE =>
				if rdMEM = '0' and wrMEM = '1' then
					nextstate <= WRITE;
				elsif rdMEM = '1' and wrMEM = '0' then
					nextstate <= READ;
				end if;

			when READ =>
				if counter < BLOCKSIZE then
					nextstate <= READ;
				else
					nextstate <= IDLE;
				end if;

			when WRITE =>
				if counter < BLOCKSIZE then
					nextstate <= WRITE;
				else
					nextstate <= IDLE;
				end if;

			when others => nextstate <= IDLE;
		end case;
	end process;
	
	-- Output logic.
	readyMEM <= '0' when (state=READ and counter < BLOCKSIZE) else
				 '0' when (state=WRITE and counter < BLOCKSIZE) else
			    '1' when (state=READ and counter >= BLOCKSIZE) else
			    '1' when (state=WRITE and counter >= BLOCKSIZE);
			    
	counter <= 0 when (state=IDLE and rdMEM='0' and wrMEM='1') else
				0 when (state=IDLE and rdMEM='1' and wrMEM='0') else
				counter+1 when (state=READ and counter <BLOCKSIZE and rising_edge(clk)) else
				counter+1 when (state=WRITE and counter <BLOCKSIZE and rising_edge(clk));
	
	-- Store the read word.
	addrMEM_tmp <= addrMEM( MEMORY_ADDRESS_WIDTH-1 downto 4) & "0000" when state=IDLE;
	cacheBlockLine(counter-1) <= bram_out when counter > 0 and counter <= BLOCKSIZE and state=READ;
	addr                        <= STD_LOGIC_VECTOR(unsigned(addrMEM_tmp) + 4 * counter);

	-- Determine the output.
	dataMEM_out <= BLOCK_LINE_TO_STD_LOGIC_VECTOR(cacheBlockLine);

	-- -------------------------------------------------------------------------------------------------------------------------
	-- Control logic regarding writing to main memory.
	-- -------------------------------------------------------------------------------------------------------------------------

--	cacheBlockLine_in <= STD_LOGIC_VECTOR_TO_BLOCK_LINE(dataMEM_in);

--	bram_in <= cacheBlockLine_in(counter - 1) when counter > 0 and counter <= BLOCKSIZE;

end synth;