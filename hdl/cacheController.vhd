--------------------------------------------------------------------------------
-- filename : cacheController.vhd
-- author   : Meyer zum Felde, P�ttjer, Hoppe
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

entity cacheController is
	generic(
		MEMORY_ADDRESS_WIDTH : INTEGER := 32; -- Memory address is 32-bit wide.
		DATA_WIDTH           : INTEGER := 32; -- Length of instruction/data words.
		BLOCKSIZE            : INTEGER := 4; -- Number of words that a block contains.
		ADDRESSWIDTH         : INTEGER := 256; -- Number of cache blocks.
		OFFSET               : INTEGER := 8 -- Number of bits that can be selected in the cache.
	);

	port(
		-- Clock and reset signal.
		clk         : in    STD_LOGIC;
		reset       : in    STD_LOGIC;
	
		-- Ports regarding Direct Mapped Cache.
		rdWord 		: out 	STD_LOGIC;	-- Signal indicates whether to write a complete block line from Direct Mapped Cache.
		wrWord 		: out 	STD_LOGIC; 	-- Signal indicates whether to write to Direct Mapped Cache.
		wrCBLine 	: out 	STD_LOGIC;	-- Signal indicates whether to write cache block line to Direct Mapped Cache.
		rdCBLine	: out   STD_LOGIC;  -- Signal indicates whether to read a complete block line from Direct Mapped Cache.
		writeMode   : out   STD_LOGIC;
		valid 			: inout STD_LOGIC; 	-- Valid bit from Direct Mapped Cache.
		dirty 			: inout STD_LOGIC;
		setValid 		: out 	STD_LOGIC;	-- Indicates whether to reset the valid bit of Direct Mapped Cache.
		setDirty 		: out 	STD_LOGIC;	-- Indicates whether to set the dirty bit of Direct Mapped Cache.
		hitFromCache 	: in 	STD_LOGIC; -- Indicates whether hit from direct mapped cache is reached.
		addrDMC	: out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0); -- Memory address to Direct Mapped Cache.
		
		dataToMEM : in STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE-1 downto 0); -- Cache block line from main memory to be written to main memory.
		newCacheBlockLine : out STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0); -- New cache block line to be written into cache.
				   
		-- Ports regarding to CPU.
		hitCounter  : out   INTEGER; -- Counter stores the number of cache hits.
		missCounter : out   INTEGER; -- Counter stores the number of cache misses.
		stallCPU    : out   STD_LOGIC; -- Signal identifies whether to stall the CPU or not.
		rdCPU       : in    STD_LOGIC; -- Read signal from CPU.
		wrCPU       : in    STD_LOGIC; -- Write signal from CPU.
		addrCPU     : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0); -- Address signal from CPU.
		dataCPU     : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data signal from/to CPU.
		
		-- Ports regarding MEM.
		readyMEM    : in    STD_LOGIC;
		rdMEM       : out   STD_LOGIC;
		wrMEM       : out   STD_LOGIC;
		addrMEM     : out   STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataMEM     : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0)
	);

end;

architecture synth of cacheController is

	-- Constant object.
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);
	constant cacheBlockLineBits : INTEGER := config.cacheLineBits;
	
	-- Definition of type BLOCK_LINE as an array of STD_LOGIC_VECTORs.
	type BLOCK_LINE is array(0 to (BLOCKSIZE-1)) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	
	-- Memory address consists of tag, index and offset vector.
	type MEMORY_ADDRESS is record
		tag    : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0);
		index  : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0);
		offset : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0);
		indexAsInteger : INTEGER;
		offsetAsInteger : INTEGER;
	end record;
 
	-- Definition of auxiliary functions.
	function STD_LOGIC_VECTOR_TO_BLOCK_LINE(ARG : in STD_LOGIC_VECTOR(cacheBlockLineBits-1 downto 0)) return BLOCK_LINE;
	function TO_MEMORY_ADDRESS(ARG : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0)) return MEMORY_ADDRESS;
	function TO_STD_LOGIC_VECTOR(ARG : in MEMORY_ADDRESS) return STD_LOGIC_VECTOR;
	function BLOCK_LINE_TO_STD_LOGIC_VECTOR(ARG : in BLOCK_LINE) return STD_LOGIC_VECTOR;
	function GET_NEW_CACHE_BLOCK_LINE(
		blockLine 		: in STD_LOGIC_VECTOR(cacheBlockLineBits-1 downto 0);
		data 	  		: in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
		offsetAsInteger : in INTEGER
	) return STD_LOGIC_VECTOR;
		
	-- Declaration of states.
	type statetype is (
		IDLE,
		CHECK1,
		WRITE_BACK1,
		WRITE_BACK1_DELAY,
		WRITE,
		TOCACHE1,
		CHECK2,
		WRITE_BACK2,
		WRITE_BACK2_DELAY,
		READ,
		TOCACHE2
	);

	function TO_MEMORY_ADDRESS(ARG : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0)
	) return MEMORY_ADDRESS is
		variable addr : MEMORY_ADDRESS;
	begin
		addr.tag    := ARG(config.tagIndexH downto config.tagIndexL);
		addr.index  := ARG(config.IndexIndexH downto config.IndexIndexL);
		addr.offset := ARG(config.offsetIndexH downto config.offsetIndexL);
		addr.indexAsInteger := TO_INTEGER(UNSIGNED(addr.index));
		addr.offsetAsInteger := TO_INTEGER(UNSIGNED(addr.offset));
		return addr;
	end function;
	
	function TO_STD_LOGIC_VECTOR(ARG : in MEMORY_ADDRESS) return STD_LOGIC_VECTOR is
		variable addr : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	begin
		addr := ARG.tag & ARG.index & ARG.offset;
		return addr;
	end function;
	
	signal addrCPUZero : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	signal addressCPU : MEMORY_ADDRESS := TO_MEMORY_ADDRESS(addrCPUZero);
	
	-- Current state of FSM.
	signal state     : statetype := IDLE;
	
	-- Next state of FSM.
	signal nextstate : statetype := IDLE;
	
	-- Hit and Miss counter registers are initialized with Zero on reset.
	-- They counts the number of occurrences of cache hits and cache misses.
	signal rHitCt, rMissCt  : INTEGER := 0;

	-- Auxiliary signals.
	signal lineIsInvalid  : STD_LOGIC := '0';
	signal lineIsNotDirty : STD_LOGIC := '0';
	signal lineIsDirty    : STD_LOGIC := '0';
	
	function GET_NEW_CACHE_BLOCK_LINE(
		blockLine 		: in STD_LOGIC_VECTOR(cacheBlockLineBits-1 downto 0);
		data 	  		: in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
		offsetAsInteger	: in INTEGER
	) return STD_LOGIC_VECTOR is
		variable newCacheBlockLine : STD_LOGIC_VECTOR(cacheBlockLineBits-1 downto 0) := (others=>'0');
		variable b : BLOCK_LINE;
	begin
		b := STD_LOGIC_VECTOR_TO_BLOCK_LINE( blockLine );
		for I in 0 to BLOCKSIZE-1 loop
			if (I = offsetAsInteger) then
				b(I) := data;
			else
				b(I) := b(I);
			end if;
		end loop;
		newCacheBlockLine := BLOCK_LINE_TO_STD_LOGIC_VECTOR( b );
		return newCacheBlockLine;
	end;

	-- Returns the given BLOCK_LINE as a STD_LOGIC_VECTOR. 
	function BLOCK_LINE_TO_STD_LOGIC_VECTOR(ARG : in BLOCK_LINE) return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR(config.cacheLineBits - 1 downto 0);
	begin
		v := (others => '0');
		for I in 0 to BLOCKSIZE - 1 loop
			v                          := std_logic_vector(unsigned(v) sll DATA_WIDTH);
			v(DATA_WIDTH - 1 downto 0) := ARG(I);
		end loop;
		return v;
	end;

	-- Returns the given STD_LOGIC_VECTOR as a BLOCK_LINE.
	function STD_LOGIC_VECTOR_TO_BLOCK_LINE(ARG : in STD_LOGIC_VECTOR(cacheBlockLineBits-1 downto 0)) return BLOCK_LINE is
		variable v          : BLOCK_LINE;
		variable startIndex : INTEGER;
		variable endIndex   : INTEGER;
	begin
		for I in 0 to BLOCKSIZE - 1 loop
			startIndex := config.cacheLineBits - 1 - I * DATA_WIDTH;
			endIndex   := config.cacheLineBits - (I + 1) * DATA_WIDTH;
			v(I)       := ARG(startIndex downto endIndex);
		end loop;
		return v;
	end;

	signal auxiliaryCounter : INTEGER := 1;
	signal myBlockLine : BLOCK_LINE;
begin
	 
	-- State register.
	state <= IDLE when reset = '1' else nextstate when rising_edge(clk);
	
	--------------------------------------------
	-- TransitionLogic:
	-- Transition logic of FSM.
	--------------------------------------------
	TransitionLogic : process( state, wrCPU, rdCPU, hitFromCache, dirty, readyMEM, valid, auxiliaryCounter)
	begin
		case state is
			when IDLE =>
				if wrCPU = '1' and rdCPU = '0' then
					nextstate <= CHECK1;
				elsif rdCPU = '1' and wrCPU = '0' then
					nextstate <= CHECK2;
				end if;

			when CHECK1 =>
				if hitFromCache='1' and valid='1' and auxiliaryCounter=0 then
					nextstate <= IDLE;
				elsif valid = '0' and auxiliaryCounter=0 then
					nextstate <= WRITE;
				elsif hitFromCache='0' and valid='1' and dirty='0' and auxiliaryCounter=0 then
					nextstate <= WRITE;
				elsif hitFromCache='0' and valid='1' and dirty='1' and auxiliaryCounter=0 then
					nextstate <= WRITE_BACK1;
				end if;
				
			when CHECK2 =>
				if hitFromCache='1' and valid='1' and auxiliaryCounter=0 then
					nextstate <= IDLE;
				elsif valid = '0' and auxiliaryCounter=0 then
					nextstate <= READ;
				elsif hitFromCache='0' and valid='1' and dirty='0' and auxiliaryCounter=0 then
					nextstate <= READ;
				elsif hitFromCache='0' and valid='1' and dirty='1' and auxiliaryCounter=0 then
					nextstate <= WRITE_BACK2;
				end if;

			when WRITE =>
				if readyMEM = '1' then
					nextstate <= TOCACHE1;
				else
					nextstate <= WRITE;
				end if;

			when WRITE_BACK1 =>
				if readyMEM = '1' then
					nextstate <= WRITE_BACK1_DELAY;
				else
					nextstate <= WRITE_BACK1;
				end if;
				
			when WRITE_BACK1_DELAY =>
				nextstate <= WRITE;
			

			when READ =>
				if readyMEM = '1' then
					nextstate <= TOCACHE2;
				else
					nextstate <= READ;
				end if;
				
			when TOCACHE1 =>
				nextstate <= IDLE;
				
			when TOCACHE2 => 
				nextstate <= IDLE;
				

			when WRITE_BACK2 =>
				if readyMEM = '1' then
					nextstate <= WRITE_BACK2_DELAY;
				else
					nextstate <= WRITE_BACK2;
				end if;
				
			when WRITE_BACK2_DELAY =>
				nextstate <= READ;

		    -- Warning: Case statement contains all choices explicitly. You can safely remove redundant 'others'.
			-- when others => nextstate <= IDLE;
		end case;
	end process;
		 
	-- Update the auxiliary counter regarding delays.
	auxiliaryCounter <= 1 when state=IDLE and rdCPU='1' and wrCPU='0' else
						1 when state=IDLE and wrCPU='1' and rdCPU='0' else
						auxiliaryCounter-1 when state=CHECK1 and rising_edge(clk) else
						auxiliaryCounter-1 when state=CHECK2 and rising_edge(clk);
		 
	-- ------------------------------------------------------------------------------------
	-- Handling of memory address.
	-- ------------------------------------------------------------------------------------
	addressCPU 	<= TO_MEMORY_ADDRESS( addrCPU ) when state=IDLE and wrCPU='1' and rdCPU='0' else
				   TO_MEMORY_ADDRESS( addrCPU ) when state=IDLE and wrCPU='0' and rdCPU='1';
	addrMEM 	<= TO_STD_LOGIC_VECTOR( addressCPU );
	addrDMC		<= TO_STD_LOGIC_VECTOR( addressCPU );
		 
	-- ------------------------------------------------------------------------------------
	-- Increment or reset hit counter and miss counter.
	-- ------------------------------------------------------------------------------------
	rHitCt  <= 0 when reset='1' else
			   rHitCt+1 when state=CHECK1 and hitFromCache='1' and rising_edge(clk) and valid='1' and auxiliaryCounter=0 else
		       rHitCt+1 when state=CHECK2 and hitFromCache='1' and rising_edge(clk) and auxiliaryCounter=0;
		       
	rMissCt <= 0 when reset='1' else
			   rMissCt+1 when state=TOCACHE2 and rising_edge(clk) else
			   rMissCt+1 when state=TOCACHE1 and rising_edge(clk);
				    
	-- Export the miss counter and hit counter.
	missCounter <= rMissCt;
	hitCounter  <= rHitCt;

 
	-- ------------------------------------------------------------------------------------
	-- Set the auxiliary signals.
	-- ------------------------------------------------------------------------------------
	lineIsInvalid  		<= '1' when hitFromCache='0' and valid='0' else '0';
	lineIsNotDirty 		<= '1' when hitFromCache='0' and valid='1' and dirty='0' else '0';
	lineIsDirty    		<= '1' when hitFromCache='0' and valid='1' and dirty='1' else '0';
	
	rdWord	            <= '1' when (state=IDLE and wrCPU='1' and rdCPU='0') else 
						   '1' when (state=IDLE and wrCPU='0' and rdCPU='1') else
						   '0' when (state=WRITE and readyMEM='1') else
						   '0' when (state=CHECK2 and hitFromCache='1' and auxiliaryCounter=0) else
						   '0' when (state=CHECK1 and hitFromCache='1' and auxiliaryCounter=0) else
						   '0' when (state=READ and readyMEM='1') else
						   '0' when (state=TOCACHE2);
						   
	wrWord            	<= '0' when (state=IDLE) else
					       '0' when (state=IDLE and rdCPU='1') else
						   '1' when (state=CHECK1 and hitFromCache='1') else
						   '0';
	
	wrCBLine 		    <= '0' when (state=IDLE) else 
						   '1' when (state=WRITE and readyMEM='1') else
						   '1' when (state=READ and readyMEM='1') else
						   '0';
							
	rdCBLine 			<= '0';
	
	-- ------------------------------------------------------------------------------------
	-- Determine whether to stall the CPU.
	-- ------------------------------------------------------------------------------------
	stallCPU <= '1' when (state=IDLE and wrCPU='1' and rdCPU = '0') else
		        '1' when (state=IDLE and wrCPU='0' and rdCPU = '1') else
		        '0' when (state=IDLE);
				
		        
		        
		        
		        
	
	-- ------------------------------------------------------------------------------------
	-- Determine whether to read or to write from the Main Memory.
	-- ------------------------------------------------------------------------------------
	rdMEM <= '1' when (state=CHECK1 and lineIsInvalid='1') else 
			 '1' when (state=CHECK1 and lineIsNotDirty='1') else 
			 '1' when (state=WRITE_BACK1_DELAY) else 
			 '1' when (state=WRITE_BACK2_DELAY) else
			 '1' when (state=CHECK2 and lineIsInvalid='1') else
			 '1' when (state=CHECK2 and lineIsNotDirty='1') else
			 '1' when (state=WRITE and readyMEM='0') else
			 '0';
			 
	wrMEM <= 
			 '1' when (state=CHECK1 and lineIsDirty='1' and auxiliaryCounter=0) else 
			 '1' when (state=CHECK2 and lineIsDirty='1' and auxiliaryCounter=0) else
			 '0';
			 
	writeMode <= '1' when (state=IDLE and wrCPU='1') else
				 '0' when state=IDLE;
				 
	setValid <= '1' when (state=WRITE and readyMEM='1' and rising_edge(clk)) else 
	            '1' when (state=READ and readyMEM = '1' and rising_edge(clk)) else 
	            '0' when rising_edge(clk);
	
	dirty <= '1' when (state=CHECK1 and hitFromCache='1' and valid='1') else 
	         '1' when (state=WRITE and readyMEM='1') else
	         'Z';
	         
	setDirty <= '1' when (state=CHECK1 and hitFromCache='1' and valid='1' and auxiliaryCounter=0) else 
	            '1' when (state=WRITE and readyMEM = '1') else 
	            '0';
	
	newCacheBlockLine <= GET_NEW_CACHE_BLOCK_LINE( dataMEM, dataCPU, addressCPU.offsetAsInteger) when (state=WRITE and readyMEM='1') else
						 dataMEM when (state=READ and readyMEM='1');
	
	-- Determine the data word to be written to Main Memory.
	dataMEM           <= dataToMEM when (state=CHECK2 and hitFromCache='0' and valid='1' and dirty='1' and auxiliaryCounter=0) else
						 dataToMEM when (state=CHECK1 and lineIsDirty='1' and auxiliaryCounter=0) else
						 (others=>'Z');
	
	
	
	myBlockLine <= STD_LOGIC_VECTOR_TO_BLOCK_LINE(dataMEM) when state=TOCACHE2;
	
	-- Data CPU output.
	dataCPU <= myBlockLine(addressCPU.offsetAsInteger) when state=TOCACHE2 else
			   (others=>'Z') when (state=IDLE and wrCPU='1' and rdCPU='0') else
			   (others=>'Z') when (state=IDLE and rdCPU='1' and wrCPU='0') else
			   dataCPU when (state=IDLE and rdCPU='0' and wrCPU='0') else
			   dataCPU when (hitFromCache='1' and state = CHECK2 and auxiliaryCounter=0);
end synth;
