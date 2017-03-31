library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.log2;
use IEEE.math_real.ceil;
use work.mips_pkg.all;
use work.casts.all;

entity BHT is
  generic (
  	
  		BHT_ENTRIES 	: INTEGER := 32;
  		EDGE       		: EDGETYPE:= FALLING;
 
        
		MEMORY_ADDRESS_WIDTH : INTEGER := 32 -- Memory address is 32-bit wide.
  );  
            
  port    (
  	
  		clk 			: in STD_LOGIC;
  		reset			: in STD_LOGIC;
  		
  		
  		branchInstructionAddressRead : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		prediction					 : out STD_LOGIC; -- 1: TAKEN, 0: NOT TAKEN
  		
  		currentBranch					: in STD_LOGIC;
  		branchInstructionAddressWrite 	: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		writeEnable 					: in STD_LOGIC
  );
end;

architecture behave of BHT is
	
  	constant BHT_INDEXSIZE 	: INTEGER := INTEGER(CEIL(LOG2(REAL(BHT_ENTRIES))));
  	constant DATA_WIDTH 	: INTEGER := 2;
    constant ADDR_WIDTH 	: integer := BHT_INDEXSIZE;
    
    signal rd : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
    signal ra : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others=>'0');
    
    signal wd : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
    signal wa : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others=>'0');
begin
	
	bhtController : entity work.BHTController
		generic map (
			BHT_ENTRIES => BHT_ENTRIES,
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			BHT_INDEXSIZE => BHT_INDEXSIZE,
			DATA_WIDTH => DATA_WIDTH
		)
		
			port map (
				clk 			=> clk,
				ra 				=> ra,
				writeData 		=> wd,
				wa 				=> wa,
				rd 				=> rd,
				currentBranch 	=> currentBranch,
				prediction	 	=> prediction,
				branchInstructionAddressRead => branchInstructionAddressRead,
				branchInstructionAddressWrite => branchInstructionAddressWrite
				
  );
	
	regFileBHT : entity work.regFile
		generic map(
			EDGE       => EDGE,
			DATA_WIDTH => DATA_WIDTH,
			ADDR_WIDTH => ADDR_WIDTH
		)
			port map (
				clk => clk,
				ra1 => branchInstructionAddressRead,
				ra2 => (others=>'0'),
				rd1 => rd,
				wa3 => wa,
				we3 => writeEnable,
				wd3 => wd
		); 
end behave;