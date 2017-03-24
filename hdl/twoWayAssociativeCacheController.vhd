--------------------------------------------------------------------------------
-- filename : twoWayAssociativeCacheController.vhd
-- author   : Meyer zum Felde, P�ttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 21/02/17
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Include packages.
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cache_pkg.ALL;
use IEEE.NUMERIC_STD.all;

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
		TAG_FILENAME         : STRING  := "../imem/tagFileName";

		-- Filename for data BRAM.
		DATA_FILENAME        : STRING  := "../imem/dataFileName";

		-- File extension for BRAM.
		FILE_EXTENSION       : STRING  := ".txt";
		REPLACEMENT_STRATEGY : replacementStrategy :=  LRU_t
	);

	port(
		-- Clock signal is used for BRAM.
		clk                                : in    STD_LOGIC;
		reset                              : in    STD_LOGIC;
		
		-- Ports regarding the two direct mapped caches.
		hit                                : in   STD_LOGIC_VECTOR(1 downto 0);
		wrCBLine, rdCBLine, rdWord, wrWord : out   STD_LOGIC_VECTOR(1 downto 0);
		writeMode             			   : out   STD_LOGIC_VECTOR(1 downto 0);
		setValid, setDirty   	   		   : out   STD_LOGIC_VECTOR(1 downto 0);
		valid							   : inout STD_LOGIC_VECTOR(1 downto 0);
		dirty 							   : inout   STD_LOGIC_VECTOR(1 downto 0);
		dataCPU0                           : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.
		dataCPU1                           : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.
		dataToMEM0						   : in STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE/2 downto 0);
		dataToMEM1						   : in STD_LOGIC_VECTOR(DATA_WIDTH*BLOCKSIZE/2 downto 0);		
		newCacheBlockLine1                 : inout   STD_LOGIC_VECTOR(BLOCKSIZE/2*DATA_WIDTH - 1 downto 0) := (others => '0');
		newCacheBlockLine0                 : inout   STD_LOGIC_VECTOR(BLOCKSIZE/2*DATA_WIDTH - 1 downto 0) := (others => '0');
		
		-- Ports regarding CPUs.
		dataCPU                            : inout STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data from CPU to cache or from cache to CPU.
		addrCPU                            : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0); -- Memory address from CPU is divided into block address and block offset.
		wrCPU                              : in    STD_LOGIC; -- Write signal identifies whether a complete cache block should be written into cache.
		rdCPU                              : in    STD_LOGIC; -- Read signal identifies whether a complete cache block should be read from cache.
		stallCPU                           : out   STD_LOGIC; -- Signal identifies whether to stall the CPU or not.

		-- Hit and miss counter.
		hitCounter                         : out   INTEGER; -- Signal counts the number of cache hits.
		missCounter                        : out   INTEGER; -- Signal counts the number of cache misses.
		
		-- Ports regarding MEM.
		dataToMEM                          : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE/2 - 1 downto 0); -- Data from memory to cache or from cache to memory.
		readyMEM                           : in    STD_LOGIC; -- Signal identifies whether the main memory is ready.
		wrMEM                              : out   STD_LOGIC; -- Read signal identifies to read data from the cache.
		rdMEM                              : out   STD_LOGIC -- Write signal identifies to write data into the cache.
	);
end;

-- =============================================================================
-- Definition of architecture.
-- =============================================================================
architecture synth of twoWayAssociativeCacheController is

		
	-- Declaration of states.
	type statetype is (
		IDLE,
		CHECK,
		CACHE_HIT,
		CACHE_MISS, 	-- Stall CPU
		DIRTY_CHECK, 	--check LRU bit
		WRITE_BACK, 	--Write cash line in main memory
		EVICTION, 
		WRITE_TO_CACHE, 
		DELAY_WB, 		--Delay after Writeback
		UPDATE_LRU_BIT, 
		BLOCK_TO_CACHE	-- Writing a new cash line
	
	);

	-- Current state of FSM.
	signal state     		: statetype := IDLE;
	
	-- Next state of FSM.
	signal nextstate 		: statetype := IDLE;
	
	-- Least recently used bit = not(use bit)
	signal LRU, LRU_neg : INTEGER	:= 0;
	
	-- Use bit identifies which cache is used. 0, when the first cache is used. 1, otherwise.
	signal use_bit : INTEGER := 0;
	
	-- Not Use bit identifies which cache is not used. 0, when the first cache is not used. 1, otherwise.
	signal not_use_bit : INTEGER := 0; 
	
	-- Hit and Miss counter registers are initialized with Zero on reset.
	-- They counts the number of occurrences of cache hits and cache misses.
	signal rHitCt, rMissCt  : INTEGER := 0;
	
	-- Counts down like a delay function.
	signal delay_Counter  	: INTEGER := 0;
	
	-- Read (not write) signal is set to '1' when the CPU reads the Cache. It is set to '0', when the CPU writes to Cache.
	signal RD_NOTWR 		: std_logic:= '0';
	
	-- Flip flop used for Random strategy. This flip flop is toggled in case of cache miss.
	signal flipFlop : STD_LOGIC := '0';
	
	signal flipFlopI : INTEGER := 0;


begin
	
	-- State register.
	state <= IDLE when reset = '1' else nextstate when rising_edge(clk);
	
	--------------------------------------------
	-- Transition logic of FSM.
	--------------------------------------------
	TransitionLogic : process( state, wrCPU, rdCPU, dirty, readyMEM, valid, LRU, delay_Counter, hit(0), hit(1), reset)
	begin
		case state is
			when IDLE =>
				if (wrCPU /= rdCPU) and (reset = '0') then
					nextstate <= CHECK;
				elsif reset = '1' then
					nextstate <= IDLE;
				end if;

			when CHECK =>
				if hit(0)='0' and hit(1)= '0' and (delay_Counter = 0) then
					nextstate <= CACHE_MISS;
				elsif delay_Counter= 0 and hit(0) = '1' then
					nextstate <= CACHE_HIT;
				elsif delay_Counter= 0 and hit(1) = '1' then
					nextstate <= CACHE_HIT;
				end if;
				
						
			when CACHE_HIT =>
				nextstate <= IDLE;
			
			when CACHE_MISS =>
				if (valid(0)='1') and (valid(1) = '1' ) then
					nextstate <= DIRTY_CHECK;
				else
					nextstate <= EVICTION;
				end if;

			when DIRTY_CHECK =>
				if dirty(LRU) = '1'  then
					nextstate <= WRITE_BACK;
				elsif (dirty(LRU) = '0') then
					nextstate <= EVICTION;
				end if;
							

			when WRITE_BACK =>
				if readyMEM = '0' then
					nextstate <= WRITE_BACK;
				elsif (readyMEM = '1') then
					nextstate <= DELAY_WB;
				end if;
				
			when DELAY_WB=>
				nextstate <= EVICTION;
				
			when EVICTION=> 
				nextstate <= BLOCK_TO_CACHE;
				
			when BLOCK_TO_CACHE =>
				if readyMEM = '1' then
					nextstate <= WRITE_TO_CACHE;
				end if;
				
			when WRITE_TO_CACHE =>
				nextstate <= UPDATE_LRU_BIT;
				
			when UPDATE_LRU_BIT =>
				nextstate <= IDLE;
				
		    -- Warning: Case statement contains all choices explicitly. You can safely remove redundant 'others'.
			-- when others => nextstate <= IDLE;
		end case;
	end process;	

	-- ------------------------------------------------------------------------------------
	-- LRU logic
	-- ------------------------------------------------------------------------------------
	LRU_FLIPFLOP_LOGIC: block
	begin
		
		-- Update the USE bit.
		use_bit <= 0 when state=IDLE and reset='1' else
				   0 when state=CHECK and delay_counter=0 and hit(0)='1' and hit(1)='0' 						else
		           1 when state=CHECK and delay_counter=1 and hit(0)='0' and hit(1)='1' 						else
		           0 when state=CACHE_MISS and valid(0)='0' and valid(1)='1' 									else
		           1 when state=CACHE_MISS and valid(0)='1' and valid(1)='0' 									else
		           0 when state=CACHE_MISS and valid(0)='0' and valid(1)='0' 									else
		   flipFlopI when state=CACHE_MISS and valid(0)='1' and valid(1)='1' and REPLACEMENT_STRATEGY=RANDOM_t 	else
		         LRU when state=CACHE_MISS and valid(0)='1' and valid(1)='1' and REPLACEMENT_STRATEGY=LRU_t
		           ;
		
		-- Update the not USE bit.
		not_use_bit <= 0 when use_bit=1 else
		               1 when use_bit=0; 
		           
		-- Update the LRU bit. TODO          
		LRU 		<= 0 when state = CHECK and delay_Counter = 1 and hit(1) = '1' else
		 		   1 when state = CHECK and delay_Counter = 1 and hit(0) = '1' else
		 		   0 when state = UPDATE_LRU_BIT and rising_edge(clk) and LRU=1 else
		 		   1 when state = UPDATE_LRU_BIT and rising_edge(clk) and LRU=0;
--	LRU 	    <= 1 when state = CACHE_MISS and valid(0) = '0' and valid(1) = '1' else 		--!valid(0) and valid(1) => LRU = 0
--		 		   1 when state = CACHE_MISS and valid(0) = '1' and valid(1) = '0' else 		--valid(0) and !valid(1) => LRU = 1
--		 		   0 when state = CACHE_MISS and valid(0) = '0' and valid(1) = '0' ; 			--!valid(0) and !valid(1) => LRU = 0
--	LRU 		<= LRU_neg 			when state = UPDATE_LRU_BIT;		 		   
--	LRU 		<= 0 		when state = IDLE and reset = '1';	
		 		   
		-- Update the not LRU bit.
		LRU_neg 	<= 0 when LRU = 1 else 1;

		-- Toggle flip flop in case of cache miss.		
		flipFlop	<= '0' when state=CACHE_MISS and valid(0)='0' and valid(1)='1' else
					   '1' when state=CACHE_MISS and valid(0)='1' and valid(1)='0' else
					   '0' when state=CACHE_MISS and valid(0)='0' and valid(1)='0' else
			 not(flipFlop) when state=CACHE_MISS and valid(0)='1' and valid(1)='1' and rising_edge(clk);
		flipFlopI   <= 0   when flipFlop='0' else 1;
		
	end block LRU_FLIPFLOP_LOGIC;
	
	-- Update the auxiliary counter regarding delays.
	delay_Counter 	<= 1 when state=IDLE and rdCPU='1' and wrCPU='0' else
					   1 when state=IDLE and wrCPU='1' and rdCPU='0' else
					   delay_Counter-1 when state=CHECK and rising_edge(clk);
		  
	-- ------------------------------------------------------------------------------------
	-- LRU logic
	-- ------------------------------------------------------------------------------------
	VALID_DIRTY_LOGIC: block
	begin
		
	-- Block at top right
	dirty(USE_BIT) 				<= '1' when (RD_NOTWR = '0' ) and state = CACHE_HIT;
	valid(USE_BIT) 				<= '1' when (RD_NOTWR = '0' ) and state = CACHE_HIT;
	
	end block VALID_DIRTY_LOGIC;			          						   

	-- WRITE_TO_CACHE
	dirty(LRU)	<= NOT(RD_NOTWR) 	when state = UPDATE_LRU_BIT;
	valid(LRU) 	<= RD_NOTWR			when state = UPDATE_LRU_BIT;	 	 		   


	-- ------------------------------------------------------------------------------------
	-- Control logic to controls the two direct mapped caches.
	-- ------------------------------------------------------------------------------------
	CONTROL_SIGNALS: block
	begin
		
		wrWord(use_bit) <= '1' when (state=CHECK and delay_counter=0) and RD_NOTWR='0' else
						   '0' when (state=CHECK and delay_counter=0) and RD_NOTWR='1';
						   
		wrWord(not_use_bit) <= '0' when (state=CHECK and delay_counter=0);
		
		rdWord(use_bit) <= '1' when (state=CHECK and delay_counter=0) and RD_NOTWR='1' else
						   '0' when (state=CHECK and delay_counter=0) and RD_NOTWR='0';
		
		rdWord(not_use_bit) <= '0' when (state=CHECK and delay_counter=0);		

	end block CONTROL_SIGNALS;
		
		
		
	-- ------------------------------------------------------------------------------------
	-- Control logic regarding Main Memory. Controls whether the Main Memory
	-- should be written or read.
	-- ------------------------------------------------------------------------------------
	MEM_CONTROL: block
	begin
		
		wrMEM <= '1' when state=DIRTY_CHECK and dirty(LRU)='1' else '0';
		
		rdMEM <= '1' when state=DIRTY_CHECK and dirty(LRU)='0' else
				 '1' when state=DELAY_WB else
				 '1' when state=CACHE_MISS and valid(0)/='1' and valid(1)/='1' else
				 '0';
	end block MEM_CONTROL;
	
	
	-- ------------------------------------------------------------------------------------
	-- Control logic regarding the hit counter and miss counter.
	-- ------------------------------------------------------------------------------------
	HITCOUNTER_LOGIC: block
	begin
	
		-- Increment or reset hit counter.
		rHitCt  <= 0 when reset='1' else
			       rHitCt+1 when state=CACHE_HIT and rising_edge(clk);
			       
		-- Increment or reset miss counter.
		rMissCt <= 0 when reset='1' else
			       rMissCt+1 when state=CACHE_MISS and rising_edge(clk);
	
		-- Export the miss counter and hit counter.
		missCounter <= rMissCt;
		hitCounter  <= rHitCt;
	
	end block HITCOUNTER_LOGIC;
		
	-- ------------------------------------------------------------------------------------
	-- Determine whether to stall the CPU.
	-- ------------------------------------------------------------------------------------
	stallCPU <= '1' when (state=IDLE and wrCPU/=rdCPU) else
		        '0' when (state=IDLE);
		        
	-- ------------------------------------------------------------------------------------
	-- Updates the RD_NOTWR signal.
	-- ------------------------------------------------------------------------------------	     
	RD_NOTWR <= '1' when (state=IDLE and wrCPU='1' and rdCPU='0') else
				'0' when (state=IDLE and wrCPU='0' and rdCPU='1');
				

	-- 
	dataCPU0 <= dataCPU       when (state=CHECK and delay_counter=0) and RD_NOTWR='1' and use_bit=0 else
				(others=>'Z') when (state=CHECK and delay_counter=0) and RD_NOTWR='0' and use_bit=0;
				
	dataCPU1 <= dataCPU       when (state=CHECK and delay_counter=0) and RD_NOTWR='1' and use_bit=1 else
				(others=>'Z') when (state=CHECK and delay_counter=0) and RD_NOTWR='0' and use_bit=1;

		        
end synth;


--
--	LRU_STATEMENTS: if REPLACEMENT_STRATEGY=LRU_t generate
--	begin
--
--		-- CHECK + CACHE_HIT				    
--		wrWord(MY_NOT_USE_BIT)	<= '0' when (state = CHECK and delay_Counter = 0);	
--		rdWord(MY_NOT_USE_BIT)	<= '0' when (state = CHECK and delay_Counter = 0);
--		
--		wrWord(MY_USE_BIT)		<= not(RD_NOTWR) when (state=CHECK and delay_Counter = 0) else 
--						           '0' when state=CACHE_HIT;
--		rdWord(MY_USE_BIT)		<= RD_NOTWR when (state=CHECK and delay_Counter = 0) else 
--					               '0' when REPLACEMENT_STRATEGY=LRU_t and (state=CACHE_HIT);
--					               
--					               
--		-- BLOCK_TO_CACHE
--		wrWord(LRU_neg)        		<= '0' when state = BLOCK_TO_CACHE;
--		rdWord(LRU_neg)	       		<= '0' when state = BLOCK_TO_CACHE; 
--		wrWord(LRU)                 <= not(RD_NOTWR) when (state=BLOCK_TO_CACHE ) else
--						          '0' when (state=WRITE_TO_CACHE); 
--		rdWord(LRU)                 <= RD_NOTWR when (state=BLOCK_TO_CACHE ) else
--						          '0' when (state=WRITE_TO_CACHE); 		
--	end generate LRU_STATEMENTS;
