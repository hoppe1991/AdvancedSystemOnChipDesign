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

	component MIPS_COMPONENT is 
		generic ( DFileName, IFileName : STRING );
  		port (clk , reset : in STD_LOGIC;  memwrite : out STD_LOGIC; dataadr, writedata : out STD_LOGIC_VECTOR(31 downto 0));
 	end component MIPS_COMPONENT;
begin

	-- instantiate device to be tested
	dut: MIPS_COMPONENT
       generic map(DFileName => DFileName, IFileName => IFileName)
       port map(clk, reset, memwrite, dataadr, writedata);

	-- Generate clock with 10 ns period
  	process begin
  		clk <= '1';
  		report "HELLO WORLD - INSTRUCTION CACHE";
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

configuration c5 of mips_with_instructionCache_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task5_btb)
	generic map(DFileName => DFileName, IFileName => IFileName)
    port map(clk => clk, reset => reset, memwrite => memwrite, dataadr => dataadr, writedata => writedata);end for;
end for;
end configuration c5;

configuration c4 of mips_with_instructionCache_tb is 
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
end configuration c4;

configuration c3 of mips_with_instructionCache_tb is 
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
end configuration c3;

configuration c2 of mips_with_instructionCache_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task4_instructioncache)
	generic map(DFileName => DFileName, IFileName => IFileName)
    port map(clk => clk, reset => reset, memwrite => memwrite, dataadr => dataadr, writedata => writedata);end for;
end for;
end configuration c2;

configuration c1 of mips_with_instructionCache_tb is 
for test
	for dut: MIPS_COMPONENT
	use entity work.mips(mips_task3_pipelining)
	generic map(DFileName => DFileName, IFileName => IFileName)
    port map(clk => clk, reset => reset, memwrite => memwrite, dataadr => dataadr, writedata => writedata);end for;
end for;
end configuration c1;