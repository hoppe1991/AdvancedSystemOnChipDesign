--------------------------------------------------------------------------------
-- filename : directMappedCache_tb.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Include packages.
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
use work.cache_pkg.all;

-- =============================================================================
-- Test bench to verify the behavior of the direct mapped cache.
-- =============================================================================
entity directMappedCache_tb is
	generic(
		TAG_FILENAME    : string  := "../imem/tagCache";
		DATA_FILENAME   : string  := "../imem/dataCache";
		FILE_EXTENSION  : STRING  := ".txt";
		MEMORY_ADDRESS_WIDTH : integer := 32;
		ADDRESSWIDTH    : integer := 256;
		BLOCKSIZE       : integer := 4;
		DATA_WIDTH       : integer := 32;
		OFFSET          : integer := 8);
end;

-- =============================================================================
-- Definition of architecture of the test bench.
-- =============================================================================
architecture test of directMappedCache_tb is
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(MEMORY_ADDRESS_WIDTH, ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);
	subtype CACHE_BLOCK_LINE_RANGE is NATURAL range config.cacheLineBits-1 downto 0;
	
	-- Signal to reset the cache.
	signal reset : STD_LOGIC := '0';

	-- Clock signal.
	signal clk : STD_LOGIC := '0';

	-- Memory address from CPU.
	signal addrCPU : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := (others => '0');

	-- Data from CPU to cache or from cache to CPU.
	signal dataCPU        : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)               := (others => 'Z');
	
	
	-- Signal identifies whether the cache block is valid or not.
	signal valid          : STD_LOGIC                                              := '0';
	
	-- Signal identifies whether the cache block is dirty or not.
	signal dirty          : STD_LOGIC                                              := '0';
	
	-- Signal identifies whether a cache hit or cache miss occurs. 
	signal hit            : STD_LOGIC                                              := '0';
	
	-- Data signal to main memory.
	signal dataMem        : STD_LOGIC_VECTOR(CACHE_BLOCK_LINE_RANGE) := (others => '0');
	
	
	-- Control signal to read a single word from cache.
	signal rdWord             : STD_LOGIC                                              := '0';
	
	-- Control signal to write a single word from cache.
	signal wrWord             : STD_LOGIC                                              := '0';
	
	-- Control signal to write a complete cache block line from cache.
	signal wrCBLine       : STD_LOGIC                                              := '0';
	
	-- Control signal to read a complete cache block line from cache.
	signal rdCBLine       : STD_LOGIC                                              := '0';
	
	-- Write modus: '1' when writing, '0' when reading.
	signal writeMode      : STD_LOGIC                                              := '0';
	
	-- Control signal identifies whether a new cache block line should be written into cache.
	signal wrNewCBLine		 : STD_LOGIC := '0'; 
	
	-- Control signal to set the valid bits.
	signal setValid       : STD_LOGIC                                              := '0';
	
	-- Control signal to set the dirty bits.
	signal setDirty       : STD_LOGIC                                              := '0';
	
	-- New cache block line to be written into cache.
	signal newCacheBlockLine : STD_LOGIC_VECTOR(CACHE_BLOCK_LINE_RANGE);

	-- Auxiliary value.
	constant breakLine : STRING := "----------------------------------------------------------------------------------------------";
	 
	-- Auxiliary procedure to print a break line.
	procedure REPORT_BREAK_LINE is
	begin
		report breakLine severity NOTE;
	end;

	-- Constant value determines whether to rerun the test process or not.
	constant rerunProcess : STD_LOGIC := '0';

	-- Definition of type BLOCK_LINE as an array of STD_LOGIC_VECTORs.
	TYPE BLOCK_LINE IS ARRAY (BLOCKSIZE - 1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	
	-- Auxiliary function initializes a block line with the given parameters.
	function INIT_BLOCK_LINE(ARG1, ARG2, ARG3, ARG4 : in INTEGER) return BLOCK_LINE;
	 
	-- Auxiliary function initializes a block line with the given parameters.
	function INIT_BLOCK_LINE(ARG1, ARG2, ARG3, ARG4 : in INTEGER) return BLOCK_LINE is
		variable v : BLOCK_LINE;
	begin
		v(3) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG1, DATA_WIDTH));
		v(2) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG2, DATA_WIDTH));
		v(1) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG3, DATA_WIDTH));
		v(0) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG4, DATA_WIDTH));
		return v;
	end;
	
	function GET_RANDOM(rand : in REAL) return INTEGER is
		variable irand : INTEGER;
	begin
		irand := INTEGER((rand * 100.0 - 0.5) + 50.0); -- Make a random integer between 50 and 150.
		return irand;
	end;

	function GET_TAG(ARG : in INTEGER) return STD_LOGIC_VECTOR is
		variable tag : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0) := (others => '0');
	begin
		tag := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG, config.tagNrOfBits));
		return tag;
	end;

	function GET_INDEX(ARG : in INTEGER) return STD_LOGIC_VECTOR is
		variable index : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0) := (others => '0');
	begin
		index := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG, config.indexNrOfBits));
		return index;
	end;

	function GET_OFFSET(ARG : in INTEGER) return STD_LOGIC_VECTOR is
		variable offset : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0) := (others => '0');
	begin
		offset := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG, config.offsetNrOfBits));
		return offset;
	end;

	function GET_DATA(ARG : in INTEGER) return STD_LOGIC_VECTOR is
		variable data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
	begin
		data := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG, DATA_WIDTH));
		return data;
	end;


	signal myDataWord : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
begin

	-- -----------------------------------------------------------------------------
	-- Instantiate device to be tested.
	-- -----------------------------------------------------------------------------
	cache : entity work.directMappedCache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk       => clk,
			reset     => reset,
			dataCPU   => dataCPU,
			addrCPU   => addrCPU,
			dataMem   => dataMem,
			rdWord    => rdWord,
			wrWord    => wrWord,
			wrCBLine  => wrCBLine,
			rdCBLine  => rdCBLine,
			writeMode => writeMode,
			valid     => valid,
			dirty     => dirty,
			setValid  => setValid,
			setDirty  => setDirty,
			hit       => hit,
			newCacheBlockLine => newCacheBlockLine,
			wrNewCBLine => wrNewCBLine
		);

	-- -----------------------------------------------------------------------------
	-- Generate clock with 10 ns period process
	-- -----------------------------------------------------------------------------
	clockProcess : process
	begin
		clk <= '1';
		wait for 5 ns;
		clk <= '0';
		wait for 5 ns;
	end process;

	-- -----------------------------------------------------------------------------
	-- Process checks the functions of the Direct Mapped Cache.
	-- -----------------------------------------------------------------------------
	testProcess : process
		variable tag1, tag2          : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0);
		variable index               : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0);
		variable offset              : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0);
		variable irand               : INTEGER;
		variable seed1, seed2        : POSITIVE;
		variable data1, data2, data3 : INTEGER;
		variable blockLine           : BLOCK_LINE := INIT_BLOCK_LINE(0, 0, 0, 0);
		variable rand                : REAL;
	begin
		dataCPU <= (others => 'Z');
		-- ---------------------------------------------------------------------------------------------------
		-- Reset the Direct Mapped Cache.
		-- ---------------------------------------------------------------------------------------------------
		reset   <= '0';
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		reset <= '1';
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		wait for 5 ns;
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		wait until falling_edge(clk);

		-- ---------------------------------------------------------------------------------------------------
		-- Check whether all dirty bits and valid bits are reset.
		-- ---------------------------------------------------------------------------------------------------
		report "checking valid and dirty bits after reset..." severity NOTE;
		for I in 0 to ADDRESSWIDTH - 1 loop

			-- Set to mode READ.
			rdWord <= '1';
			wrWord <= '0';

			-- Define tag, index and offset.
			tag1    := (others => '0');
			index   := GET_INDEX(I);
			offset  := (others => '0');
			addrCPU <= tag1 & index & offset;

			-- Check the outputs.
			if (valid = '0' and dirty = '0' and hit = '0') then
				report "valid bit and dirty bit in block line with index <" & INTEGER'IMAGE(I) & "> are valid." severity NOTE;
			elsif (valid /= '0') then
				report "valid bit is expected to be <0> but it is actually <" & STD_LOGIC'IMAGE(valid) & ">." severity FAILURE;
			elsif (dirty /= '0') then
				report "dirty bit is expected to be <0> but it is actually <" & STD_LOGIC'IMAGE(dirty) & ">." severity FAILURE;
			elsif (hit /= '0') then
				report "hit is expected to be <0> but it is actually <" & STD_LOGIC'IMAGE(hit) & ">." severity FAILURE;
			end if;

			-- Wait for one cycle.
			wait until rising_edge(clk);
			wait until falling_edge(clk);
		end loop;
		wait for 10 ns;
		wait until rising_edge(clk);
		wait until falling_edge(clk);

		-- ---------------------------------------------------------------------------------------------------
		-- Check writing single data words to cache blocks.
		-- ---------------------------------------------------------------------------------------------------
		report "checking writing single words to one cache block..." severity NOTE;
		for I in 0 to ADDRESSWIDTH - 1 loop

			-- Create random number.
			uniform(seed1, seed2, rand);
			irand := GET_RANDOM(rand);

			-- Define the tag.
			tag1 := GET_TAG(irand);

			-- Change mode to write.
			wrWord <= '1';
			rdWord <= '0';

			-- Define the index.
			index := GET_INDEX(I);

			for J in 0 to BLOCKSIZE - 1 loop

				-- Determine offset.
				offset := GET_OFFSET(J);

				-- Define the address for the CPU.
				addrCPU <= tag1 & index & offset;

				-- Create random number.
				uniform(seed1, seed2, rand);
				irand := GET_RANDOM(rand);

				dataCPU      <= GET_DATA(irand);
				blockLine(J) := GET_DATA(irand);
				myDataWord   <= blockLine(J);

				-- Wait for one cycle.
				wait until rising_edge(clk);
				wait until falling_edge(clk);
				data3 := TO_INTEGER(UNSIGNED(addrCPU));
				report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> write <" & INTEGER'IMAGE(irand) & "> to cache block" severity NOTE;

				-- Wait for one cycle.
				wait until rising_edge(clk); -- TODO Why is this line necessary?
				wait until falling_edge(clk); -- TODO Why is this line necessary? 
			end loop;

			-- Wait.
			wait for 50 ns;

			-- Set the mode to READ.
			wrWord <= '0';
			rdWord <= '1';

			for J in 0 to BLOCKSIZE - 1 loop

				-- TODO It is important to set the bits to 'Z' because of inout type.
				dataCPU <= (others => 'Z');

				-- Determine offset.
				offset := GET_OFFSET(J);

				-- Define the address for the CPU.
				addrCPU <= tag1 & index & offset;

				-- Wait for one cycle.	
				wait until rising_edge(clk); -- TODO Why is this line necessary?
				wait until falling_edge(clk); -- TODO Why is this line necessary?


				data1 := TO_INTEGER(UNSIGNED(blockLine(J)));
				data2 := TO_INTEGER(UNSIGNED(dataCPU));
				data3 := TO_INTEGER(UNSIGNED(addrCPU));

				-- Wait for one cycle.
				wait until rising_edge(clk); -- TODO Why is this line necessary?
				wait until falling_edge(clk); -- TODO Why is this line necessary?

				-- Check the output.
				if (dataCPU = blockLine(J)) then
					report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> read cache block is correct." severity NOTE;
				else
					report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> read cache block is actually <" & INTEGER'IMAGE(data2) & ">, but expected <" & INTEGER'IMAGE(data1) & ">." severity FAILURE;
				end if;
			end loop;
			REPORT_BREAK_LINE;

		end loop;
		report "FINISHED checking writing single words to one cache block..." severity NOTE;

		-- ---------------------------------------------------------------------------------------------------
		-- Check tag.
		-- ---------------------------------------------------------------------------------------------------
		report "START checking tags..." severity NOTE;
		for I in 0 to ADDRESSWIDTH - 1 loop

			-- Create random number.
			uniform(seed1, seed2, rand);
			irand := GET_RANDOM(rand);

			-- Determine tag.
			tag1 := GET_TAG(irand);

			-- Change mode to write.
			wrWord <= '1';
			rdWord <= '0';

			-- Determine index. 
			index := GET_INDEX(I);

			for J in 0 to BLOCKSIZE - 1 loop

				-- Determine offset.
				offset := GET_OFFSET(J);

				-- Determine address for CPU.
				addrCPU <= tag1 & index & offset;

				-- Create random number.
				uniform(seed1, seed2, rand);
				irand := GET_RANDOM(rand);

				dataCPU      <= GET_DATA(irand);
				blockLine(J) := GET_DATA(irand);
				myDataWord   <= blockLine(J);

				-- Wait for one cycle.
				wait until rising_edge(clk);
				wait until falling_edge(clk);

				data3 := TO_INTEGER(UNSIGNED(addrCPU));
				report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> write <" & INTEGER'IMAGE(irand) & "> to cache block" severity NOTE;

				-- Wait for one cycle.
				wait until rising_edge(clk); -- TODO Why is this line necessary?
				wait until falling_edge(clk); -- TODO Why is this line necessary? 
			end loop;
			wait for 50 ns;

			wrWord <= '0';
			rdWord <= '1';

			for J in 0 to BLOCKSIZE - 1 loop

				-- Determine the offset vector.
				offset := GET_OFFSET(J);

				-- Determine the address for CPU.
				addrCPU <= tag1 & index & offset;

				-- Wait for one cycle.
				wait until rising_edge(clk); -- TODO Why is this line necessary?
				wait until falling_edge(clk); -- TODO Why is this line necessary?

				-- Check the output.
				if (valid = '1' and hit = '1') then
					report "valid and hit bits are correct." severity NOTE;
				elsif (valid = '0') then
					report "valid bit is not correct." severity FAILURE;
				elsif (hit = '0') then
					report "hit bit is not correct." severity FAILURE;
				end if;
				wait for 5 ns;
			end loop;

			-- Create random tag.
			uniform(seed1, seed2, rand);
			irand := GET_RANDOM(rand);
			tag2  := GET_TAG(irand);

			for J in 0 to BLOCKSIZE - 1 loop

				-- Determine the offset vector.
				offset := GET_OFFSET(J);

				-- Determine the address for CPU.
				addrCPU <= tag2 & index & offset;

				-- Wait for one cycle.
				wait until rising_edge(clk); -- TODO Why is this line necessary?
				wait until falling_edge(clk); -- TODO Why is this line necessary?

				-- Check the outputs.
				if (tag1 /= tag2 and hit = '0' and valid = '1') then
					report "tags are different, valid and hit bits are correct." severity NOTE;
				elsif (tag1 = tag2 and hit = '1' and valid = '1') then
					report "tags are equal, valid and hit bits are correct." severity NOTE;
				elsif (tag1 /= tag2 and (hit /= '0' or valid /= '1')) then
					report "tags are different, valid and hit bits are not correct." severity NOTE;
				else
					report "tags are equal, valid and hit bits are not correct." severity FAILURE;
				end if;
			end loop;
			REPORT_BREAK_LINE;
		end loop;
		report "FINISHED checking tags..." severity NOTE;

		-- Check whether to rerun the process.
		if rerunProcess = '0' then
			wait;
		end if;

	end process;

end;
