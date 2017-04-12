---------------------------------------------------------------------------------
-- filename: btbController.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 03/04/17 
---------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.log2;
use IEEE.math_real.ceil;
use work.mips_pkg.all;
use work.casts.all;

-- -------------------------------------------------------------------------------------
-- The BTB is supposed to be implemented as register files.
-- -------------------------------------------------------------------------------------
entity btbController is
	
  generic (
  	
  		-- The BTB is supposed to be a 2-way associative cache with 16 cache lines.
  		BTB_ENRTIES 	: INTEGER := 16;
  		
  		-- 
  		DATA_WIDTH       : INTEGER := 65;
 
 		-- Width of a memory address.       
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;
		
		-- 
		ADDR_WIDTH		: INTEGER := 5
		
  );  
            
  port    (
  	
  		-- Clock signal.
  		clk 			: in STD_LOGIC;
  		
  		-- Signal to reset the BHT register file.
  		reset			: in STD_LOGIC;
  		
  		-- Current program counter given by CPU.
  		pc				: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		--
  		addressWriteID	: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- 
  		writeEnableID	: in STD_LOGIC;
  		
  		-- 
  		dataWriteID		: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		
  		addressWriteEX	: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		writeEnableEX	: in STD_LOGIC;
  		
  		dataWriteEX		: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		
  		-- Predicted program counter.
  		predictedPC		: out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- Signal indicates whether the predicted program counter is valid ('1') or not ('0').
  		predictedPCIsValid : out STD_LOGIC;
  		
  		-- Ports regarding first register file.
    	ra1 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	rd1 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wa1 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	wd1 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	we1 : out STD_LOGIC;
    
    	-- Ports regarding second register file.
    	ra2 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	rd2 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wa2 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	wd2 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	we2 : out STD_LOGIC 		
  );
end;

-- -------------------------------------------------------------------------------------
-- The BTB is supposed to be implemented as register files.
-- -------------------------------------------------------------------------------------
architecture behave of btbController is
	
	-- A memory address contains a tag vector, target pc and a valid bit.
	type BTB_LINE is record
	
		-- |     |   INDEX	 |	TAG																	   |
		-- | 0 1 | 2 3 4 5 6 | 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 |
		-- Address width minus five bit index of BTB two bit skipped.
		tag    		: STD_LOGIC_VECTOR(25-1 downto 0);
		targetPC	: STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		validBit	: STD_LOGIC;
	end record;
	
	signal rd1_btbLine 		: BTB_LINE;
	signal rd2_btbLine 		: BTB_LINE;	
	
	function STD_LOGIC_VECTOR_TO_BTB_LINE( vector : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)) return BTB_LINE is
		variable b : BTB_LINE;
		
	begin
	
		b.tag 		:= vector( DATA_WIDTH-1 downto 33);
		b.targetPC 	:= vector( 32 downto 1);
		b.validBit 	:= vector( 0 );
			
		return b;
		
	end;
	   
begin
	
	rd1_btbLine	<= STD_LOGIC_VECTOR_TO_BTB_LINE( rd1 );
	rd2_btbLine	<= STD_LOGIC_VECTOR_TO_BTB_LINE( rd2 ); 
	
	
	-- TODO Add logic of the BTB controller here.
	
	
	-- Determine whether the predicted program counter is valid ('1') or not ('0').
	predictedPCIsValid <= '1' when (rd1_btbLine.validBit='1' and rd1_btbLine.targetPC=pc(31 downto 7)) else
						  '1' when (rd2_btbLine.validBit='1' and rd2_btbLine.targetPC=pc(31 downto 7)) else
						  '0';
						  
	-- Predict the next program counter.
	predictedPC		   <= rd1_btbLine.targetPC when rd1_btbLine.validBit='1' else
						  rd2_btbLine.targetPC when rd2_btbLine.validBit='1' else
						  (others=>'0');
						  
	-- Determine the addresses of registers to be read.
	ra1 				<= pc(ADDR_WIDTH+1 downto 2);
	ra2					<= pc(ADDR_WIDTH+1 downto 2);
	
	
	-- If both the EX and ID stage are trying to write the table simultaneously, priority is given to the EX stage,
	-- since the branch instruction is ahead in the pipeline. Here, the writing of the BTB for the jump instruction
	-- is ignored which may result in minor performance degradation.
	wa1		  			<= addressWriteEX(ADDR_WIDTH+1 downto 2) when (writeEnableEX='1') else
						   addressWriteID(ADDR_WIDTH+1 downto 2) when (writeEnableID='1') else
						   (others=>'0');
    --wd1 <= 
	--we1 <= 
    
    --wa2	<= 
    --wd2 <= 
	--we2 <= 
	
end behave;