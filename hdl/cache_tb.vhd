--------------------------------------------------------------------------------
-- filename : cache_tb.vhd
-- author   : Meyer zum Felde, P�ttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.all;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.cache_pkg.all;

entity cache_tb is
	generic(
		MEMORY_ADDRESS_WIDTH 	: INTEGER := 32; -- Memory address is 32-bit wide.
		DATA_WIDTH           	: INTEGER := 32; -- Length of instruction/data words.
		BLOCKSIZE            	: INTEGER := 4; -- Number of words that a block contains.
		ADDRESSWIDTH         	: INTEGER := 256; -- Number of cache blocks.
		OFFSET               	: INTEGER := 8; -- Number of bits that can be selected in the cache.
		BRAM_ADDR_WIDTH 		: INTEGER := 10; -- Number of bits defining the BRAM address wide.
		TAG_FILENAME         	: STRING  := "../imem/tagCache";
		DATA_FILENAME        	: STRING  := "../imem/dataCache";
		MAIN_MEMORY_FILENAME 	: STRING  := "../imem/mainMemory";
		FILE_EXTENSION       	: STRING  := ".imem"
	);
end;

architecture tests of cache_tb is
	
	-- Constant object.
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);

	-- Declaration of procedures.
	procedure VALIDATE_SIGNALS( L : in INTEGER; I : in INTEGER; stallCPU : in STD_LOGIC; expectedStallCPU : in STD_LOGIC; missCounter : in INTEGER; expectedMissCounter : in INTEGER; hitCounter : in INTEGER; expectedHitCounter : INTEGER );
	procedure VALIDATE_SIGNALS( stallCPU : in STD_LOGIC; expectedStallCPU : in STD_LOGIC; missCounter : in INTEGER; expectedMissCounter : in INTEGER;hitCounter : in INTEGER; expectedHitCounter : INTEGER );
	procedure VALIDATE_SIGNAL( signalName : in STRING; currentValue : in INTEGER; expectedValue : in INTEGER );
	procedure VALIDATE_SIGNAL( signalName : in STRING; currentValue : in STD_LOGIC; expectedValue : in STD_LOGIC );
	procedure VALIDATE_SIGNAL( signalName : in STRING; currentVector : in STD_LOGIC_VECTOR; expectedVector : STD_LOGIC_VECTOR );
	
	-- Declaration of functions.
	function GET_RANDOM_DATA( rand : in REAL ) return STD_LOGIC_VECTOR;
	function GET_RANDOM( rand : in REAL; max : in REAL ) return INTEGER;
	function GET_DATA( ARG : in INTEGER ) return STD_LOGIC_VECTOR;
	function GET_RANDOM_TAG( rand : in REAL ) return INTEGER;
	function GET_TAG( ARG : in INTEGER ) return STD_LOGIC_VECTOR;
	 
	type CACHE_BLOCK_ARRAY is array((ADDRESSWIDTH-1) downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	
	impure function InitCacheBlockArray return CACHE_BLOCK_ARRAY is
    variable cacheBlock         : CACHE_BLOCK_ARRAY;
  	begin
	    for I in cacheBlock'range loop
	    	cacheBlock(I) := (others=>'0');
	    end loop;
	    return cacheBlock;
  	end function;

  	signal cacheBlockMEM: CACHE_BLOCK_ARRAY := InitCacheBlockArray;
	 
	 
	type TAG_ARRAY is array((ADDRESSWIDTH-1) downto 0) of INTEGER;
	
	impure function InitTagArray return TAG_ARRAY is
    variable tagArray         : TAG_ARRAY;
  	begin
	    for I in tagArray'range loop
	    	tagArray(I) := 0;
	    end loop;
	    return tagArray;
  	end function;

  	signal tagArrayMEM: TAG_ARRAY := InitTagArray;
	 
	 signal tagValueTmp : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) := (others=>'0'); -- TODO Remove this signal.
	 
	 
	-- Report mode indicates whether all reports will be printed to console.
	signal report_mode : STD_LOGIC := '0';
		
	signal clk, reset : STD_LOGIC := '0';

	signal stallCPU : STD_LOGIC                                             := '0';
	signal rdCPU    : STD_LOGIC                                             := '0';
	signal wrCPU    : STD_LOGIC                                             := '0';
	signal addrCPU  : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0)   := (others => '0');
 	signal dataCPU  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)             := (others => '0');
	signal readyMEM : STD_LOGIC                                             := '0';
	signal rdMEM    : STD_LOGIC                                             := '0';
	signal wrMEM    : STD_LOGIC                                             := '0';
	signal addrMEM  : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0)   := (others => '0');
	signal dataMEM  : STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0) := (others => '0');
	
	alias tagV : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) is addrMEM(config.tagIndexH downto config.tagIndexL);

	signal indexI       : INTEGER := 0;
	signal offsetBlockI : INTEGER := 0;
	signal offsetByteI  : INTEGER := 0;

	signal indexV       : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0)       := (others => '0');
	signal offsetBlockV : STD_LOGIC_VECTOR(config.offsetBlockNrOfBits - 1 downto 0) := (others => '0');
	signal offsetByteV  : STD_LOGIC_VECTOR(config.offsetByteNrOfBits - 1 downto 0)  := (others => '0');

	signal hitCounter  		   : INTEGER := 0; -- Current hit counter value from cache entity.
	signal missCounter 		   : INTEGER := 0; -- Current miss counter value from cache entity.
	
	function GET_RANDOM_TAG( rand : in REAL ) return INTEGER is
		variable irand : INTEGER;
		variable max : REAL := REAL(DATA_WIDTH);
		variable t : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) := (others=>'0');
		variable r : INTEGER := 0;
	begin
		t := (others=>'1');
		max := REAL(TO_INTEGER(UNSIGNED(t)));
		irand := INTEGER( max ) + 1;
		while irand>INTEGER(max) loop
			irand := GET_RANDOM( rand, max );
		end loop;
		t := GET_TAG( irand );
		r := TO_INTEGER(UNSIGNED(t));
		return r;
	end;

	function GET_RANDOM_DATA( rand : in REAL ) return STD_LOGIC_VECTOR is 
		variable irand : INTEGER;
		variable max : REAL := REAL(DATA_WIDTH);
		variable d : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
	begin
		irand := GET_RANDOM( rand, max );
		d := GET_DATA( irand );
		return d;
	end;
	
	
	function GET_RANDOM( rand : in REAL; max : in REAL ) return INTEGER is
		variable irand : INTEGER;
	begin
		irand := INTEGER((rand * 100.0-0.5) + 50.0);
		return irand;
	end;
	 	
	function GET_TAG( ARG : in INTEGER ) return STD_LOGIC_VECTOR is
		variable t : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) := (others=>'0');
	begin
		t := STD_LOGIC_VECTOR( TO_UNSIGNED( ARG, config.tagNrOfBits ));
		return t;
	end;
	
	function GET_INDEX( ARG : in INTEGER ) return STD_LOGIC_VECTOR is
		variable index : STD_LOGIC_VECTOR(config.indexNrOfBits-1 downto 0) := (others=>'0');
	begin
		index := STD_LOGIC_VECTOR( TO_UNSIGNED( ARG, config.indexNrOfBits ));
		return index;
	end;
	
	function GET_OFFSET( ARG : in INTEGER ) return STD_LOGIC_VECTOR is
		variable offset : STD_LOGIC_VECTOR(config.offsetNrOfBits-1 downto 0) := (others=>'0');
	begin
		offset := STD_LOGIC_VECTOR( TO_UNSIGNED( ARG, config.offsetNrOfBits ));
		return offset;
	end;
	
	function GET_DATA( ARG : in INTEGER ) return STD_LOGIC_VECTOR is
		variable data : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
	begin
		data := STD_LOGIC_VECTOR( TO_UNSIGNED( ARG, DATA_WIDTH ));
		return data;
	end;
	 
	function GET_MEMORY_ADDRESS( tag : in INTEGER; index : in INTEGER; offset : in INTEGER) return STD_LOGIC_VECTOR is
		variable m : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
		variable t : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) := (others=>'0');
		variable i : STD_LOGIC_VECTOR(config.indexNrOfBits-1 downto 0) := (others=>'0');
		variable o : STD_LOGIC_VECTOR(config.offsetNrOfBits-1 downto 0) := (others=>'0');
	begin
		t := GET_TAG( tag );
		i := GET_INDEX( index );
		o := GET_OFFSET( offset );
		m := t & i & o;
		return m;
	end function;
	
	procedure VALIDATE_SIGNALS(
		L : in INTEGER; I : in INTEGER;
		stallCPU : in STD_LOGIC; expectedStallCPU : in STD_LOGIC;
		missCounter : in INTEGER; expectedMissCounter : in INTEGER;
		hitCounter : in INTEGER; expectedHitCounter : INTEGER ) is
	begin
		if report_mode='1' then
			report "L: " & INTEGER'IMAGE(L) & " I: " & INTEGER'IMAGE(I) severity NOTE;
		end if;
		VALIDATE_SIGNAL("stallCPU", stallCPU, expectedStallCPU);
		VALIDATE_SIGNAL("Misscounter", misscounter, expectedMissCounter);
		VALIDATE_SIGNAL("Hitcounter", hitCounter, expectedHitCounter);
	end;
	
	procedure VALIDATE_SIGNALS( 
		stallCPU : in STD_LOGIC; expectedStallCPU : in STD_LOGIC;
		missCounter : in INTEGER; expectedMissCounter : in INTEGER;
		hitCounter : in INTEGER; expectedHitCounter : INTEGER ) is
	begin
		VALIDATE_SIGNAL("stallCPU", stallCPU, expectedStallCPU);
		VALIDATE_SIGNAL("Misscounter", misscounter, expectedMissCounter);
		VALIDATE_SIGNAL("Hitcounter", hitCounter, expectedHitCounter);
	end;
	
	procedure VALIDATE_SIGNAL(  signalName : in STRING; currentValue : in INTEGER; expectedValue : in INTEGER ) is
	begin 
		if currentValue=expectedValue then
			if report_mode='1' then
				report signalName & " is correctly set to <" & INTEGER'IMAGE(currentValue) & ">." severity NOTE;
			end if;
		else
			report signalName & " is expected to be <"&INTEGER'IMAGE(expectedValue) & "> but is <"&INTEGER'IMAGE(currentValue)&">." severity FAILURE;
		end if; 	
	end;
	 
	procedure VALIDATE_SIGNAL( signalName : in STRING; currentValue : in STD_LOGIC; expectedValue : in STD_LOGIC ) is
	begin
		if currentValue=expectedValue then
			if report_mode='1' then
				report signalName & " is correctly set to <" & STD_LOGIC'IMAGE(currentValue) & ">." severity NOTE;
			end if;
		else
			report signalName & " is expected to be <"&STD_LOGIC'IMAGE(expectedValue) & "> but is <"&STD_LOGIC'IMAGE(currentValue)&">." severity FAILURE;
		end if; 	
	end;
	
	procedure VALIDATE_SIGNAL( signalName : in STRING; currentVector : in STD_LOGIC_VECTOR; expectedVector : STD_LOGIC_VECTOR ) is
		variable currentVectorAsInteger : INTEGER := 0;
		variable expectedVectorAsInteger : INTEGER := 0;
	begin
		if currentVector=expectedVector then
			if report_mode='1' then
				report signalName & " is correctly set." severity NOTE;
			end if;
		else
			currentVectorAsInteger := TO_INTEGER( UNSIGNED( currentVector ));
			expectedVectorAsInteger := TO_INTEGER( UNSIGNED( expectedVector ));
			report signalName & " is expected to be <" & INTEGER'IMAGE(expectedVectorAsInteger) & "> but is <" & INTEGER'IMAGE(currentVectorAsINTEGER) & ">." severity FAILURE;
		end if;
	end;
	
	procedure PRINT_TEST_START( testID : in INTEGER ) is
	begin
		report "Test " & INTEGER'IMAGE( testID ) & " start validation..." severity NOTE;
	end;
	
	procedure PRINT_TEST_END( testID : in INTEGER ) is
	begin
		report "Test " & INTEGER'IMAGE(testID) & " successfully validated." severity NOTE;
		report "-------------------------------------------------------------------" severity NOTE;
	end;
	
	procedure VALIDATE( cycles : in INTEGER; 
		expectedStallCPU_duringLoop : in STD_LOGIC;
		expectedMissCounter_duringLoop : in INTEGER;
		expectedHitCounter_duringLoop : in INTEGER;
		
		expectedStallCPU_afterLoop : in STD_LOGIC;
		expectedMissCounter_afterLoop : in INTEGER;
		expectedHitCounter_afterLoop : in INTEGER;
		
		expectedDataCPU : in STD_LOGIC_VECTOR
	) is
	begin
			for I in 1 to cycles loop
				VALIDATE_SIGNALS(stallCPU, expectedStallCPU_duringLoop, missCounter, expectedMissCounter_duringLoop, hitCounter, expectedHitCounter_duringLoop);
				wait until rising_edge(clk);
			end loop;
			VALIDATE_SIGNALS(stallCPU, expectedStallCPU_afterLoop, missCounter, expectedMissCounter_afterLoop, hitCounter, expectedHitCounter_afterLoop);
			VALIDATE_SIGNAL( "dataCPU", dataCPU, expectedDataCPU );
			  
	end;
	
	
	signal indexMyTest : STD_LOGIC_VECTOR(config.indexNrOfBits-1 downto 0) := (others=>'0');
begin
	
	indexMyTest <= addrCPU(config.indexIndexH downto config.indexIndexL);
	-- ------------------------------------------------------------------------------------------
	-- Create entity cache.
	-- ------------------------------------------------------------------------------------------
	cache : entity work.cache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME,
			FILE_EXTENSION		 => FILE_EXTENSION
		)
		port map(clk         => clk,
			     reset       => reset,
			     hitCounter  => hitCounter,
			     missCounter => missCounter,
			     stallCPU    => stallCPU,
			     rdCPU       => rdCPU,
			     wrCPU       => wrCPU,
			     dataCPU     => dataCPU,
			     addrCPU     => addrCPU,
			     readyMEM    => readyMEM,
			     rdMEM       => rdMEM,
			     wrMEM       => wrMEM,
			     addrMEM     => addrMEM,
			     dataMEM     => dataMEM
		);

	-- ------------------------------------------------------------------------------------------
	-- Create main memory.
	-- ------------------------------------------------------------------------------------------
	mainMemoryController : entity work.mainMemory
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			DATA_WIDTH           => DATA_WIDTH,
			BRAM_ADDR_WIDTH		 => BRAM_ADDR_WIDTH,
			DATA_FILENAME        => MAIN_MEMORY_FILENAME,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk         => clk,
			readyMEM    => readyMEM,
			addrMEM     => addrMEM,
			rdMEM       => rdMEM,
			wrMEM       => wrMEM,
			dataMEM  	=> dataMEM,
			reset       => reset
		);

	-- ------------------------------------------------------------------------------------------
	-- Process generates clock.
	-- ------------------------------------------------------------------------------------------
	clockProcess : process
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end process;

	-- ------------------------------------------------------------------------------------------
	-- Process tests some test cases.
	-- ------------------------------------------------------------------------------------------
	testProcess: process
		variable testCaseIndex : INTEGER := 0;
		variable expected_missCounter, expected_hitCounter : INTEGER := 0;
		variable expected_stallCPU : STD_LOGIC := '0';
		variable tag_integer : INTEGER := 0;
		variable offset_integer : INTEGER := 0;
		variable seed1, seed2        : POSITIVE;
		variable rand                : REAL;
		variable dataCPU2 : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
		variable expectedDataCPU : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
		
		variable activatedTest : STD_LOGIC_VECTOR(1 to 100) := (others=>'0');-- TODO Remove this variable.
	begin
		activatedTest := (others=>'1');
		--activatedTest(3 to 4) := (others=>'0');
		wait for 5 ns;
		
		-- --------------------------------------------------------------------------------------
		-- Reset the cache.
		-- --------------------------------------------------------------------------------------
		dataCPU <= (others=>'Z');
		dataMEM <= (others=>'Z');
		reset 	<= '1';
		wait for 5 ns;
		reset <= '0';
		wait for 4 ns;
		wait until rising_edge(clk);
		
		-- =======================================================================================================================
		-- Test 1 - Reset Cache. Miss counter and Hit counter are zero.
		-- At start the miss counter and hit counter should be zero.
		-- =======================================================================================================================
		testCaseIndex := 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex);
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, 0, hitCounter, 0); 
		PRINT_TEST_END(testCaseIndex);
		end if;

		-- =======================================================================================================================
		-- Test 2 - Reset Cache. Invalid cache blocks.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex);
		addrCPU <= GET_MEMORY_ADDRESS( 0, 0, 0 ); 
		expected_missCounter := missCounter;
		expected_hitCounter := hitCounter;
		expected_stallCPU := '0';
		VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		for L in 0 to ADDRESSWIDTH-1 loop
			-- ---------------------------------------------------------------------------
			-- Read from another cache block line.
			-- ---------------------------------------------------------------------------
			rdCPU <= '1';
			addrCPU <= GET_MEMORY_ADDRESS( 0, L, 0 ); 
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			wait until rising_edge(clk);
			for I in 1 to 22 loop
				rdCPU <= '1';
				wait until rising_edge(clk);
				rdCPU <= '0';
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
		
			-- ---------------------------------------------------------------------------
			-- Check whether miss counter has been incremented.
			-- ---------------------------------------------------------------------------
			expected_missCounter := expected_missCounter + 1;
			expected_stallCPU 	 := '0';
			wait until rising_edge(clk);
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;
		 
		-- =======================================================================================================================
		-- Test 3 - Read Cache. Line is not dirty.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		rdCPU <= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex); 
		for L in 0 to ADDRESSWIDTH-1 loop
			tag_integer := 0;
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, 0 ); 
			rdCPU <= '1';
			expected_hitCounter := hitCounter+1;
			expected_missCounter := missCounter;
			expected_stallCPU := '0';
			wait until rising_edge(clk);
			rdCPU <= '0';
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		for L in 0 to ADDRESSWIDTH-1 loop
			rdCPU <= '0';
			tag_integer := 1;
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			rdCPU <= '1';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, 0 );
			wait until stallCPU='1';
			expected_missCounter := missCounter;
			expected_hitCounter := hitCounter;
			expected_missCounter := expected_missCounter + 1;
			wait until rising_edge(clk);
			rdCPU <= '0';
			wait until rising_edge(clk);
			wait until stallCPU='0';
			expected_stallCPU := '0';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		wait until rising_edge(clk);
		PRINT_TEST_END(testCaseIndex);
		end if;
		 
		 
		-- =======================================================================================================================
		-- Test 4 - Read Cache. Different Offset.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex);
		for L in 0 to ADDRESSWIDTH-1 loop
			for O in 0 to BLOCKSIZE-1 loop
				rdCPU <= '1';
				-- Read from another offset block.
				addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, O ); 
				expected_hitCounter := hitCounter+1;
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				rdCPU <= '0';
				wait until rising_edge(clk);
				wait until rising_edge(clk);
				wait until rising_edge(clk);
				VALIDATE_SIGNALS(stallCPU, '0', missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;
		
		-- =======================================================================================================================
		-- Test 5 - Read Cache. Line is dirty.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex);

		-- Reset the cache.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		expected_stallCPU := '0';
		VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, 0, hitCounter, 0);
		tag_integer := 0;
		offset_integer := 0;
		dataCPU <= (others=>'0');
		
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		-- Read from cache block the first time.
		for L in 0 to ADDRESSWIDTH-1 loop
			wrCPU <= '0';
			rdCPU <= '1';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			rdCPU <= '0';
			for I in 1 to 22 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter+1, hitCounter, expected_hitCounter);
		end loop;
		
		-- Wait some clock cycles.
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		-- Change data in cache blocks
		dataCPU <= (others=>'1');
		for L in 0 to ADDRESSWIDTH-1 loop
			wrCPU <= '1';
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			expected_hitCounter := expected_hitCounter + 1;
			expected_stallCPU := '0';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		-- ---------------------------------------------------------------
		-- Read from dirty cache blocks, where tags are not equal.
		-- ---------------------------------------------------------------
		wrCPU <= '0';
		rdCPU <= '0';
		
		-- Change the tag value.
		if tag_integer/=1 then
			tag_integer := 1;
		else
			tag_integer := 0;
		end if;
		
		-- Wait some default clock cycles.
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		for L in 0 to ADDRESSWIDTH-1 loop
			wrCPU <= '0';
			rdCPU <= '1';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			rdCPU <= '0';
			wrCPU <= '0';
			expected_hitCounter  := hitCounter;
			expected_missCounter := missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
			for I in 1 to 44 loop
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			end loop;
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter+1, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;
		 
		-- =======================================================================================================================
		-- Test 6 - Write Cache - Invalid Cache blocks.
		-- 1. After reset of the cache, all cache block lines are invalid.
		-- 2. Thus, if a cache block line is written for the first time after reset, 
		--    the correspondent cache block line will be read from the main memory first.
		-- 3. Finally, the miss counter is incremented and the correspondent control signal
		--    is activated to stall the CPU.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex); 
		
		-- Reset the cache first.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		reset <= '0';
		
		-- Wait some clock cycles.
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		-- Check the miss counter and hit counter.
		expected_missCounter := 0;
		expected_hitCounter := 0;
		expected_stallCPU := '0';
		VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		
		-- Set the data to be written as well as the tag and offset.
		tag_integer 	:= 0;
		offset_integer 	:= 0;
		dataCPU	 		<= (others=>'1');
		
		-- Loop over all cache block lines.
		for L in 0 to ADDRESSWIDTH-1 loop
			
			wrCPU <= '1';
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter 	:= hitCounter;
			expected_missCounter	:= missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			for I in 1 to 22 loop
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			wait until rising_edge(clk);
			
			expected_stallCPU := '0';
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			wait until rising_edge(clk);
			
			expected_missCounter := expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;
		
		-- =======================================================================================================================
		-- Test 7 - Write Cache. Line is Dirty.
		-- 1. Assume that there are already changed data in the cache block lines.
		-- 2. If new data should be written into cache and the tag values differs,
		--    then the changed data must be first written back from cache to the main memory.
		-- 3. After that, the correspondent cache block line will be read from main memory
		--    to the cache.
		-- 4. Finally, the new data are written into the cache.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex); 
		
		-- Reset the cache.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		expected_missCounter := 0;
		expected_hitCounter  := 0;
		expected_stallCPU := '0';
		VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		
		-- Define tag and offset.
		tag_integer := 0;
		offset_integer := 0;
		
		-- Loop over all cache block lines and write the first time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			tagArrayMEM(L) <= tag_integer;

			-- Create random data word.
			uniform(seed1, seed2, rand);
			dataCPU2 := GET_RANDOM_DATA(rand);
			cacheBlockMEM(L) <= dataCPU2; 
			dataCPU <= dataCPU2;
						
			-- Write 
			wrCPU <= '1';
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			for I in 1 to 22 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		
		
		report "wait for some clock cycles.";
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		-- Loop over all cache block lines and write the second time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			while tag_integer=tagArrayMEM(L) loop
				uniform(seed1, seed2, rand);
				tag_integer := GET_RANDOM_TAG( rand );
			end loop;
			tagArrayMEM(L) <= tag_integer;
		
			-- Create random data word.
			uniform(seed1, seed2, rand);
			dataCPU2 := GET_RANDOM_DATA(rand);
			cacheBlockMEM(L) <= dataCPU2; 
			dataCPU <= dataCPU2;
			wait until rising_edge(clk);
			
			-- Write to cache.
			wrCPU	<= '1';
			rdCPU 	<= '0';
			tagValueTmp <= STD_LOGIC_VECTOR( TO_UNSIGNED( tag_integer, config.tagNrOfBits ));
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			for I in 1 to 45 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;  
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter+1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;
		
		-- =======================================================================================================================
		-- Test 8 - Write Cache. Line is Not Dirty.
		-- 1. Assume that there are valid, clean data in the cache block lines.
		-- 2. If new data should be written into cache and the tag values differs,
		--    then the clean data are not written back from cache to main memory.
		-- 3. Instead of that, the correspondent block are read from main memory into cache.
		-- 4. Finally, the new data are written into the cache.
		-- 5. We expect, that the miss counter is incremented.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex); 
		
		-- Reset the cache.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		expected_missCounter := 0;
		expected_hitCounter  := 0;
		expected_stallCPU := '0';
		VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		
		-- Define tag and offset.
		tag_integer := 0;
		offset_integer := 0;
		
		-- Loop over all cache block lines and write the first time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			tagArrayMEM(L) <= tag_integer;
						
			-- Write 
			wrCPU <= '0';
			rdCPU <= '1';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			rdCPU <= '0';
			expected_hitCounter 	:= hitCounter;
			expected_missCounter 	:= missCounter;
			expected_stallCPU 		:= '1';
			for I in 1 to 22 loop
				wait until rising_edge(clk);
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		
		-- Wait some clock cycles.
		report "wait for some clock cycles.";
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		
		-- Write data with different tag values.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			while tag_integer=tagArrayMEM(L) loop
				uniform(seed1, seed2, rand);
				tag_integer := GET_RANDOM_TAG( rand );
			end loop;
		
			-- Create random data word.
			uniform(seed1, seed2, rand);
			dataCPU2 := GET_RANDOM_DATA(rand);
			cacheBlockMEM(L) <= dataCPU2; 
			dataCPU <= dataCPU2;
			wait until rising_edge(clk);

			-- Write to cache.
			wrCPU			<= '1';
			rdCPU 			<= '0';
			tagValueTmp 	<= STD_LOGIC_VECTOR( TO_UNSIGNED( tag_integer, config.tagNrOfBits ));
			addrCPU 		<= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter 	:= hitCounter;
			expected_missCounter 	:= missCounter;
			expected_stallCPU 		:= '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			for I in 1 to 22 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter+1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;
		
		-- =======================================================================================================================
		-- Test 9 - Write Cache - Hit.
		-- 1. Let's assume that there are already valid (clean or invalid) data in the cache block line.
		-- 2. If we write new data to this cache block/line and the tags are equal, then then the old data will
		--    not be written back to the main memory.
		-- 3. Instead of that, the correspondent cache block line is directly rewritten with the new data word.
		-- 4. We expect, that the hit counter is incremented.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex);
		
		-- Reset the cache.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, 0, hitCounter, 0);
		
		-- Define tag and offset.
		tag_integer := 0;
		offset_integer := 0;
		
		-- Loop over all cache block lines and write the first time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			tagArrayMEM(L) <= tag_integer;

			-- Create random data word.
			uniform(seed1, seed2, rand);
			dataCPU2 := GET_RANDOM_DATA(rand);
			cacheBlockMEM(L) <= dataCPU2; 
			dataCPU <= dataCPU2;
						
			-- Write 
			wrCPU <= '1';
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			--VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			for I in 1 to 22 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		
		-- Wait some clock cycles.
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		-- Loop over all cache block lines and write the second time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Write to the same tag..
			tag_integer := tagArrayMEM(L);

			-- Create random data word.
			uniform(seed1, seed2, rand);
			dataCPU2 := GET_RANDOM_DATA(rand);
			cacheBlockMEM(L) <= dataCPU2; 
			dataCPU <= dataCPU2;
			
			-- Write to cache.
			wrCPU <= '1';
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter+1);
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;

		-- =======================================================================================================================
		-- Test 10 - Write Cache - Check Values.
		-- 1. In this test case we will check whether the new data word has been successfully written into the cache.
		-- 2. Whatever the current status of the cache block/line is, we write new data into cache in the first step.
		-- 3. After we have finished writing the cache, we can read the cache block line again.
		-- 4. We expect, that we read the equal data from the cache, which we have written into the cache before.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		if activatedTest(testCaseIndex)='1' then
		PRINT_TEST_START(testCaseIndex);
		
		-- Reset the cache.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, 0, hitCounter, 0);
		
		-- Define tag and offset.
		tag_integer := 0;
		offset_integer := 0;
		
		
		-- Loop over all cache block lines and write the first time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			tagArrayMEM(L) <= tag_integer;

			-- Create random data word.
			uniform(seed1, seed2, rand);
			dataCPU2 := GET_RANDOM_DATA(rand);
			cacheBlockMEM(L) <= dataCPU2; 
			dataCPU <= dataCPU2;
						
			-- Write 
			wrCPU <= '1';
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			--VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			for I in 1 to 22 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;  
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		
		-- Wait some clock cycles.
		report "wait some clock cycles.";
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		
		-- Loop over all cache block lines and write the second time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Write to the same tag.
			tag_integer := tagArrayMEM(L);
			
			-- Determine the expected data from Cache.
			expectedDataCPU := cacheBlockMEM(L);

			-- Read from cache.
			wrCPU <= '0';
			rdCPU <= '1';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			rdCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter+1);
			VALIDATE_SIGNAL( "dataCPU", dataCPU, expectedDataCPU );
		end loop;
		PRINT_TEST_END(testCaseIndex);
		end if;

		
		
		-- =======================================================================================================================
		-- Test 11 - Write Back - Check Values.
		-- 1. In this test case we will check whether the data word has been successfully written back to main memory.
		-- 2. Assume, there are modified data words in cache block lines.
		-- 3. Because of read operation with different tag values, the modified data word must be written back to main memory.
		-- 4. If we read again the written back data from main memory to cache, the data must be correct.
		-- =======================================================================================================================
		testCaseIndex := testCaseIndex + 1;
		PRINT_TEST_START(testCaseIndex);
		
		-- Reset the cache.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, 0, hitCounter, 0);
		
		-- Define tag and offset.
		tag_integer := 0;
		offset_integer := 0;
		
		report "[test11] Write new data into cache."; -- TODO Remove this line.
		-- Loop over all cache block lines and write the first time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			tagArrayMEM(L) <= tag_integer;

			-- Create random data word.
			uniform(seed1, seed2, rand);
			dataCPU2 := GET_RANDOM_DATA(rand);
			cacheBlockMEM(L) <= dataCPU2; 
			dataCPU <= dataCPU2;
						
			-- Write 
			wrCPU <= '1';
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			wrCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			--VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			for I in 1 to 22 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		
			wait until rising_edge(clk);
			expected_stallCPU := '0';
			expected_missCounter := expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
		end loop;
		report "[test11] Write new data into cache finished."; -- TODO Remove this line.
		
		-- Wait some clock cycles.
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		dataCPU <= (others=>'Z');
		wait until rising_edge(clk);
		
		report "[test11] Read data from main memory into cache."; -- TODO Remove this line.
		-- Read block lines with other tag values.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Create random tag.
			uniform(seed1, seed2, rand);
			tag_integer := GET_RANDOM_TAG( rand );
			while tag_integer=tagArrayMEM(L) loop
				uniform(seed1, seed2, rand);
				tag_integer := GET_RANDOM_TAG( rand );
			end loop;
			
			-- Read from cache.
			wrCPU 	<= '0';
			rdCPU 	<= '1';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			rdCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			for I in 1 to 45 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;
			
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);			
		
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);			
		end loop;
		report "[test11] Read data from main memory into cache finished."; -- TODO Remove this line.
		
		
		report "[test11] Read data from main memory into cache."; -- TODO Remove this line.
		dataCPU <= (others=>'Z');
		-- Loop over all cache block lines and write the second time.
		for L in 0 to ADDRESSWIDTH-1 loop
		
			-- Write to the same tag.
			tag_integer := tagArrayMEM(L);
			
			-- Determine the expected data from Cache.
			expectedDataCPU := cacheBlockMEM(L);

			-- Read from cache.
			wrCPU <= '0';
			rdCPU <= '1';
			addrCPU <= GET_MEMORY_ADDRESS( tag_integer, L, offset_integer );
			wait until rising_edge(clk);
			rdCPU <= '0';
			expected_hitCounter := hitCounter;
			expected_missCounter := missCounter;
			expected_stallCPU := '1';
			VALIDATE_SIGNALS(stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			for I in 1 to 45 loop
				expected_missCounter := missCounter;
				wait until rising_edge(clk);
				expected_stallCPU := '1';
				VALIDATE_SIGNALS(L, I, stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);
			end loop;  
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter + 1;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);	
			 
			wait until rising_edge(clk);
			expected_stallCPU 		:= '0';
			expected_missCounter 	:= expected_missCounter;
			VALIDATE_SIGNALS( stallCPU, expected_stallCPU, missCounter, expected_missCounter, hitCounter, expected_hitCounter);	
			
			-- Compare data words.
			VALIDATE_SIGNAL( "dataCPU", dataCPU, expectedDataCPU );
		end loop;
		report "[test11] Read data from main memory into cache finished."; -- TODO Remove this line.
		PRINT_TEST_END(testCaseIndex);

		report "Validation finished." severity FAILURE;
		wait;
	end process;

	indexV       <= STD_LOGIC_VECTOR(TO_UNSIGNED(indexI, config.indexNrOfBits));
	offsetBlockV <= STD_LOGIC_VECTOR(TO_UNSIGNED(offsetBlockI, config.offsetBlockNrOfBits));
	offsetByteV  <= STD_LOGIC_VECTOR(TO_UNSIGNED(offsetByteI, config.offsetByteNrOfBits));

end tests;
