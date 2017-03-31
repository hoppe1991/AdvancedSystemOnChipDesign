library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.log2;
use IEEE.math_real.ceil;
use work.mips_pkg.all;
use work.casts.all;
use work.bht_pkg.all;

entity BHTController is
  generic (
  	
  		BHT_ENTRIES 			: INTEGER := 32;
		MEMORY_ADDRESS_WIDTH 	: INTEGER := 32 ;-- Memory address is 32-bit wide.
		BHT_INDEXSIZE 			: INTEGER := 5;
		DATA_WIDTH				: INTEGER := 2
  );  
            
  port    (
  		
  		-- Clock signal.
  		clk 			: in STD_LOGIC;
  		
  		-- Signals regarding CPU.
  		branchInstructionAddressRead : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		ra 		: out STD_LOGIC_VECTOR(BHT_INDEXSIZE-1 downto 0);
  		
  		prediction 					 : out STD_LOGIC;
  		
  		branchTaken 					: in STD_LOGIC; -- 1: TAKEN, 0: NOT TAKEN
  		branchInstructionAddressWrite 	: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		wa 				: out STD_LOGIC_VECTOR(BHT_INDEXSIZE-1 downto 0);
  		wd 				: out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
  		rd 				: in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
  );
end;

architecture behave of BHTController is
	
	signal previousState1 : stateBHT := WEAKLY_TAKEN;
	signal nextState : stateBHT 	 := WEAKLY_TAKEN;
    
begin

	-- Determine the address of register to be read.
	ra <= branchInstructionAddressRead(BHT_INDEXSIZE+1 downto 2);
	
	-- Determine the address of register to be written.
	wa <= branchInstructionAddressWrite(BHT_INDEXSIZE+1 downto 2);
	
	-- Determine the prediction.
	prediction <= '1' when rd="11" or rd="10" else
				  '0';
	
	--
	previousState1 <= TO_STATEBHT(rd) when rising_edge(clk);		  
				  
	nextState 	   <= 	STRONGLY_TAKEN when branchTaken='1' and (previousState1=STRONGLY_TAKEN or previousState1=WEAKLY_TAKEN) else
				   		WEAKLY_TAKEN when branchTaken='1' and (previousState1=WEAKLY_NOT_TAKEN) else
				   		WEAKLY_TAKEN when branchTaken='0' and (previousState1=STRONGLY_TAKEN) else
				   		WEAKLY_NOT_TAKEN when branchTaken='1' and (previousState1=STRONGLY_NOT_TAKEN) else
				   		WEAKLY_NOT_TAKEN when branchTaken='0' and (previousState1=WEAKLY_TAKEN) else
				   		STRONGLY_NOT_TAKEN;
				   			   		
	wd 				<= TO_STD_LOGIC_VECTOR(nextState);
				   		
		 
	

end behave;