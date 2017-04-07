---------------------------------------------------------------------------------
-- filename: mips_tb.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;
use work.CASTS.all;
use work.global_pkg.all;
use STD.TEXTIO.ALL;
use IEEE.std_logic_textio.all;

entity mips_with_instructionCache_tb is
  generic (DFileName : string := "../dmem/isort_pipe";
           IFileName : string := "../imem/isort_pipe";
           TAG_FILENAME 		: STRING := "../imem/tagCache";
		   DATA_FILENAME		: STRING := "../imem/dataCache";
		   FILE_EXTENSION		: STRING := ".imem"
           );
end;

architecture test of mips_with_instructionCache_tb is
	
	signal writedata, dataadr   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	signal clk, reset			: STD_LOGIC := '0';
	signal memwrite 			: STD_LOGIC := '0';

begin

	-- instantiate device to be tested
	dut: entity work.mips
       	generic map(DFileName => DFileName, IFileName => IFileName, 
       		TAG_FILENAME => TAG_FILENAME, DATA_FILENAME=> DATA_FILENAME, 
       		FILE_EXTENSION => FILE_EXTENSION
       	)
       	port map(clk, reset, writedata, dataadr, memwrite);

	-- Generate clock with 10 ns period
  	process begin
    	clk <= '1';
    	wait for 5 ns; 
    	clk <= '0';
    	wait for 5 ns;
  	end process;

	-- Generate reset for first two clock cycles
  	process is 
  	begin
  		reset <= '1';
		wait until rising_edge(clk);
    	reset <= '0';    
    	wait;
	end process;


end;
