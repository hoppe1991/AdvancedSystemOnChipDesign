--------------------------------------------------------------------------------
-- filename : mainMemoryController.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 10/02/17
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Include packages.
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- Entity of the Main Memory Controller.
-- =============================================================================
entity mainMemoryController is
	generic(
		-- Width of bit string containing the memory address. 
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Number of words that a cache block contains.
		BLOCKSIZE            : integer := 4;

		-- Width of bit string containing a data/instruction word.
		DATA_WIDTH           : INTEGER := 32;
		
		-- Width of BRAM address (10 <=> Compare code in file mips.vhd).
		BRAM_ADDR_WIDTH 	: INTEGER := 10
	);

	port(
		-- Clock signal.
		clk         	: in  STD_LOGIC;
		
		-- Control signal to reset the main memory.
		reset       	: in  STD_LOGIC;	
		
		-- Signal identifies whether the main memory is ready.
		readyMEM    	: out STD_LOGIC;
		
		-- Control signal to read from main memory.
		rdMEM       	: in  STD_LOGIC;
		
		-- Control signal to write from main memory.
		wrMEM       	: in  STD_LOGIC;
		
		-- Address signal identifies which unit should be read from main memory.
		addrMEM     	: in  STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		
		-- Data to be read or written from main memory.
		dataMEM  	    : inout  STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
		
		-- Data to be written to BRAM.
		dataToBRAM 	 	: out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
		
		-- Data to be read from BRAM.
		dataFromBRAM 	: in STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
		
		-- Control signal to write to main memory.
		writeToBRAM 	: out STD_LOGIC;
		
		-- Address signal used for BRAM of the main memory.
		addrBram 		: out STD_LOGIC_VECTOR(BRAM_ADDR_WIDTH - 1 downto 0) 
	);
end;

-- =============================================================================
-- Architecture of the entity of the Main Memory Controller.
-- =============================================================================
architecture synth of mainMemoryController is
	
	-- Definition of possible states of the FSM.
	type statetype is (
		IDLE,
		READ,
		WRITE,
		DELAY
	);
	
	-- Number of bits in a cache line.
	constant cacheLineBits : INTEGER := BLOCKSIZE * DATA_WIDTH;
	
	-- The ready signal is activated after 20 cycles.
	constant readySignalAfter : INTEGER := 20;
 
	-- Signal contains the memory address.
	signal addr : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
	  
	-- Definition of type BLOCK_LINE as an array of STD_LOGIC_VECTORs.
	TYPE BLOCK_LINE IS ARRAY (BLOCKSIZE - 1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	
	-- Signal containing the cache block line to be read from BRAM.
	signal cacheBlockLine_out : BLOCK_LINE;
	
	-- Signal containing the cache block line to be written from BRAM.
	signal cacheBlockLine_in : BLOCK_LINE;

 	-- Auxiliary signal.
	signal counter : integer := BLOCKSIZE + BLOCKSIZE;

	-- Register cache block line should be written into BRAM.
	signal regCacheBlockLine : STD_LOGIC_VECTOR( cacheLineBits-1 downto 0) := (others => '0');
	
	-- Bit string containing the input address modulo 16.
	signal addrMEM_mod16 : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others => '0');
	
	-- Auxiliary signal to determine the data to MEM.
	signal dataMEM_out_tmp : STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
	 
	-- Actual state of the FSM.
	signal state     : statetype := IDLE;
	
	-- Next state of the FSM.
	signal nextstate : statetype := IDLE;
	
	signal wrRequest : STD_LOGIC := '0';
	signal rdRequest : STD_LOGIC := '0';
	
	-- Returns the given STD_LOGIC_VECTOR as a BLOCK_LINE.
	function STD_LOGIC_VECTOR_TO_BLOCK_LINE(ARG : in STD_LOGIC_VECTOR(cacheLineBits - 1 downto 0)) return BLOCK_LINE is
		variable v          : BLOCK_LINE;
		variable startIndex : INTEGER;
		variable endIndex   : INTEGER;
	begin
		for I in 0 to BLOCKSIZE - 1 loop
			startIndex := cacheLineBits - 1 - I * DATA_WIDTH;
			endIndex   := cacheLineBits - (I + 1) * DATA_WIDTH;
			v(I)       := ARG(startIndex downto endIndex);
		end loop;
		return v;
	end;

	-- Returns the given BLOCK_LINE as a STD_LOGIC_VECTOR. 
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
 
begin
	 
	wrRequest <= '1' when wrMEM='1' and rdMEM='0' else '0';
	rdRequest <= '1' when rdMEM='1' and wrMEM='0' else '0';

	-- state register
	state <= IDLE when reset = '1' else nextstate when rising_edge(clk);

	transition_logic : process(counter, rdRequest, state, wrRequest)
	begin
		case state is
			when IDLE =>
				if wrRequest='1' then
					nextstate <= WRITE;
				elsif rdRequest='1' then
					nextstate <= READ;
				end if;

			when READ =>
				if counter <= BLOCKSIZE then
					nextstate <= READ;
				else
					nextstate <= DELAY;
				end if;

			when WRITE =>
				if counter < BLOCKSIZE then
					nextstate <= WRITE;
				else
					nextstate <= DELAY;
				end if;
				
			when DELAY => 
				if counter < readySignalAfter then
					nextstate <= DELAY;
				else
					nextstate <= IDLE;
				end if;
				
		end case;
	end process;
	
	-- Write to BRAM.
	writeToBRAM <= '1' when (state=WRITE and counter < BLOCKSIZE) else
				   --'1' when (state=IDLE and rdMEM='0' and wrMEM='1') else
				   '0' when (state=WRITE and counter >= BLOCKSIZE) else
				   '0' when (state=READ and counter >= BLOCKSIZE) else
				   '0' when (state=IDLE and rdMEM='1' and wrMEM='0') else
				   '0';

	-- Output logic.
	readyMEM <= 
				'1' when (state=DELAY and counter >= readySignalAfter) else
				'0' when (state/=IDLE) else
				'0' when (state=IDLE and wrMEM='1' and rdMEM='0') else
				'0' when (state=IDLE and wrMEM='0' and rdMEM='1');
				--'1' when (state=IDLE and wrMEM/='1' and rdMEM='1') else
				
	-- Increment counter.
	counter <= 0 when (state=IDLE and wrRequest='1') else
			   0 when (state=IDLE and rdRequest='1') else
			   counter+1 when state/=IDLE and rising_edge(clk);

	-- Store the read word.
	addrMEM_mod16               <= addrMEM(MEMORY_ADDRESS_WIDTH - 1 downto 4) & "0000" when state = IDLE;
	cacheBlockLine_out(counter-1) <= dataFromBRAM when counter>0 and counter<=BLOCKSIZE;
	addr                        <= STD_LOGIC_VECTOR(unsigned(addrMEM_mod16) + 4 * counter) when state=READ else
								   STD_LOGIC_VECTOR(unsigned(addrMEM_mod16) + 4 * counter) when state=WRITE;
	addrBram <= addr( 11 downto 2 );

	-- Determine the output.
	regCacheBlockLine <= dataMEM when state = IDLE;
	cacheBlockLine_in  <= STD_LOGIC_VECTOR_TO_BLOCK_LINE(regCacheBlockLine) when state = IDLE;
	dataToBRAM            <= cacheBlockLine_in(counter) when counter >= 0  and counter < BLOCKSIZE;
 
	-- Determine the output.
	dataMEM_out_tmp <= BLOCK_LINE_TO_STD_LOGIC_VECTOR( cacheBlockLine_out );
	dataMEM <= dataMEM_out_tmp when state=WRITE AND counter>=BLOCKSIZE else
			   dataMEM_out_tmp when state=READ AND counter>=BLOCKSIZE else
			   dataMEM_out_tmp when state=DELAY else
			   dataMEM_out_tmp when state=IDLE and wrMEM='0' else
				(others=>'Z'); 

end synth;