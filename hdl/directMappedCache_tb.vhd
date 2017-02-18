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
		TagFileName     : string  := "../imem/tagCache";
		DataFileName    : string  := "../imem/dataCache";
		MEMADDRESSWIDTH : integer := 32;
		ADDRESSWIDTH    : integer := 256;
		BLOCKSIZE       : integer := 4;
		DATAWIDTH       : integer := 32;
		OFFSET          : integer := 8);
end;

architecture test of directMappedCache_tb is
	signal reset            : STD_LOGIC                                            := '0';
	signal addrCPU          : STD_LOGIC_VECTOR(MEMADDRESSWIDTH - 1 downto 0)       := (others => '0');
	signal dataCPU_in       : STD_LOGIC_VECTOR(DATAWIDTH - 1 downto 0)             := (others => '0');
	signal dataCPU_out      : STD_LOGIC_VECTOR(DATAWIDTH - 1 downto 0)             := (others => '0');
	signal clk              : STD_LOGIC                                            := '0';
	signal rd               : STD_LOGIC                                            := '0';
	signal wr               : STD_LOGIC                                            := '0';
	signal valid            : STD_LOGIC                                            := '0';
	signal dirty_out        : STD_LOGIC                                            := '0';
	signal dirty_in         : STD_LOGIC                                            := '0';
	signal hit              : STD_LOGIC                                            := '0';
	signal dataMem          : STD_LOGIC_VECTOR(DATAWIDTH * BLOCKSIZE - 1 downto 0) := (others => '0');
	signal wrCacheBlockLine : STD_LOGIC                                            := '0';
	signal setValid         : STD_LOGIC                                            := '0';
	signal setDirty         : STD_LOGIC                                            := '0';

	signal myMemoryString     : STD_LOGIC_VECTOR(MEMADDRESSWIDTH - 1 downto 0) := (others => '0');
	signal myMemory           : MEMORY_ADDRESS                                 := INIT_MEMORY_ADDRESS;
	signal cacheBlockLine_in  : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);
	signal cacheBlockLine_out : STD_LOGIC_VECTOR((BLOCKSIZE * DATA_WIDTH) - 1 downto 0);

	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);

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

	signal myBlockLine : BLOCK_LINE;
	signal myDataWord  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others => '0');

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
			TAGFILENAME          => TagFileName,
			DATAFILENAME         => DataFileName
		)
		port map(
			clk                => clk,
			reset              => reset,
			dataCPU_in         => dataCPU_in,
			dataCPU_out        => dataCPU_out,
			addrCPU            => addrCPU,
			dataMem            => dataMem,
			rd                 => rd,
			wr                 => wr,
			valid              => valid,
			dirty_in           => dirty_in,
			dirty_out          => dirty_out,
			setValid           => setValid,
			setDirty           => setDirty,
			hit                => hit,
			cacheBlockLine_in  => cacheBlockLine_in,
			cacheBlockLine_out => cacheBlockLine_out,
			wrCacheBlockLine   => wrCacheBlockLine
		);

	-- Generate clock with 10 ns period process
	clockProcess : process
	begin
		clk <= '1';
		wait for 5 ns;
		clk <= '0';
		wait for 5 ns;
	end process;
 
	process
		variable tag          : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0);
		variable index        : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0);
		variable offset       : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0);
		variable seed1, seed2 : POSITIVE;
		variable rand         : REAL;
		variable irand        : INTEGER;
		variable data1, data2, data3 : INTEGER;
		variable blockLine    : BLOCK_LINE := INIT_BLOCK_LINE(0, 0, 0, 0);
	begin

		-- 		
		reset <= '0';
		wait for 5 ns;

		-- Reset the Direct Mapped Cache.
		reset <= '1';
		wait for 5 ns;

		-- Check whether all dirty bits and valid bits are reset.
		report "checking valid and dirty bits..." severity NOTE;
		for I in 0 to ADDRESSWIDTH - 1 loop
			rd      <= '1';
			wr      <= '0';
			tag     := (others => '0');
			index   := STD_LOGIC_VECTOR(TO_UNSIGNED(I, config.indexNrOfBits));
			offset  := (others => '0');
			addrCPU <= tag & index & offset;

			if (valid = '0' and dirty_out = '0' and hit = '0') then
				report "valid bit and dirty bit in block line with index <" & INTEGER'IMAGE(I) & "> are valid." severity NOTE;
			elsif (valid /= '0') then
				report "valid bit is expected to be <0> but it is actually <" & STD_LOGIC'IMAGE(valid) & ">." severity FAILURE;
			elsif (dirty_out /= '0') then
				report "dirty bit is expected to be <0> but it is actually <" & STD_LOGIC'IMAGE(dirty_out) & ">." severity FAILURE;
			elsif (hit /= '0') then
				report "hit is expected to be <0> but it is actually <" & STD_LOGIC'IMAGE(hit) & ">." severity FAILURE;
			end if;
			
			wait until rising_edge(clk);
			wait until falling_edge(clk);
		end loop;
		wait for 10 ns;
		wait until rising_edge(clk);
		wait until falling_edge(clk);

		-- Check writing single data words to cache blocks.
		report "checking writing single words to one cache block..." severity NOTE;
		for I in 0 to ADDRESSWIDTH - 1 loop
			wr    <= '1';
			rd    <= '0';
			tag   := (others => '0');
			index := STD_LOGIC_VECTOR(TO_UNSIGNED(I, config.indexNrOfBits));

			for J in 0 to BLOCKSIZE - 1 loop
				offset  := STD_LOGIC_VECTOR(TO_UNSIGNED(J, config.offsetNrOfBits));
				addrCPU <= tag & index & offset;
				
				uniform(seed1, seed2, rand); -- Make a random real between 0 and 1
				irand := INTEGER((rand * 100.0 - 0.5) + 50.0); -- Make a random integer between 50 and 150.
				wait for irand * 1 ns;  -- Wait for that many ns.
				
				--wait until rising_edge(clk);
				dataCPU_in   <= STD_LOGIC_VECTOR(TO_UNSIGNED(irand, DATA_WIDTH));
				blockLine(J) := STD_LOGIC_VECTOR(TO_UNSIGNED(irand, DATA_WIDTH));
				myDataWord     <= blockLine(J); 
				
				wait until rising_edge(clk);
				wait until falling_edge(clk);
				data3        := TO_INTEGER(UNSIGNED(addrCPU));
				report "offset <" & INTEGER'IMAGE(J) & "> addrCPU <" & INTEGER'IMAGE(data3) & ">  write <" & INTEGER'IMAGE(irand) & "> to cache block with index <" & INTEGER'IMAGE(I) & ">..." severity NOTE;
			
			
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?
			end loop; 
			wait for 50 ns;

			wr <= '0';
			rd <= '1';
			
			for J in 0 to BLOCKSIZE - 1 loop
			
				offset  := STD_LOGIC_VECTOR(TO_UNSIGNED(J, config.offsetNrOfBits));
				addrCPU <= tag & index & offset;
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?

				data1 := TO_INTEGER(UNSIGNED(blockLine(J)));
				data2 := TO_INTEGER(UNSIGNED(dataCPU_out));
				data3 := TO_INTEGER(UNSIGNED(addrCPU));
			
				wait until rising_edge(clk);		-- TODO Why is this line necessary?
				wait until falling_edge(clk);		-- TODO Why is this line necessary?
				 
				if (dataCPU_out = blockLine(J)) then
					report "read cache block with index <" & INTEGER'IMAGE(I) & ">, offset <" & INTEGER'IMAGE(J) & "> is correct." severity NOTE;
				else
					report "addrCPU <" & INTEGER'IMAGE(data3) & "> read cache block with index <" & INTEGER'IMAGE(I) & ">, offset <" & INTEGER'IMAGE(J) & "> is actually <" & INTEGER'IMAGE(data2) & ">, but expected <" & INTEGER'IMAGE(data1) & ">." severity FAILURE;
				end if;
				wait for 5 ns; 
			end loop;
			report "----------------------" severity NOTE;
			report "" severity NOTE;
			report "" severity NOTE;

		end loop;
		report "FINISHED checking writing single words to one cache block..." severity NOTE;

		myMemory.index   <= "00001111";
		wr               <= '0';
		rd               <= '0';
		wrCacheBlockLine <= '0';
		dataCPU_in       <= "11111111111111111111111111111111";
		wait for 5 us;
		wr <= '1';
		rd <= '0';
		wait for 20 us;
		wr <= '0';
		rd <= '1';
		wait for 30 us;
		myMemory.index   <= "11111000";
		wr               <= '1';
		rd               <= '0';
		wrCacheBlockLine <= '0';
		addrCPU(0)       <= '1';
		dataCPU_in       <= "11111111111111111111111111111111";
		wait for 5 us;
		wr <= '0';
		rd <= '1';
		wait for 50 us;
	end process;

end;
