--------------------------------------------------------------------------------
-- filename : cacheController.vhd
-- author   : Meyer zum Felde, P�ttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 30/03/17
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;
use STD.TEXTIO.ALL;
use work.CASTS.all;

entity mips_gcd_tb is
  generic (

		DFileName 			: STRING := "../dmem/isort_pipe";
        IFileName 			: STRING := "../imem/isort_pipe";
        TAG_FILENAME 		: STRING := "../imem/tagCache";
		DATA_FILENAME		: STRING := "../imem/dataCache";
		FILE_EXTENSION		: STRING := ".imem"
   );
end;

architecture test of mips_gcd_tb is
	
	-- Expected ggt(3528, 3780) is 252.
	constant expectedValue : INTEGER := 252;

	-- Width of address vector.
	constant ADDR_WIDTH     : integer  := 11;

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
	selectedAddrI 	<= to_i(selectedAddr);
	
	-- Converts the data word to integer value.
	writedataI 		<= to_i(writedata);
	
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
    	wait until memwrite_i='1' and memwrite='0'; 
    	
    	-- Asserts the ggt value.
    	assert writedataI=expectedValue report "Test case fails: ggt is expected to be " 
    		& INTEGER'IMAGE(expectedValue) & " but is actually " & INTEGER'IMAGE(writedataI) severity FAILURE;
    	
		-- Report whether the test runs successfully.
		report "The test has been successfully passed.";
		
    	wait;
	end process;
 
end;
