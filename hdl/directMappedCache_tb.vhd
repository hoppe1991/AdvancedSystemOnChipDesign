--------------------------------------------------------------------------------
-- filename : directMappedCache_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
use work.cache_pkg.all;

entity directMappedCache_tb is
	generic(
		TAG_FILENAME     : string  := "../imem/tagCache";
		DATA_FILENAME    : string  := "../imem/dataCache";
		FILE_EXTENSION   : STRING  := ".txt";
		MEMADDRESSWIDTH : integer := 32;
		ADDRESSWIDTH    : integer := 256;
		BLOCKSIZE       : integer := 4;
		DATAWIDTH       : integer := 32;
		OFFSET          : integer := 8);
end;

architecture test of directMappedCache_tb is
	signal reset            : STD_LOGIC                                            := '0';
	signal addrCPU          : STD_LOGIC_VECTOR(MEMADDRESSWIDTH - 1 downto 0)       := (others => '0');
	signal dataCPU       : STD_LOGIC_VECTOR(DATAWIDTH - 1 downto 0)             := (others => 'Z');
	signal clk              : STD_LOGIC                                            := '0';
	signal rd               : STD_LOGIC                                            := '0';
	signal wr               : STD_LOGIC                                            := '0';
	signal valid            : STD_LOGIC                                            := '0';
	signal dirty        	: STD_LOGIC                                            := '0';
	signal hit              : STD_LOGIC                                            := '0';
	signal dataMem          : STD_LOGIC_VECTOR(DATAWIDTH * BLOCKSIZE - 1 downto 0) := (others => '0');
	signal wrCBLine : STD_LOGIC                                            := '0';
	signal rdCBLine : STD_LOGIC := '0';
	signal writeMode : STD_LOGIC := '0';
	signal setValid         : STD_LOGIC                                            := '0';
	signal setDirty         : STD_LOGIC                                            := '0';
	signal cacheBlockLine  : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
	

	constant breakLine : STRING := "----------------------------------------------------------------------------------------------";

	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);
	
	constant rerunProcess : STD_LOGIC := '0';

	-- Definition of type BLOCK_LINE as an array of STD_LOGIC_VECTORs.
	TYPE BLOCK_LINE IS ARRAY (BLOCKSIZE - 1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	function INIT_BLOCK_LINE(ARG1, ARG2, ARG3, ARG4 : in INTEGER) return BLOCK_LINE;
	function BLOCK_LINE_TO_STD_LOGIC_VECTOR(ARG : in BLOCK_LINE) return STD_LOGIC_VECTOR;

	-- Returns the given STD_LOGIC_VECTOR as a BLOCK_LINE.
	function STD_LOGIC_VECTOR_TO_BLOCK_LINE(ARG : in STD_LOGIC_VECTOR(config.cacheLineBits - 1 downto 0)) return BLOCK_LINE is
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

	function INIT_BLOCK_LINE(ARG1, ARG2, ARG3, ARG4 : in INTEGER) return BLOCK_LINE is
		variable v : BLOCK_LINE;
	begin
		v(3) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG1, DATA_WIDTH));
		v(2) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG2, DATA_WIDTH));
		v(1) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG3, DATA_WIDTH));
		v(0) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG4, DATA_WIDTH));
		return v;
	end;
	signal myDataWord  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');
	
	function GET_RANDOM( rand : in REAL ) return INTEGER is 
		variable irand        : INTEGER; 
	begin
		irand := INTEGER((rand * 100.0 - 0.5) + 50.0); -- Make a random integer between 50 and 150.
		return irand;
	end;
	
	function GET_TAG( ARG : in INTEGER ) return STD_LOGIC_VECTOR is
		variable tag : STD_LOGIC_VECTOR(config.tagNrOfBits-1 downto 0) := (others=>'0');
	begin
		tag := STD_LOGIC_VECTOR( TO_UNSIGNED( ARG, config.tagNrOfBits ));
		return tag;
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
begin

	-- -----------------------------------------------------------------------------
	-- Instantiate device to be tested.
	-- -----------------------------------------------------------------------------
	cache : entity work.directMappedCache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMADDRESSWIDTH,
			DATA_WIDTH           => DATAWIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME,
			FILE_EXTENSION		 => FILE_EXTENSION
		)
		port map(
			-- Clock and reset signal.
			clk			=> clk,
			reset		=> reset,
			
			dataCPU		=> dataCPU,
			addrCPU		=> addrCPU,
			
			dataMem		=> dataMem,
			
			rdWord		=> rd,
			wrWord		=> wr,
			wrCBLine	=> wrCBLine,
			rdCBLine 	=> rdCBLine,
			writeMode	=> writeMode,
			
			valid       => valid,
			dirty       => dirty, 
			setValid    => setValid,
			setDirty    => setDirty,
			
			hit         => hit
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
	testProcess: process
		variable tag1, tag2   : STD_LOGIC_VECTOR(config.tagNrOfBits -1 downto 0);
		variable index        : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0);
		variable offset       : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0);
		variable irand        : INTEGER; 
		variable seed1, seed2 : POSITIVE;
		variable data1, data2, data3 : INTEGER;
		variable blockLine    : BLOCK_LINE := INIT_BLOCK_LINE(0, 0, 0, 0);
		variable rand : REAL;
	begin
		dataCPU <= (others=>'Z');
		-- ---------------------------------------------------------------------------------------------------
		-- Reset the Direct Mapped Cache.
		-- ---------------------------------------------------------------------------------------------------
		reset <= '0';
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
			rd      <= '1';
			wr      <= '0';
			
			-- Define tag, index and offset.
			tag1     := (others => '0');
			index := GET_INDEX( I ); 
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
			irand := GET_RANDOM( rand );
			
			-- Define the tag.
			tag1 := GET_TAG( irand );

			-- Change mode to write.
			wr    <= '1';
			rd    <= '0';
			
			-- Define the index.
			index := GET_INDEX( I );

			for J in 0 to BLOCKSIZE - 1 loop
			
				-- Determine offset.
				offset  := GET_OFFSET( J );
				
				-- Define the address for the CPU.
				addrCPU <= tag1 & index & offset;
				
				-- Create random number.
				uniform(seed1, seed2, rand);
				irand := GET_RANDOM( rand );
				 
				dataCPU   <= GET_DATA( irand );
				blockLine(J) := GET_DATA( irand );
				myDataWord   <= blockLine(J); 
				
				-- Wait for one cycle.
				wait until rising_edge(clk);
				wait until falling_edge(clk);
				data3        := TO_INTEGER(UNSIGNED(addrCPU));
				report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> write <" & INTEGER'IMAGE(irand) & "> to cache block" severity NOTE;
				
				-- Wait for one cycle.
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary? 
			end loop; 
			
			-- Wait.
			wait for 50 ns;

			-- Set the mode to READ.
			wr <= '0';
			rd <= '1';
			
			
			for J in 0 to BLOCKSIZE - 1 loop
			
				-- TODO It is important to set the bits to 'Z' because of inout type.
				dataCPU <= (others=>'Z');
			
				-- Determine offset.
				offset  := GET_OFFSET( J );
				
				-- Define the address for the CPU.
				addrCPU <= tag1 & index & offset;
				
				-- Wait for one cycle.	
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?

				
				data1 := TO_INTEGER(UNSIGNED(blockLine(J)));
				data2 := TO_INTEGER(UNSIGNED(dataCPU));
				data3 := TO_INTEGER(UNSIGNED(addrCPU));
			
				-- Wait for one cycle.
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?
				  
				-- Check the output.
				if (dataCPU = blockLine(J)) then
					report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> read cache block is correct." severity NOTE;
				else
					report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> read cache block is actually <" & INTEGER'IMAGE(data2) & ">, but expected <" & INTEGER'IMAGE(data1) & ">." severity FAILURE;
				end if; 
			end loop;
			report breakLine severity NOTE;

		end loop;
		report "FINISHED checking writing single words to one cache block..." severity NOTE;


		-- ---------------------------------------------------------------------------------------------------
		-- Check tag.
		-- ---------------------------------------------------------------------------------------------------
		report "START checking tags..." severity NOTE;
		for I in 0 to ADDRESSWIDTH - 1 loop
		
			-- Create random number.
			uniform(seed1, seed2, rand);
			irand := GET_RANDOM( rand );
			
			-- Determine tag.
			tag1 := GET_TAG( irand );
			
			-- Change mode to write.
			wr    <= '1';
			rd    <= '0';
			
			-- Determine index. 
			index := GET_INDEX( I );

			for J in 0 to BLOCKSIZE - 1 loop
				
				-- Determine offset.
				offset  := GET_OFFSET( J );
				
				-- Determine address for CPU.
				addrCPU <= tag1 & index & offset;
			
				-- Create random number.
				uniform(seed1, seed2, rand);
				irand := GET_RANDOM( rand );
				 
				dataCPU   <= GET_DATA( irand );
				blockLine(J) := GET_DATA( irand );
				myDataWord     <= blockLine(J); 
				
				-- Wait for one cycle.
				wait until rising_edge(clk);
				wait until falling_edge(clk);
				
				data3 := TO_INTEGER(UNSIGNED(addrCPU));
				report "addrCPU <" & INTEGER'IMAGE(data3) & "> offset <" & INTEGER'IMAGE(J) & " index <" & INTEGER'IMAGE(I) & "> write <" & INTEGER'IMAGE(irand) & "> to cache block" severity NOTE;
						
				-- Wait for one cycle.
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary? 
			end loop; 
			wait for 50 ns;

			wr <= '0';
			rd <= '1';
			
			for J in 0 to BLOCKSIZE - 1 loop
			
				-- Determine the offset vector.
				offset  := GET_OFFSET( J );
				
				-- Determine the address for CPU.
				addrCPU <= tag1 & index & offset;
				
				-- Wait for one cycle.
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?

				-- Check the output.
				if (valid='1' and hit='1') then
					report "valid and hit bits are correct." severity NOTE;
				elsif ( valid='0' ) then
					report "valid bit is not correct." severity FAILURE;
				elsif ( hit='0' ) then 
					report "hit bit is not correct." severity FAILURE;
				end if;
				wait for 5 ns; 
			end loop;
			
			-- Create random tag.
			uniform(seed1, seed2, rand);
			irand := GET_RANDOM( rand );
			tag2 := GET_TAG( irand );
			
			for J in 0 to BLOCKSIZE - 1 loop
			
				-- Determine the offset vector.
				offset  := GET_OFFSET( J );
				
				-- Determine the address for CPU.
				addrCPU <= tag2 & index & offset;
				
				-- Wait for one cycle.
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?
				
				-- Check the outputs.
				if ( tag1/=tag2 and hit='0' and valid='1' ) then
					report "tags are different, valid and hit bits are correct." severity NOTE;
				elsif ( tag1=tag2 and hit='1' and valid='1' ) then
					report "tags are equal, valid and hit bits are correct." severity NOTE;
				elsif (tag1/=tag2 and (hit/='0' or valid/='1')) then
					report "tags are different, valid and hit bits are not correct." severity NOTE;
				else
					report "tags are equal, valid and hit bits are not correct." severity FAILURE;
				end if;
			end loop;			
			report breakLine severity NOTE;
		end loop;
		report "FINISHED checking tags..." severity NOTE;
		
		-- Check whether to rerun the process.
		if rerunProcess='0' then
			wait;
		end if;

	end process;

end;
