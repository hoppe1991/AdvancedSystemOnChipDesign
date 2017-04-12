---------------------------------------------------------------------------------
-- filename: BHTController.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 01/04/17 
---------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.log2;
use IEEE.math_real.ceil;
use work.mips_pkg.all;
use work.casts.all;
use work.bht_pkg.all;


-- -------------------------------------------------------------------------------
-- BHT controller reads the register with the given index and determines whether
-- the current instruction from MIPS should be TAKEN or NOT TAKEN.
-- BHT calculates the new state of the saturation counter, if a register should
-- be updated.
-- -------------------------------------------------------------------------------
entity bhtController is
  
	generic (	
	
  		-- Width of a memory address.
		MEMORY_ADDRESS_WIDTH 	: INTEGER := 32 ;
		
		-- 
		BHT_INDEXSIZE 			: INTEGER := 5;
		
		-- 
		DATA_WIDTH				: INTEGER := 2
  );  
            
  port    (
  		
  		-- Clock signal.
  		clk : in STD_LOGIC;
  		
  		-- Current PC given from CPU as memory address.
  		instructionPC : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- Execute stage of MIPS calculates the result of the branch condition. Therefore,
  		-- this stage knows whether the branch instruction has been taken or not.
  		branchTaken : in STD_LOGIC; -- 1: TAKEN, 0: NOT TAKEN
  		
  		-- Address (index) of register to be read.
  		ra : out STD_LOGIC_VECTOR(BHT_INDEXSIZE-1 downto 0);
  		
  		-- Data word of register to be read. Represents the state of a saturation counter.
  		rd : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
  		
  		-- Address (index) of register to be written.
  		wa : out STD_LOGIC_VECTOR(BHT_INDEXSIZE-1 downto 0);
  		
  		-- Data word to be written into register. Represents the state of a saturation counter.
  		wd : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
  		
  		-- Prediction of the current instruction.
  		-- Returns 1 if predicts TAKEN, otherwise 0 (NOT TAKEN).
  		prediction : out STD_LOGIC
  );
end;

-- -------------------------------------------------------------------------------
-- BHT controller reads the register with the given index and determines whether
-- the current instruction from MIPS should be TAKEN or NOT TAKEN.
-- BHT calculates the new state of the saturation counter, if a register should
-- be updated.
-- -------------------------------------------------------------------------------
architecture behave of bhtController is
	
	signal previousState  : STATE_SATURATION_COUNTER 							:= WEAKLY_TAKEN;
	signal nextState 	  : STATE_SATURATION_COUNTER 							:= WEAKLY_TAKEN;
	signal rdState 		  : STATE_SATURATION_COUNTER 							:= WEAKLY_TAKEN;
	signal nextAddress    : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) 	:=  (others=>'0');
     
begin

	-- Determine the address of register to be read.
	ra   <= instructionPC(BHT_INDEXSIZE+1 downto 2);
	
	-- Determine the address of register to be written.
	wa   <= nextAddress(BHT_INDEXSIZE+1 downto 2);
	
	-- Determine the prediction.
	rdState <= TO_STATEBHT(rd);
	prediction <= '1' when rdState=STRONGLY_TAKEN or rdState=WEAKLY_TAKEN else
				  '0';
	
	-- Save the previous state.
	nextAddress    <= instructionPC when rising_edge(clk);
	previousState <= rdState when rising_edge(clk);		  
	
	-- Determine the next state to be written into register.	  
	nextState 	   <= 	STRONGLY_TAKEN when branchTaken='1' and (previousState=STRONGLY_TAKEN or previousState=WEAKLY_TAKEN) else
				   		WEAKLY_TAKEN when branchTaken='1' and (previousState=WEAKLY_NOT_TAKEN) else
				   		WEAKLY_TAKEN when branchTaken='0' and (previousState=STRONGLY_TAKEN) else
				   		WEAKLY_NOT_TAKEN when branchTaken='1' and (previousState=STRONGLY_NOT_TAKEN) else
				   		WEAKLY_NOT_TAKEN when branchTaken='0' and (previousState=WEAKLY_TAKEN) else
				   		STRONGLY_NOT_TAKEN;
	
	-- Determine new data word to be written into register.			   			   		
	wd 				<= TO_STD_LOGIC_VECTOR_STATE(nextState);
	
end behave;