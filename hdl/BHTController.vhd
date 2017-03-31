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
  		
  		wa 				: out STD_LOGIC_VECTOR(BHT_INDEXSIZE-1 downto 0);
  		wd 				: out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
  		rd 				: in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
  );
end;

architecture behave of BHTController is
	
	signal previousState1 : stateBHT := WEAKLY_TAKEN;
	signal nextState : stateBHT 	 := WEAKLY_TAKEN;
	signal rdState : stateBHT := WEAKLY_TAKEN;
	
	signal nextAddress : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) :=  (others=>'0');
    
begin

	-- Determine the address of register to be read.
	ra <= branchInstructionAddressRead(BHT_INDEXSIZE+1 downto 2);
	
	-- Determine the address of register to be written.
	wa <= nextAddress(BHT_INDEXSIZE+1 downto 2);
	
	-- Determine the prediction.
	rdState <= TO_STATEBHT(rd);
	prediction <= '1' when rdState=STRONGLY_TAKEN or rdState=WEAKLY_TAKEN else
				  '0';
	
	-- Save the previous state.
	nextAddress    <= branchInstructionAddressRead when rising_edge(clk);
	previousState1 <= rdState when rising_edge(clk);		  
	
	-- Determine the next state to be written into register.	  
	nextState 	   <= 	STRONGLY_TAKEN when branchTaken='1' and (previousState1=STRONGLY_TAKEN or previousState1=WEAKLY_TAKEN) else
				   		WEAKLY_TAKEN when branchTaken='1' and (previousState1=WEAKLY_NOT_TAKEN) else
				   		WEAKLY_TAKEN when branchTaken='0' and (previousState1=STRONGLY_TAKEN) else
				   		WEAKLY_NOT_TAKEN when branchTaken='1' and (previousState1=STRONGLY_NOT_TAKEN) else
				   		WEAKLY_NOT_TAKEN when branchTaken='0' and (previousState1=WEAKLY_TAKEN) else
				   		STRONGLY_NOT_TAKEN;
	
	-- Determine new data word to be written into register.			   			   		
	wd 				<= TO_STD_LOGIC_VECTOR(nextState);
				   		
		 
	

end behave;