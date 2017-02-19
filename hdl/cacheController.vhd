--------------------------------------------------------------------------------
-- filename : cacheController.vhd
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

entity cacheController is
	generic(
		MEMORY_ADDRESS_WIDTH : INTEGER := 32; -- Memory address is 32-bit wide.
		DATA_WIDTH           : INTEGER := 32; -- Length of instruction/data words.
		BLOCKSIZE            : INTEGER := 4; -- Number of words that a block contains.
		ADDRESSWIDTH         : INTEGER := 256; -- Number of cache blocks.
		OFFSET               : INTEGER := 8 -- Number of bits that can be selected in the cache.
	);

	port(
		hitCounter  : out   INTEGER;
		missCounter : out   INTEGER;
		clk         : in    STD_LOGIC;
		reset       : in    STD_LOGIC;
		stallCPU    : out   STD_LOGIC;
		rdCPU       : in    STD_LOGIC;
		wrCPU       : in    STD_LOGIC;
		addrCPU     : in    STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataCPU_in  : in    STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
		dataCPU_out : out   STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
		readyMEM    : in    STD_LOGIC;
		rdMEM       : out   STD_LOGIC;
		wrMEM       : out   STD_LOGIC;
		addrMEM     : out   STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		dataMEM     : inout STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0)
	);

end;

architecture synth of cacheController is

	-- Constant object.
	constant config : CONFIG_BITS_WIDTH := GET_CONFIG_BITS_WIDTH(ADDRESSWIDTH, BLOCKSIZE, DATA_WIDTH, OFFSET);
	constant cacheBlockLineBits : INTEGER := config.cacheLineBits;

	-- Definition of type BLOCK_LINE as an array of STD_LOGIC_VECTORs.
	TYPE BLOCK_LINE IS ARRAY (BLOCKSIZE - 1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

	function INIT_BLOCK_LINE(ARG1, ARG2, ARG3, ARG4 : in INTEGER) return BLOCK_LINE;
	function BLOCK_LINE_TO_STD_LOGIC_VECTOR(ARG : in BLOCK_LINE) return STD_LOGIC_VECTOR;
	function STD_LOGIC_VECTOR_TO_BLOCK_LINE(ARG : in STD_LOGIC_VECTOR(cacheBlockLineBits-1 downto 0)) return BLOCK_LINE;

	-- Block line from/to cache.
	signal blockLineCache : BLOCK_LINE := INIT_BLOCK_LINE(0, 0, 0, 0);
	
	-- Block line from/to main memory.
	signal blockLineMEM   : BLOCK_LINE := INIT_BLOCK_LINE(0, 0, 0, 0);

	-- Declaration of states.
	type statetype is (
		IDLE,
		CHECK1,
		WRITE_BACK1,
		WRITE,
		CHECK2,
		WRITE_BACK2,
		READ
	);

	type MEMORY_ADDRESS is record
		tag    : STD_LOGIC_VECTOR(config.tagNrOfBits - 1 downto 0);
		index  : STD_LOGIC_VECTOR(config.indexNrOfBits - 1 downto 0);
		offset : STD_LOGIC_VECTOR(config.offsetNrOfBits - 1 downto 0);
		indexAsInteger : INTEGER;
		offsetAsInteger : INTEGER;
	end record;

	function TO_MEMORY_ADDRESS(ARG : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0)) return MEMORY_ADDRESS;
		
	signal addrCPUZero : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	signal adddressCPU : MEMORY_ADDRESS := TO_MEMORY_ADDRESS(addrCPUZero);
	
	-- Current state of FSM.
	signal state     : statetype := IDLE;
	
	-- Next state of FSM.
	signal nextstate : statetype := IDLE;
 
 	-- Signal indicates whether to read from Direct Mapped Cache.
	signal rd : STD_LOGIC := '0';
	
	-- Signal indicates whether to write to Direct Mapped Cache.
	signal wr : STD_LOGIC := '0';
	
	-- Signal indicates whether to write cache block line to Direct Mapped Cache.
	signal wrCacheBlockLine : STD_LOGIC := '0';
	
	-- Valid bit from Direct Mapped Cache.
	signal valid : STD_LOGIC := '0';

	-- Indicates whether to reset the valid bit of Direct Mapped Cache.
	signal setValid : STD_LOGIC := '0';
	
	-- Indicates whether to set the dirty bit of Direct Mapped Cache.
	signal setDirty : STD_LOGIC := '0';

	-- Hit counter.
	signal rHitCounter  : INTEGER := 0;
	
	-- Miss counter.
	signal rMissCounter : INTEGER := 0;

	-- New value of the dirty bit.
	signal dirty_in : STD_LOGIC := '0';
	
	-- Current value of the dirty bit.
	signal dirty_out : STD_LOGIC := '0';
	
	signal directMappedCache_data_out : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others => '0');

	signal cacheBlockLine_in  : STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0) := (others => '0');
	signal cacheBlockLine_out : STD_LOGIC_VECTOR(DATA_WIDTH * BLOCKSIZE - 1 downto 0) := (others => '0');

	-- Auxiliary signals.
	signal lineIsInvalid  : STD_LOGIC := '0';
	signal lineIsNotDirty : STD_LOGIC := '0';
	signal lineIsDirty    : STD_LOGIC := '0';
	signal isDirty        : STD_LOGIC := '0';
	signal hit            : STD_LOGIC := '0';
	
	function CREATE_NEW_BLOCK_LINE( blockLine : in BLOCK_LINE;
				   data : in STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0); 
				   offset : in STD_LOGIC_VECTOR(config.offsetNrOfBits-1 downto 0)
	) return BLOCK_LINE is
		variable b : BLOCK_LINE;
	begin
		for I in 0 to BLOCKSIZE-1 loop
			if (I = TO_INTEGER(UNSIGNED(offset))) then
				b(I) := data;
			else
				b(I) := blockLine(I);
			end if;
		end loop;
		return b;
	end;
	
	function CREATE_NEW_BLOCK_LINE( blockLine : in STD_LOGIC_VECTOR(cacheBlockLineBits-1 downto 0);
		data : in STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0);
		offset : in STD_LOGIC_VECTOR(config.offsetNrOfBits-1 downto 0)
	) return BLOCK_LINE is
		variable b : BLOCK_LINE;
		variable t : BLOCK_LINE;
	begin
		t := STD_LOGIC_VECTOR_TO_BLOCK_LINE( blockLine );
		b := CREATE_NEW_BLOCK_LINE( t, data, offset );
		return b;
	end;

	function INIT_BLOCK_LINE(ARG1, ARG2, ARG3, ARG4 : in INTEGER) return BLOCK_LINE is
		variable b : BLOCK_LINE;
	begin
		b(0) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG1, DATAWIDTH));
		b(1) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG2, DATAWIDTH));
		b(3) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG3, DATAWIDTH));
		b(4) := STD_LOGIC_VECTOR(TO_UNSIGNED(ARG4, DATAWIDTH));
		return b;
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

	function TO_MEMORY_ADDRESS(
		 
		ARG : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0)
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
	
begin
	
	-- State register.
	state <= IDLE when reset = '1' else nextstate when rising_edge(clk);
	
 
	--------------------------------------------
	-- TransitionLogic:
	-- Transition logic of FSM.
	--------------------------------------------
	TransitionLogic : process( state, wrCPU, rdCPU, hit, isDirty, readyMEM, valid)
	begin
		case state is
			when IDLE =>
				if wrCPU = '1' and rdCPU = '0' then
					nextstate <= CHECK1;
				elsif rdCPU = '1' and wrCPU = '0' then
					nextstate <= CHECK2;
				end if;

			when CHECK1 =>
				if hit='1' and valid = '1' then
					nextstate <= IDLE;
				elsif valid = '0' then
					nextstate <= WRITE;
				elsif hit='0' and valid = '1' and isDirty = '0' then
					nextstate <= WRITE;
				elsif hit='0' and valid = '1' and isDirty = '1' then
					nextstate <= WRITE_BACK1;
				end if;
			when CHECK2 =>
				if hit='1' and valid = '1' then
					nextstate <= IDLE;
				elsif valid = '0' then
					nextstate <= READ;
				elsif hit='0' and valid = '1' and isDirty = '0' then
					nextstate <= READ;
				elsif hit='0' and valid = '1' and isDirty = '1' then
					nextstate <= WRITE_BACK2;
				end if;

			when WRITE =>
				if readyMEM = '1' then
					nextstate <= IDLE;
				else
					nextstate <= WRITE;
				end if;

			when WRITE_BACK1 =>
				if readyMEM = '1' then
					nextstate <= WRITE;
				else
					nextstate <= WRITE_BACK1;
				end if;

			when READ =>
				if readyMEM = '1' then
					nextstate <= IDLE;
				else
					nextstate <= READ;
				end if;

			when WRITE_BACK2 =>
				if readyMEM = '1' then
					nextstate <= READ;
				else
					nextstate <= WRITE_BACK2;
				end if;

			when others => nextstate <= IDLE;
		end case;
	end process;
	
	
	-- ------------------------------------------------------------------------------------
	-- Handling of memory address.
	-- ------------------------------------------------------------------------------------
	adddressCPU <= TO_MEMORY_ADDRESS( addrCPU );
	addrMEM 	<= addrCPU;

	-- ------------------------------------------------------------------------------------
	-- Increment or reset hit counter and miss counter.
	-- ------------------------------------------------------------------------------------
	rHitCounter  <= 0 when reset = '1' and rising_edge(clk) else 
					rHitCounter + 1 when state = CHECK1 and hit='1' and rising_edge(clk) else 
					rHitCounter + 1 when state = CHECK2 and hit='1' and rising_edge(clk);
	rMissCounter <= 0 when reset = '1' and rising_edge(clk) else 
					rMissCounter + 1 when state = CHECK1 and hit='0' and rising_edge(clk) else 
					rMissCounter + 1 when state = CHECK2 and hit='0' and rising_edge(clk);
	-- Export the miss counter and hit counter.
	missCounter <= rMissCounter;
	hitCounter  <= rHitCounter;


	-- ------------------------------------------------------------------------------------
	-- Set the auxiliary signals.
	-- ------------------------------------------------------------------------------------
	lineIsInvalid  <= '1' when hit='0' and valid = '0' else '0';
	lineIsNotDirty <= '1' when hit='0' and valid = '1' and isDirty = '0' else '0';
	lineIsDirty    <= '1' when hit='0' and valid = '1' and isDirty = '1' else '0';
	isDirty <= dirty_out;	
	rd               <= '1' when (state = IDLE and wrCPU = '1');
	wr               <= '0' when (state = IDLE and wrCPU = '1');
	wrCacheBlockLine <= '0' when (state=IDLE) else 
						'1' when (state=CHECK1 and hit='1') else
						'1' when (state=WRITE and readyMEM='1');


	-- ------------------------------------------------------------------------------------
	-- Determine whether to stall the CPU.
	-- ------------------------------------------------------------------------------------
	stallCPU <= '1' when (valid = '0') else '1' when (hit='0' and valid = '1' and isDirty = '0') else '1' when (hit='0' and valid = '1' and isDirty = '1') else '0' when (hit='1' and valid = '1');


	-- ------------------------------------------------------------------------------------
	-- Determine whether to read or to write from the Main Memory.
	-- ------------------------------------------------------------------------------------
	rdMEM <= '1' when (state = CHECK1 and valid = '0') else 
			 '1' when (state = CHECK1 and hit='0' and valid = '1' and isDirty = '0') else 
			 '1' when (state = WRITE_BACK1 and readyMEM = '1') else '0';
	wrMEM <= '1' when (state = CHECK1 and hit='0' and valid = '1' and isDirty = '1') else 
			 '1' when (state=CHECK2 and lineIsDirty='1') else
			 '0';

	setValid <= '1' when (state = WRITE and readyMEM = '1') else '1' when (state = CHECK1 and hit='1' and valid = '1') else '1' when (state = READ and readyMEM = '1') else '0';

	setDirty <= '1' when (state = CHECK1 and hit='1' and valid = '1') else '1' when (state = WRITE and readyMEM = '1') else '0';

	-- Data word to MEM.
	blockLineCache <= CREATE_NEW_BLOCK_LINE(cacheBlockLine_out, dataCPU_in, adddressCPU.offset);
	cacheBlockLine_in <= BLOCK_LINE_TO_STD_LOGIC_VECTOR( blockLineCache ) when (state=CHECK1 and hit='1');
 
	-- Determine the read block line.
	blockLineCache    <= STD_LOGIC_VECTOR_TO_BLOCK_LINE(cacheBlockLine_out);
	dataMEM           <= cacheBlockLine_out when (state = CHECK1 and lineIsDirty = '1');
	blockLineMEM      <= STD_LOGIC_VECTOR_TO_BLOCK_LINE(dataMEM);
	cacheBlockLine_in <= dataMEM;

	-- Data CPU output.
	dataCPU_out <= directMappedCache_data_out when (hit='1' and state = CHECK2);
end synth;
