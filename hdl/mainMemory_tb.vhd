--------------------------------------------------------------------------------
-- filename : mainMemoryController_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 10/02/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity mainMemory_tb is
	generic(

		-- Width of bit string containing the memory address. 
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;

		-- Number of words that a cache block contains.
		BLOCKSIZE            : integer := 4;

		-- Width of bit string containing a data/instruction word.
		DATA_WIDTH           : INTEGER := 32;

		-- File extension regarding BRAM.
		FILE_EXTENSION       : STRING  := ".imem";
		
		-- Width of BRAM address (10 <=> Compare code in file mips.vhd).
		BRAM_ADDR_WIDTH 	: INTEGER := 10;

		-- Filename regarding regarding BRAM.
		DATA_FILENAME        : STRING  := "../imem/mainMemory"
	);
end;

architecture mainMemory_testbench of mainMemory_tb is
	constant blockLineBits : INTEGER                                               := BLOCKSIZE * DATA_WIDTH;
	signal clk             : STD_LOGIC                                             := '0';
	signal readyMEM        : STD_LOGIC                                             := '0';
	signal rdMEM           : STD_LOGIC                                             := '0';
	signal wrMEM           : STD_LOGIC                                             := '0';
	signal addrMEM         : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0)   := (others => '0');
	signal dataMEM         : STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0) := (others => '0');
	signal reset           : STD_LOGIC                                             := '0';

	-- Definition of type BLOCK_LINE as an array of STD_LOGIC_VECTORs.
	TYPE BLOCK_LINE IS ARRAY (BLOCKSIZE - 1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	function INIT_BLOCK_LINE(ARG1, ARG2, ARG3, ARG4 : in INTEGER) return BLOCK_LINE;
	function BLOCK_LINE_TO_STD_LOGIC_VECTOR(ARG : in BLOCK_LINE) return STD_LOGIC_VECTOR;

	constant data_in_A_blockLine : BLOCK_LINE := INIT_BLOCK_LINE(150, 250, 350, 450);
	constant data_in_B_blockLine : BLOCK_LINE := INIT_BLOCK_LINE(105, 205, 305, 405);
	constant data_in_C_blockLine : BLOCK_LINE := INIT_BLOCK_LINE(125, 225, 325, 425);
	constant data_in_D_blockLine : BLOCK_LINE := INIT_BLOCK_LINE(28, 38, 98, 118);

	constant data_in_A_stdVec : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := BLOCK_LINE_TO_STD_LOGIC_VECTOR(data_in_A_blockLine);
	constant data_in_B_stdVec : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := BLOCK_LINE_TO_STD_LOGIC_VECTOR(data_in_B_blockLine);
	constant data_in_C_stdVec : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := BLOCK_LINE_TO_STD_LOGIC_VECTOR(data_in_C_blockLine);
	constant data_in_D_stdVec : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := BLOCK_LINE_TO_STD_LOGIC_VECTOR(data_in_D_blockLine);

	signal signal_data_in_A : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := data_in_A_stdVec;
	signal signal_data_in_B : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := data_in_B_stdVec;
	signal signal_data_in_C : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := data_in_C_stdVec;
	signal signal_data_in_D : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0) := data_in_D_stdVec;

	constant addr_X : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(0, MEMORY_ADDRESS_WIDTH));
	constant addr_Y : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(30, MEMORY_ADDRESS_WIDTH));
	constant addr_Z : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(60, MEMORY_ADDRESS_WIDTH));

	-- Returns the given STD_LOGIC_VECTOR as a BLOCK_LINE.
	function STD_LOGIC_VECTOR_TO_BLOCK_LINE(ARG : in STD_LOGIC_VECTOR(blockLineBits - 1 downto 0)) return BLOCK_LINE is
		variable v          : BLOCK_LINE;
		variable startIndex : INTEGER;
		variable endIndex   : INTEGER;
	begin
		for I in 0 to BLOCKSIZE - 1 loop
			startIndex := blockLineBits - 1 - I * DATA_WIDTH;
			endIndex   := blockLineBits - (I + 1) * DATA_WIDTH;
			v(I)       := ARG(startIndex downto endIndex);
		end loop;
		return v;
	end;

	-- Returns the given BLOCK_LINE as a STD_LOGIC_VECTOR. 
	function BLOCK_LINE_TO_STD_LOGIC_VECTOR(ARG : in BLOCK_LINE) return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR(blockLineBits - 1 downto 0);
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

	function PRINT_VECTOR(ARG : in STD_LOGIC_VECTOR(blockLineBits - 1 downto 0)) return STRING is
		variable ss : STRING(1 to 3)                 := "000";
		variable s  : STRING(0 to blockLineBits - 1) := (others => '1');
	begin
		for i in blockLineBits - 1 downto 0 loop
			ss   := STD_LOGIC'IMAGE(ARG(i));
			s(i) := ss(2);
		end loop;
		return s;
	end;

begin
	mainMemory : entity work.mainMemory
		generic map(MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			        BLOCKSIZE            => BLOCKSIZE,
			        DATA_WIDTH           => DATA_WIDTH,
			        FILE_EXTENSION       => FILE_EXTENSION,
			        BRAM_ADDR_WIDTH 	 => BRAM_ADDR_WIDTH,
			        DATA_FILENAME        => DATA_FILENAME
		)
		port map(
			clk => clk, 
			readyMEM => readyMEM,
			rdMEM => rdMEM, 
			wrMEM => wrMEM, 
			addrMEM => addrMEM, 
			dataMEM => dataMEM,
			reset => reset
		);

	-- Generate clock with 10 ns period
	clockProcess : process
	begin
		clk <= '1';
		wait for 1 ns;
		clk <= '0';
		wait for 1 ns;
	end process;

	process
	begin
		wait for 10 ns;
		wrMEM <= '1';
		rdMEM <= '0';
		wait until readyMEM = '1';
		-- ---------------------------------------------------------------------------
		wrMEM      <= '1';
		rdMEM      <= '0';
		addrMEM    <= addr_X;
		dataMEM <= data_in_A_stdVec;
		wait until readyMEM = '1';
		-- ---------------------------------------------------------------------------
		wrMEM   <= '0';
		rdMEM   <= '1';
		addrMEM <= addr_X;
		wait until readyMEM = '1';
		report "checking test case 1..." severity NOTE;
		if (readyMEM = '1' and dataMEM = data_in_A_stdVec) then
			report "checking test case 1...NO ERROR" severity NOTE;
		else
			report "expected value: <" & PRINT_VECTOR(data_in_A_stdVec) & ">" severity NOTE;
			report "current value : <" & PRINT_VECTOR(dataMEM) & ">" severity NOTE;
			report "checking test case 1...ERROR" severity FAILURE;
		end if;
		-- ---------------------------------------------------------------------------
		wrMEM      <= '1';
		rdMEM      <= '0';
		addrMEM    <= addr_Y;
		dataMEM <= data_in_B_stdVec;
		wait until readyMEM = '1';
		-- ---------------------------------------------------------------------------

		wrMEM      <= '1';
		rdMEM      <= '0';
		addrMEM    <= addr_Z;
		dataMEM <= data_in_C_stdVec;
		wait until readyMEM = '1';
		-- ---------------------------------------------------------------------------
		wrMEM      <= '1';
		rdMEM      <= '0';
		addrMEM    <= addr_X;
		dataMEM <= data_in_D_stdVec;
		wait until readyMEM = '1';
		-- ---------------------------------------------------------------------------
		dataMEM <= (others=>'Z'); -- TODO Why is this important?
		wrMEM   <= '0';
		rdMEM   <= '1';
		addrMEM <= addr_X;
		wait until readyMEM = '1';
		report "checking test case 2..." severity NOTE;
		if (readyMEM = '1' and dataMEM = data_in_D_stdVec) then
			report "checking test case 2...NO ERROR" severity NOTE;
		else
			report "expected value: <" & PRINT_VECTOR(data_in_D_stdVec) & ">" severity NOTE;
			report "current value : <" & PRINT_VECTOR(dataMEM) & ">" severity NOTE;
			report "checking test case 2...ERROR" severity FAILURE;
		end if;
		-- ---------------------------------------------------------------------------
		wrMEM   <= '0';
		rdMEM   <= '1';
		addrMEM <= addr_Y;
		wait until readyMEM = '1';
		report "checking test case 3..." severity NOTE;
		if (readyMEM = '1' and dataMEM = data_in_B_stdVec) then
			report "checking test case 3...NO ERROR" severity NOTE;
		else
			report "expected value: <" & PRINT_VECTOR(data_in_B_stdVec) & ">" severity NOTE;
			report "current value : <" & PRINT_VECTOR(dataMEM) & ">" severity NOTE;
			report "checking test case 3...ERROR" severity FAILURE;
		end if;
		-- ---------------------------------------------------------------------------
		wrMEM   <= '0';
		rdMEM   <= '1';
		addrMEM <= addr_Z;
		wait until readyMEM = '1';
		report "checking test case 4..." severity NOTE;
		if (readyMEM = '1' and dataMEM = data_in_C_stdVec) then
			report "checking test case 4...NO ERROR" severity NOTE;
		else
			report "expected value: <" & PRINT_VECTOR(data_in_C_stdVec) & ">" severity NOTE;
			report "current value : <" & PRINT_VECTOR(dataMEM) & ">" severity NOTE;
			report "checking test case 4...ERROR" severity FAILURE;
		end if;
	-- ---------------------------------------------------------------------------
	wait;
	end process;

end mainMemory_testbench;