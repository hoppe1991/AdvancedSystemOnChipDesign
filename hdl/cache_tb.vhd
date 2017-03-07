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
		BRAM_ADDR_WIDTH 	: INTEGER := 10; -- Number of bits defining the BRAM address wide.
		TAG_FILENAME         : STRING  := "../imem/tagCache";
		DATA_FILENAME        : STRING  := "../imem/dataCache";
		MAIN_MEMORY_FILENAME : STRING  := "../imem/mainMemory";
		FILE_EXTENSION       : STRING  := ".imem"
	);
end;

architecture tests of cache_tb is
	
	-- Constant object.
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);

	-- Declaration of procedures.
	procedure VALIDATE_SIGNALS( L : in INTEGER; I : in INTEGER; stallCPU : in STD_LOGIC; expectedStallCPU : in STD_LOGIC; missCounter : in INTEGER; expectedMissCounter : in INTEGER; hitCounter : in INTEGER; expectedHitCounter : INTEGER );
	procedure VALIDATE_SIGNALS( stallCPU : in STD_LOGIC; expectedStallCPU : in STD_LOGIC; missCounter : in INTEGER; expectedMissCounter : in INTEGER;hitCounter : in INTEGER; expectedHitCounter : INTEGER );
	procedure VALIDATE_SIGNAL( signalName : in STRING; currentValue : in INTEGER; expectedValue : in INTEGER );
	procedure VALIDATE_SIGNAL( signalName : in STRING; currentValue : in STD_LOGIC; expectedValue : in STD_LOGIC );
	
	-- Report mode indicates whether all reports will be printed to console.
	signal report_mode : STD_LOGIC := '0';
		
	signal clk, reset, memwrite : STD_LOGIC := '0';

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
	
	signal tagI         : INTEGER := 0;
	signal indexI       : INTEGER := 0;
	signal offsetI      : INTEGER := 0;
	signal offsetBlockI : INTEGER := 0;
	signal offsetByteI  : INTEGER := 0;

	signal tagV         : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0)         := (others => '0');
	signal indexV       : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0)       := (others => '0');
	signal offsetV      : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0)      := (others => '0');
	signal offsetBlockV : STD_LOGIC_VECTOR(config.offsetBlockNrOfBits - 1 downto 0) := (others => '0');
	signal offsetByteV  : STD_LOGIC_VECTOR(config.offsetByteNrOfBits - 1 downto 0)  := (others => '0');

	signal hitCounter  		   : INTEGER := 0; -- Current hit counter value from cache entity.
	signal missCounter 		   : INTEGER := 0; -- Current miss counter value from cache entity.
	signal expectedHitCounter  : INTEGER := 0; -- Expected hit counter value.
	signal expectedMissCounter : INTEGER := 0; -- Expected miss counter value.
	
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
	
	signal myT : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) := (others=>'0');
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
	
	procedure PRINT_HITCOUNTER( hitCounter : in INTEGER; missCounter : in INTEGER ) is
	begin
		if report_mode='1' then
			report "hit counter: " & INTEGER'IMAGE(hitCounter)	
								   & " miss counter: " 
								   & INTEGER'IMAGE(missCounter) severity NOTE;
		end if;
	end;
	
	procedure PRINT_HITCOUNTER( stallCPU : in STD_LOGIC; hitCounter : in INTEGER; missCounter : in INTEGER) is
	begin
		if report_mode='1' then
			report "stallCPU: " & STD_LOGIC'IMAGE(stallCPU) &
				   "hit counter: " & INTEGER'IMAGE(hitCounter) &
				   " miss counter: " & INTEGER'IMAGE(missCounter) severity NOTE;
		end if;
	end;
	
	
	procedure PRINT_START_TEST( testID : in INTEGER ) is
	begin
		report "Test " & INTEGER'IMAGE( testID ) & " start validation..." severity NOTE;
	end;
	
	procedure PRINT_END_TEST( testID : in INTEGER ) is
	begin
		report "Test " & INTEGER'IMAGE(testID) & " successfully validated." severity NOTE;
		report "-------------------------------------------------------------------" severity NOTE;
	end;
	
begin
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
			DATA_FILENAME        => DATA_FILENAME
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
	begin

		-- --------------------------------------------------------------------------------------
		-- Reset the cache.
		-- --------------------------------------------------------------------------------------
		dataMEM <= (others=>'Z');
		reset 	<= '1';
		wait for 5 ns;
		reset <= '0';
		wait for 4 ns;
		wait until rising_edge(clk);
		
		-- --------------------------------------------------------------------------------------
		-- Test 1 - Reset Cache. Miss counter and Hit counter are zero.
		-- At start the miss counter and hit counter should be zero.
		-- --------------------------------------------------------------------------------------
		PRINT_START_TEST(1); 
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, 0, hitCounter, 0); 
		PRINT_END_TEST(1);

		-- --------------------------------------------------------------------------------------
		-- Test 2 - Reset Cache. Invalid cache blocks.
		-- --------------------------------------------------------------------------------------
		PRINT_START_TEST(2); 
		rdCPU <= '1';
		addrCPU <= GET_MEMORY_ADDRESS( 0, 0, 0 ); 
		expectedMissCounter <= missCounter;
		expectedHitCounter <= hitCounter;
		wait until rising_edge(clk);
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
		for L in 0 to ADDRESSWIDTH-1 loop
			-- ---------------------------------------------------------------------------
			-- Read from another cache block line.
			-- ---------------------------------------------------------------------------
			addrCPU <= GET_MEMORY_ADDRESS( 0, L, 0 ); 
			expectedHitCounter <= hitCounter;
			for I in 1 to 8 loop
				expectedMissCounter <= missCounter;
				wait until rising_edge(clk);
				VALIDATE_SIGNALS(L, I, stallCPU, '1', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			    PRINT_HITCOUNTER( hitCounter, missCounter ); 
			end loop;
		
			-- ---------------------------------------------------------------------------
			-- Check whether miss counter has been incremented.
			-- ---------------------------------------------------------------------------
			expectedMissCounter <= expectedMissCounter + 1; 
			wait until rising_edge(clk);
			VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);

		end loop;
		PRINT_END_TEST(2);
		 
		 
		 
		-- --------------------------------------------------------------------------------------
		-- Test 3 - Reset Cache. Line is not dirty.
		-- --------------------------------------------------------------------------------------
		PRINT_START_TEST(3); 
		rdCPU <= '1';
		for L in 0 to ADDRESSWIDTH-1 loop
			tagI <= 0;
			addrCPU <= GET_MEMORY_ADDRESS( tagI, L, 0 ); 
			expectedHitCounter <= hitCounter+1;
			expectedMissCounter <= missCounter;
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
		end loop;
		for L in 0 to ADDRESSWIDTH-1 loop
			rdCPU <= '0';
			tagI <= 1;
			wait until rising_edge(clk);
			myT <= GET_TAG(tagI);
			wait until rising_edge(clk);
			rdCPU <= '1';
			addrCPU <= GET_MEMORY_ADDRESS( tagI, L, 0 );
			wait until rising_edge(clk);
			expectedMissCounter <= missCounter;
			expectedHitCounter <= hitCounter;
			for I in 1 to 8 loop
				expectedMissCounter <= missCounter;
				wait until rising_edge(clk);
				VALIDATE_SIGNALS(L, I, stallCPU, '1', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			end loop;  
			expectedMissCounter <= expectedMissCounter + 1; 
			wait until rising_edge(clk);
			VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
		end loop;
		PRINT_END_TEST(3);
		 
		 
		-- --------------------------------------------------------------------------------------
		-- Test 4 - Read Cache. Different Offset.
		-- --------------------------------------------------------------------------------------
		PRINT_START_TEST(4); 
		for L in 0 to ADDRESSWIDTH-1 loop
			for O in 0 to BLOCKSIZE-1 loop
				-- Read from another offset block.
				addrCPU <= GET_MEMORY_ADDRESS( tagI, L, O ); 
				expectedHitCounter <= hitCounter+1;
				expectedMissCounter <= missCounter;
				wait until rising_edge(clk);
				wait until rising_edge(clk);
				VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			    PRINT_HITCOUNTER( hitCounter, missCounter );
			end loop;
		end loop;
		PRINT_END_TEST(4);
		
		
		-- --------------------------------------------------------------------------------------
		-- Test 6 - Read Cache. Line is dirty.
		-- --------------------------------------------------------------------------------------
		PRINT_START_TEST(6); 
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, 0, hitCounter, 0);
		tagI <= 0;
		offsetI <= 0;
		dataCPU <= (others=>'0');
		for L in 0 to ADDRESSWIDTH-1 loop
			wrCPU <= '1';
			rdCPU <= '0';
			wait until rising_edge(clk);
			wrCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tagI, L, offsetI );
			expectedHitCounter <= hitCounter;
			expectedMissCounter <= missCounter;
			PRINT_HITCOUNTER( missCounter, hitCounter );
			--VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			for I in 1 to 7 loop
				expectedMissCounter <= missCounter;
				wait until rising_edge(clk);
				VALIDATE_SIGNALS(L, I, stallCPU, '1', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			end loop;  
			wait until rising_edge(clk);
			VALIDATE_SIGNALS( stallCPU, '0', missCounter, expectedMissCounter+1, hitCounter, expectedHitCounter);
			PRINT_HITCOUNTER( hitCounter, missCounter );
		end loop;
		PRINT_END_TEST(6);
		
		
		 
		-- --------------------------------------------------------------------------------------
		-- Test 5 - Read Cache. Line is dirty.
		-- --------------------------------------------------------------------------------------
		PRINT_START_TEST(5);

		-- Reset the cache.
		reset <= '1';
		rdCPU <= '0';
		wrCPU <= '0';
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		PRINT_HITCOUNTER( missCounter, hitCounter );
		VALIDATE_SIGNALS(stallCPU, '0', missCounter, 0, hitCounter, 0);
		tagI <= 0;
		offsetI <= 0;
		dataCPU <= (others=>'0');
		
		-- Read from cache block the first time.
		for L in 0 to ADDRESSWIDTH-1 loop
			wrCPU <= '0';
			rdCPU <= '1';
			expectedHitCounter <= hitCounter;
			expectedMissCounter <= missCounter;
			wait until rising_edge(clk);
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tagI, L, offsetI );
			PRINT_HITCOUNTER( missCounter, hitCounter );
			for I in 1 to 8 loop
				expectedMissCounter <= missCounter;
				wait until rising_edge(clk);
				PRINT_HITCOUNTER( stallCPU, hitCounter, missCounter);
				VALIDATE_SIGNALS(L, I, stallCPU, '1', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			end loop;  
			VALIDATE_SIGNALS( stallCPU, '1', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			wait until rising_edge(clk);
			report "****************" severity NOTE;
			PRINT_HITCOUNTER( stallCPU, hitCounter, missCounter);
			VALIDATE_SIGNALS( stallCPU, '0', missCounter, expectedMissCounter+1, hitCounter, expectedHitCounter);
			PRINT_HITCOUNTER( hitCounter, missCounter );
		end loop;
		
		-- Change data in cache blocks.
		dataCPU <= (others=>'1');
		for L in 0 to ADDRESSWIDTH-1 loop
			wrCPU <= '1';
			rdCPU <= '0';
			wait until rising_edge(clk);
			wrCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tagI, L, offsetI );
			expectedHitCounter <= hitCounter;
			expectedMissCounter <= missCounter;
			PRINT_HITCOUNTER( missCounter, hitCounter );
			VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			VALIDATE_SIGNALS(stallCPU, '1', missCounter, expectedMissCounter, hitCounter, expectedHitCounter+1);
			PRINT_HITCOUNTER( hitCounter, missCounter );
		end loop;
		
		-- Read from dirty cache blocks, where tags are not equal.
		tagI <= 1;
		for L in 0 to ADDRESSWIDTH-1 loop
			wrCPU <= '0';
			rdCPU <= '1';
			wait until rising_edge(clk);
			rdCPU <= '0';
			addrCPU <= GET_MEMORY_ADDRESS( tagI, L, offsetI );
			expectedHitCounter <= hitCounter;
			expectedMissCounter <= missCounter;
			PRINT_HITCOUNTER( missCounter, hitCounter );
			VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			for I in 0 to 7 loop
				wait until rising_edge(clk);
				VALIDATE_SIGNALS(stallCPU, '1', missCounter, expectedMissCounter, hitCounter, expectedHitCounter);
			end loop;
			wait until rising_edge(clk);
			VALIDATE_SIGNALS(stallCPU, '0', missCounter, expectedMissCounter+1, hitCounter, expectedHitCounter);
			PRINT_HITCOUNTER( hitCounter, missCounter );
		end loop;
		PRINT_END_TEST(5);
		
		
		
		
		
		report "Validation finished." severity NOTE; 
		wait;
	end process;

	indexV       <= STD_LOGIC_VECTOR(TO_UNSIGNED(indexI, config.indexNrOfBits));
	tagV         <= STD_LOGIC_VECTOR(TO_UNSIGNED(tagI, config.tagNrOfBits));
	offsetBlockV <= STD_LOGIC_VECTOR(TO_UNSIGNED(offsetBlockI, config.offsetBlockNrOfBits));
	offsetByteV  <= STD_LOGIC_VECTOR(TO_UNSIGNED(offsetByteI, config.offsetByteNrOfBits));

end tests;
