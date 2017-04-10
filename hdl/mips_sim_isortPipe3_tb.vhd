--------------------------------------------------------------------------------
-- filename : mips_sim_isortPipe3_tb.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;
use STD.TEXTIO.ALL;
use work.CASTS.all;
use work.mipssim_pkg.all;


--------------------------------------------------------------------------------
-- Interface of the testbench.
--------------------------------------------------------------------------------
entity mips_sim_isortPipe3_tb is
  generic (

		DFileName 			: STRING := "../dmem/isort_pipe";
        IFileName 			: STRING := "../imem/isort_pipe";
        TAG_FILENAME 		: STRING := "../imem/tagCache";
		DATA_FILENAME		: STRING := "../imem/dataCache";
		FILE_EXTENSION		: STRING := ".imem"
   );
end;

--------------------------------------------------------------------------------
-- Architecture of the testbench.
--------------------------------------------------------------------------------
architecture test of mips_sim_isortPipe3_tb is
	
	-- Filename containing intermediate results.
	constant OUTPUT_FILENAME	: STRING := "mips_isortPipe3.txt";
	
	-- Width of address vector.
	constant ADDR_WIDTH     : integer  := 11;
    
    constant expectedIndex : integerArray10 := ( 10,  9,  8,  7,  6,  5,  4,  3,  2,  1, 0 );
    constant expectedArray : integerArray10 := ( 60, 50, 40, 30, 30, 25, 20, 10, 10,  5, 0 );

    -- Array of integers.
  	signal writeDataArray: integerArray10 := (others => 0);
  	
	-- Clock and reset signal.
	signal clk, reset		: STD_LOGIC := '0';
	
    -- Data word which is written by CPU into data memory.
    signal writedata		: STD_LOGIC_VECTOR(31 downto 0) := (others=>'0');
    
    -- Data word as correspondent integer value.
  	signal writedataI		: INTEGER := 0;
  	
	-- Address of data word which is written by CPU into data memory.
	signal dataadr   		: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	
	-- Control signal indicates whether the CPU writes into data memory.
	signal memwrite			: STD_LOGIC := '0';
	
	-- Register indicates whether the CPU writes into data memory.
	signal memwrite_i 		: STD_LOGIC := '0';
	
	-- Address of data word which is written by CPU into data memory.
    signal selectedAddr 	: STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others=>'0');
    
	-- Address as correspondent integer value.
    signal selectedAddrI	: INTEGER := 0;

	-- -----------------------------------------------------------------------------
	-- Impure function shifts the integers in the array and adds the new integer
	-- at the end of the array.
	-- -----------------------------------------------------------------------------
	impure function ADD_INTEGER(int : in INTEGER; index : in INTEGER) return integerArray10 is
		variable a : integerArray10;
	begin
		a := writeDataArray;
		a(index) := int;
		return a;
	end;
	
	procedure validateValue( currentValue : in INTEGER; expectedValue : in INTEGER ) is
	begin
		assert currentValue=expectedValue report "ERROR expected value is " & INTEGER'IMAGE(expectedValue) 
			& " but current value is " & INTEGER'IMAGE(currentValue) severity FAILURE;
	end;
	
	-- Component of MIPS.
	component MIPS_COMPONENT is 
		generic ( DFileName, IFileName : STRING );
  		port (clk , reset : in STD_LOGIC;  memwrite : out STD_LOGIC; dataadr, writedata : out STD_LOGIC_VECTOR(31 downto 0));
 	end component MIPS_COMPONENT;
	
begin

	-- instantiate device to be tested
	dut: MIPS_COMPONENT
       generic map(DFileName => DFileName, IFileName => IFileName)
       port map(clk, reset, memwrite, dataadr, writedata);

	-- -----------------------------------------------------------------------------
	-- Generate clock with 10 ns period
	-- -----------------------------------------------------------------------------
  	clkProcess: process begin
    	clk <= '1';
    	wait for 5 ns; 
    	clk <= '0';
    	wait for 5 ns;
  	end process;

	-- Register the control signal.
	memwrite_i 		<= memwrite when rising_edge(clk);
	
	-- Select the address word. 
	selectedAddr	<= dataadr(ADDR_WIDTH+1 downto 2) when memwrite_i='1' and memwrite='0';
	
	-- Convert the address to integer value.
	selectedAddrI 	<= to_i(selectedAddr) when memwrite_i='1' and memwrite='0';
	
	-- Converts the data word to integer value.
	writedataI 		<= to_i(writedata) when memwrite_i='1' and memwrite='0';
	

	-- -----------------------------------------------------------------------------
  	-- Updates the integer array, which represents the last 10 data memory access 
  	-- operations.
	-- -----------------------------------------------------------------------------
	updateProcess: process(memwrite_i, writeDataArray, writedataI, clk, memwrite) is
		
	begin

		if memwrite_i='1' and memwrite='0' and rising_edge(clk) then
			writeDataArray <= ADD_INTEGER( writedataI, selectedAddrI);
			 
			-- TODO Toggle the following comments to print messages in command line.
--			report "write data: " & INTEGER'IMAGE(writedataI);
--	    	report "address: " & INTEGER'IMAGE(selectedAddrI); 
			print_array(writeDataArray, OUTPUT_FILENAME);
--	    	report "----------------------------------";
		end if;
	end process;

	-- -----------------------------------------------------------------------------
  	-- Generate reset for first two clock cycles
  	-- and check whether the list has been sorted successfully.
	-- -----------------------------------------------------------------------------
  	resetLogic: process is 
  	begin
  		
  		-- Reset the CPU.
  		reset <= '1';
		wait until rising_edge(clk);
    	reset <= '0';  
    	
    	-- Wait enough time.
		wait for 35 us;
		
		-- Asserts the last 10 operations. We assume, that the assembler program
		-- 'isort_pipe3' sorts the given 10 integer values.
		for I in 0 to 9 loop
			validateValue( writeDataArray(expectedIndex(I)), expectedArray(expectedIndex(I)) );
		end loop;

		-- Report whether the test runs successfully.
		report "The test has been successfully passed.";
		
		  
    	wait;
	end process;
 
end;

configuration cisort5 of mips_sim_fac_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task5_btb)
	generic map(DFileName => DFileName, IFileName => IFileName)
    port map(clk => clk, reset => reset, memwrite => memwrite, dataadr => dataadr, writedata => writedata);end for;
end for;
end configuration cisort5;

configuration cisort4 of mips_sim_fac_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task5_bht)
		generic map(
			DFileName      => DFileName,
			IFileName      => IFileName,
			TAG_FILENAME   => TAG_FILENAME,
			DATA_FILENAME  => DATA_FILENAME,
			FILE_EXTENSION => FILE_EXTENSION
		)
		port map(
			clk       => clk,
			reset     => reset,
			writedata => writedata,
			dataadr   => dataadr,
			memwrite  => memwrite
		);
end for;
end for;
end configuration cisort4;

configuration cisort3 of mips_sim_fac_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task5_staticbranchprediction)
		generic map(
			DFileName      => DFileName,
			IFileName      => IFileName,
			TAG_FILENAME   => TAG_FILENAME,
			DATA_FILENAME  => DATA_FILENAME,
			FILE_EXTENSION => FILE_EXTENSION
		)
		port map(
			clk       => clk,
			reset     => reset,
			writedata => writedata,
			dataadr   => dataadr,
			memwrite  => memwrite
		);
end for;
end for;
end configuration cisort3;

configuration cisort2 of mips_sim_fac_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task4_instructioncache)
	generic map(DFileName => DFileName, IFileName => IFileName)
    port map(clk => clk, reset => reset, memwrite => memwrite, dataadr => dataadr, writedata => writedata);end for;
end for;
end configuration cisort2;

configuration cisort1 of mips_sim_fac_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task3_pipelining)
	generic map(DFileName => DFileName, IFileName => IFileName)
    port map(clk => clk, reset => reset, memwrite => memwrite, dataadr => dataadr, writedata => writedata);end for;
end for;
end configuration cisort1;