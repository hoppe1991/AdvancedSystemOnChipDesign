--------------------------------------------------------------------------------
-- filename : cacheController.vhd
-- author   : Meyer zum Felde, P�ttjer, Hoppe
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

entity mips_isortPipe3_tb is
  generic (

		DFileName 			: STRING := "../dmem/isort_pipe";
        IFileName 			: STRING := "../imem/isort_pipe";
        TAG_FILENAME 		: STRING := "../imem/tagCache";
		DATA_FILENAME		: STRING := "../imem/dataCache";
		FILE_EXTENSION		: STRING := ".imem"
   );
end;

architecture test of mips_isortPipe3_tb is
	
	-- Width of address vector.
	constant ADDR_WIDTH     : integer  := 11;
    
	-- The integer array contains 10 integer values.
    type integerArray is array (10 downto 0) of INTEGER;
    
    constant expectedIndex : integerArray := ( 10,  9,  8,  7,  6,  5,  4,  3,  2,  1, 0 );
    constant expectedArray : integerArray := ( 60, 50, 40, 30, 30, 25, 20, 10, 10,  5, 0 );

    -- Array of integers.
  	signal writeDataArray: integerArray := (others => 0);
  	
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
	impure function ADD_INTEGER(int : in INTEGER; index : in INTEGER) return integerArray is
		variable a : integerArray;
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
	
	
begin


	-- instantiate device to be tested
  	dut: entity work.mips
  	generic map(DFileName => DFileName, IFileName => IFileName, 
       	TAG_FILENAME => TAG_FILENAME, DATA_FILENAME=> DATA_FILENAME, 
       	FILE_EXTENSION => FILE_EXTENSION
    )
    port map(clk, reset, writedata, dataadr, memwrite);

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
		
		-- ----------------------------------------------------------------------
		-- Writes the given integer array into a txt file.
		-- ----------------------------------------------------------------------
		procedure print_array is		
			variable l : LINE;
    		file outfile         : text;
    		variable f_status: FILE_OPEN_STATUS;
		begin
			file_open(f_status, outfile, "mips_isortPipe3_tb.txt", write_mode);
			for I in writeDataArray'RANGE loop
				write(l, INTEGER'IMAGE(writeDataArray(I)));
				write(l, string'(";"));
			end loop;
			WRITELINE(outfile, l);
			file_close(outfile);
		end;
	begin

		if memwrite_i='1' and memwrite='0' and rising_edge(clk) then
			writeDataArray <= ADD_INTEGER( writedataI, selectedAddrI);
			 
			-- TODO Toggle the following comments to print messages in command line.
--			report "write data: " & INTEGER'IMAGE(writedataI);
--	    	report "address: " & INTEGER'IMAGE(selectedAddrI); 
--	    	print_array;
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